import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';

import 'constant.dart';
import 'path.dart';

const logsDirectoryName = 'logs';

typedef ArchiveRequest = ({String archivePath, List<String> files});

/// Appends every log line to `logs/FlClashX_<day>.log` under the app home,
/// starts `_<n>` files past [maxFileBytes] and drops days older than [keepDays].
class FileLogger {
  FileLogger({
    Future<String> Function()? directory,
    DateTime Function()? now,
    this.maxFileBytes = 10 * 1024 * 1024,
    this.keepDays = 10,
    this.prefix = appName,
    @visibleForTesting Future<void> Function(ArchiveRequest)? writeArchive,
  }) : _directory = directory ?? _defaultDirectory,
       _now = now ?? DateTime.now,
       _writeArchiveWith =
           writeArchive ?? ((request) => compute(_writeArchive, request));

  final Future<String> Function() _directory;
  final DateTime Function() _now;
  final Future<void> Function(ArchiveRequest) _writeArchiveWith;
  final int maxFileBytes;
  final int keepDays;
  final String prefix;

  static const _pendingLimit = 2000;

  final _pending = <String>[];
  Future<void> _drain = Future.value();
  Future<void> _archiving = Future.value();
  bool _enabled = false;
  bool _scheduled = false;
  String? _day;
  File? _file;
  int _size = 0;

  late final _dayPattern = RegExp(
    (prefix == appName ? r'^FlClash[ZX]' : '^${RegExp.escape(prefix)}') +
    r'_(\d{4}-\d{2}-\d{2})(?:_\d+)?\.log$',
  );

  static Future<String> _defaultDirectory() async =>
      join(await appPath.homeDirPath, logsDirectoryName);

  Future<String> get directoryPath async {
    final path = await _directory();
    await Directory(path).create(recursive: true);
    return path;
  }

  /// Lines queue until the app paths can be resolved, then land in order.
  void enable() {
    _enabled = true;
    _schedule();
  }

  void write(Log log) {
    _pending.add(
      '[${log.dateTime}] [${log.logLevel.name.toUpperCase()}] ${log.payload}',
    );
    if (_pending.length > _pendingLimit) {
      _pending.removeRange(0, _pending.length - _pendingLimit);
    }
    _schedule();
  }

  void _schedule() {
    if (!_enabled || _scheduled || _pending.isEmpty) return;
    _scheduled = true;
    _drain = Future<void>.microtask(() async {
      try {
        // One writer owns the bounded queue; bursts do not create a future
        // per log line. Entries arriving during an append form the next batch.
        while (_pending.isNotEmpty) {
          await _flush();
        }
      } catch (_) {
        // Retain the pending batch and retry on the next explicit flush/write.
      } finally {
        _scheduled = false;
      }
    });
  }

  Future<void> flush() {
    if (_pending.isNotEmpty) _schedule();
    return _drain;
  }

  /// How long [archiveToday] keeps an archive for the app still reading it.
  static const shareRetention = Duration(days: 1);

  /// Zips today's files, written lines included, into [directory]; null when
  /// today has none.
  Future<String?> archiveToday(String directory) {
    final archived = _archiving.then((_) => _archiveToday(directory));
    _archiving = archived.then<void>((_) {}, onError: (_) {});
    return archived;
  }

  Future<String?> _archiveToday(String directory) async {
    await flush();
    final now = _now();
    await _pruneArchives(directory, now);
    final today = _dayOf(now);
    final files = <String>[];
    await for (final entity in Directory(
      await directoryPath,
    ).list(followLinks: false)) {
      final match = _dayPattern.firstMatch(basename(entity.path));
      if (entity is File && match?.group(1) == today) {
        files.add(entity.path);
      }
    }
    if (files.isEmpty) {
      return null;
    }
    final archivePath = await _freshArchivePath(directory, now);
    await _writeArchiveWith((archivePath: archivePath, files: files..sort()));
    return archivePath;
  }

  String get _archivePrefix => '${prefix}_logs_';

  Future<String> _freshArchivePath(String directory, DateTime now) async {
    final time = [
      now.hour,
      now.minute,
      now.second,
    ].map((part) => part.toString().padLeft(2, '0')).join('-');
    final stem = join(directory, '$_archivePrefix${_dayOf(now)}_$time');
    var path = '$stem.zip';
    for (var copy = 2; await File(path).exists(); copy++) {
      path = '${stem}_$copy.zip';
    }
    return path;
  }

  Future<void> _pruneArchives(String directory, DateTime now) async {
    final folder = Directory(directory);
    if (!await folder.exists()) {
      return;
    }
    await for (final entity in folder.list(followLinks: false)) {
      final name = basename(entity.path);
      if (entity is! File ||
          !name.startsWith(_archivePrefix) ||
          extension(name) != '.zip') {
        continue;
      }
      try {
        if (now.difference(await entity.lastModified()) > shareRetention) {
          await entity.delete();
        }
      } on FileSystemException {
        // Gone already or still held; the next share tries again.
      }
    }
  }

  Future<void> dispose() async {
    await flush();
    _file = null;
    _day = null;
  }

  Future<void> _flush() async {
    if (_pending.isEmpty) {
      return;
    }
    final batch = List<String>.of(_pending);
    _pending.clear();
    final bytes = utf8.encode('${batch.join('\n')}\n');
    try {
      final file = await _target(bytes.length);
      await file.writeAsBytes(bytes, mode: FileMode.append, flush: true);
      _size += bytes.length;
    } catch (_) {
      // Retry on the next write/flush, with a bounded queue. An interrupted
      // OS append can leave a partial line; never truncate existing history.
      _file = null;
      _pending.insertAll(0, batch);
      if (_pending.length > _pendingLimit) {
        _pending.removeRange(0, _pending.length - _pendingLimit);
      }
      rethrow;
    }
  }

  Future<File> _target(int incoming) async {
    final day = _dayOf(_now());
    final current = _file;
    if (current != null && _day == day && _size + incoming <= maxFileBytes) {
      return current;
    }
    final directory = await directoryPath;
    if (_day != day) {
      await _prune(directory, day);
    }
    _day = day;
    for (var index = 0; ; index++) {
      final name = index == 0
          ? '${prefix}_$day.log'
          : '${prefix}_${day}_$index.log';
      final file = File(join(directory, name));
      final size = await file.exists() ? await file.length() : 0;
      if (size + incoming <= maxFileBytes || size == 0) {
        _file = file;
        _size = size;
        return file;
      }
    }
  }

  Future<void> _prune(String directory, String today) async {
    final oldest = _parseDay(today).subtract(Duration(days: keepDays - 1));
    await for (final entity in Directory(directory).list(followLinks: false)) {
      final match = _dayPattern.firstMatch(basename(entity.path));
      if (entity is! File || match == null) {
        continue;
      }
      if (_parseDay(match.group(1)!).isBefore(oldest)) {
        try {
          await entity.delete();
        } on FileSystemException {
          // Another process may hold it; the next day's write tries again.
        }
      }
    }
  }

  static String _dayOf(DateTime time) =>
      '${time.year.toString().padLeft(4, '0')}-'
      '${time.month.toString().padLeft(2, '0')}-'
      '${time.day.toString().padLeft(2, '0')}';

  static DateTime _parseDay(String day) => DateTime.parse(day);
}

Future<void> _writeArchive(ArchiveRequest request) async {
  final encoder = ZipFileEncoder()..create(request.archivePath);
  try {
    for (final path in request.files) {
      await encoder.addFile(File(path));
    }
  } finally {
    await encoder.close();
  }
}

final fileLogger = FileLogger();

final zapretFileLogger = FileLogger(
  prefix: 'Zapret',
  directory: () async => join(await appPath.homeDirPath, logsDirectoryName, 'zapret'),
);
final crashFileLogger = FileLogger(
  prefix: 'Crashes',
  directory: () async => join(await appPath.homeDirPath, logsDirectoryName, 'crashes'),
);

final appFileLogger = FileLogger(
  prefix: 'Application',
  directory: () async => join(await appPath.homeDirPath, logsDirectoryName, 'application'),
);

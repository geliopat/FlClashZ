import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/file_logger.dart';
import 'package:fl_clash/common/path.dart';
import 'package:fl_clash/models/models.dart';
import 'package:path/path.dart' as p;

enum RecoveryOutcome { started, succeeded, failed, interrupted, skipped }

enum RecoveryComponentFilter { all, mihomo, helper, zapret }

List<RecoveryEvent> filterRecoveryEvents(
  Iterable<RecoveryEvent> events, RecoveryComponentFilter filter,
) => [
  for (final event in events)
    if (filter == RecoveryComponentFilter.all ||
        event.component.toLowerCase() == filter.name)
      event,
];

class RecoveryEvent {
  const RecoveryEvent({
    required this.id,
    required this.time,
    required this.component,
    required this.action,
    required this.outcome,
  });

  final String id;
  final DateTime time;
  final String component;
  final String action;
  final RecoveryOutcome outcome;

  Map<String, Object?> toJson() => {
    'id': id,
    'time': time.toUtc().toIso8601String(),
    'component': component,
    'action': action,
    'outcome': outcome.name,
  };

  factory RecoveryEvent.fromJson(Map<String, dynamic> json) => RecoveryEvent(
    id: json['id'] as String,
    time: DateTime.parse(json['time'] as String),
    component: json['component'] as String,
    action: json['action'] as String,
    outcome: RecoveryOutcome.values.byName(json['outcome'] as String),
  );
}

class RecoveryJournal {
  RecoveryJournal({FileLogger? logger}) : _logger = logger ?? FileLogger(
    prefix: 'Recovery',
    directory: () async => p.join(await appPath.homeDirPath, logsDirectoryName, 'recovery'),
  );

  final FileLogger _logger;
  int _sequence = 0;
  static const _marker = ' RECOVERY_V1 ';
  static const maxEntries = 500;

  String begin(String component, String action) {
    final id = '${DateTime.now().microsecondsSinceEpoch}-${_sequence++}';
    record(id, component, action, RecoveryOutcome.started);
    return id;
  }

  void record(String id, String component, String action, RecoveryOutcome outcome) {
    // Only controlled identifiers are persisted, never exception text, URLs,
    // strategy arguments, credentials or subscription content.
    final event = RecoveryEvent(id: id, time: DateTime.now(), component: component,
      action: action, outcome: outcome);
    _logger.enable();
    _logger.write(Log.app('$_marker${jsonEncode(event.toJson())}'));
  }

  static RecoveryEvent? parseLine(String line) {
    final index = line.indexOf(_marker);
    if (index < 0) return null;
    try {
      return RecoveryEvent.fromJson(
        jsonDecode(line.substring(index + _marker.length)) as Map<String, dynamic>,
      );
    } catch (_) {
      return null;
    }
  }

  /// Decode new structured Helper events only; old free-text messages are
  /// still available in the separate legacy journal.
  static List<RecoveryEvent> parseNativeArchive(String archive) {
    final tail = Queue<RecoveryEvent>();
    for (final line in const LineSplitter().convert(archive)) {
      try {
        final json = jsonDecode(line) as Map<String, dynamic>;
        final recovery = json['recovery'] as Map<String, dynamic>;
        final event = RecoveryEvent(
          id: recovery['id'] as String,
          time: DateTime.fromMillisecondsSinceEpoch(json['timestampMs'] as int, isUtc: true),
          component: json['component'] as String,
          action: recovery['action'] as String,
          outcome: RecoveryOutcome.values.byName(recovery['outcome'] as String),
        );
        tail.addLast(event);
        if (tail.length > maxEntries) tail.removeFirst();
      } catch (_) {
        // Legacy records and torn lines are not structured recovery events.
      }
    }
    return tail.toList(growable: false);
  }

  Future<void> flush() => _logger.flush();

  Future<({List<File> files, int pending})> retainedFiles() => _logger.retainedFiles();

  Future<String> get directoryPath => _logger.directoryPath;

  Future<List<RecoveryEvent>> readRecent() async {
    await _logger.flush();
    final files = await Directory(await directoryPath).list(followLinks: false)
      .where((entry) => entry is File &&
        RegExp(r'^Recovery_\d{4}-\d{2}-\d{2}(?:_\d+)?\.log$').hasMatch(p.basename(entry.path)))
      .cast<File>().toList();
    // File rotation names are not lexicographic after nine segments.
    final dated = await Future.wait(files.map((file) async => (file: file, modified: await file.lastModified())));
    dated.sort((a, b) => b.modified.compareTo(a.modified));
    final result = <RecoveryEvent>[];
    for (final entry in dated) {
      final tail = Queue<RecoveryEvent>();
      await for (final line in entry.file.openRead().transform(const Utf8Decoder(allowMalformed: true)).transform(const LineSplitter())) {
        final event = parseLine(line);
        if (event == null) continue;
        tail.addLast(event);
        if (tail.length > maxEntries) tail.removeFirst();
      }
      result.addAll(tail.toList().reversed);
      if (result.length >= maxEntries) break;
    }
    result.sort((a, b) => b.time.compareTo(a.time));
    return result.take(maxEntries).toList(growable: false);
  }
}

final recoveryJournal = RecoveryJournal();

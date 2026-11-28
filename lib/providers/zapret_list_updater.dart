import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:fl_clash/core/desktop/helper_client.dart';
import 'package:fl_clash/l10n/l10n.dart';

const zapretListUpdateInterval = Duration(hours: 12);
const zapretListRetryInterval = Duration(minutes: 5);

bool zapretListsDue(DateTime now, DateTime? lastSuccess, DateTime? retryAfter) {
  if (retryAfter != null && now.isBefore(retryAfter) &&
      retryAfter.difference(now) <= zapretListRetryInterval) {
    return false;
  }
  return lastSuccess == null || now.isBefore(lastSuccess) ||
      !now.isBefore(lastSuccess.add(zapretListUpdateInterval));
}

// Helper stores LF, including when it receives CRLF.
String normalizeZapretList(String content) =>
    content.replaceAll('\r\n', '\n').replaceAll('\r', '\n');

bool sameZapretList(String a, String b) =>
    normalizeZapretList(a) == normalizeZapretList(b);

String zapretListEntryKey(String line) => line.trim().toLowerCase();

class ZapretListUpdateResult {
  const ZapretListUpdateResult({this.error, this.notice});
  final String? error;
  final String? notice;
  bool get succeeded => error == null;
}

/// Shared by the background scheduler and the settings editor. All list
/// mutations made by the application pass through this one coordinator.
class ZapretListUpdater {
  ZapretListUpdater({HelperClient? client, DateTime Function()? now})
      : _client = client ?? helperClient, _now = now ?? DateTime.now;

  final HelperClient _client;
  final DateTime Function() _now;
  Future<ZapretListUpdateResult>? _update;
  bool _editing = false;
  DateTime? _lastSuccess;
  DateTime? _retryAfter;
  bool get busy => _editing || _update != null;
  bool get isDue => !busy && zapretListsDue(_now(), _lastSuccess, _retryAfter);

  static const _sources = <String, String>{
    'list-general.txt': 'https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/main/lists/list-general.txt',
    'list-google.txt': 'https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/main/lists/list-google.txt',
    'list-exclude.txt': 'https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/main/lists/list-exclude.txt',
    'ipset-all.txt': 'https://raw.githubusercontent.com/Flowseal/zapret-discord-youtube/main/lists/ipset-all.txt',
  };

  static const _gifDomains = <String>[
    'tenor.com', 'media.tenor.com', 'c.tenor.com', 't.tenor.com',
    'api.tenor.com', 'tenor.co', 'gifdeliverynetwork.com', 'giphy.com',
    'media.giphy.com', 'api.giphy.com', 'i.giphy.com',
  ];

  final _http = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 8),
    receiveTimeout: const Duration(seconds: 20),
    responseType: ResponseType.plain,
  ));

  Future<T> edit<T>(Future<T> Function() operation) async {
    // Do not overlap edits/restores with an update, including rollback.
    final update = _update;
    if (update != null) await update;
    if (busy) throw StateError('Another Zapret list operation is running');
    _editing = true;
    try {
      return await operation();
    } finally {
      _editing = false;
    }
  }

  Future<ZapretListUpdateResult> update(AppLocalizations l, {bool Function()? canCommit}) {
    if (_update case final active?) return active;
    if (_editing) {
      return Future.value(ZapretListUpdateResult(error: l.forkConcurrentEdit));
    }
    return _update = _run(l, canCommit).then((result) {
      final now = _now();
      if (result.succeeded) {
        _lastSuccess = now;
        _retryAfter = null;
      } else {
        _retryAfter = now.add(zapretListRetryInterval);
      }
      return result;
    }).whenComplete(() => _update = null);
  }

  Future<ZapretListUpdateResult?> updateIfDue(AppLocalizations l, {bool Function()? canCommit}) async {
    if (busy || !zapretListsDue(_now(), _lastSuccess, _retryAfter)) return null;
    return update(l, canCommit: canCommit);
  }

  String _mergeList(String upstream, String existing, String filename) {
    final seen = <String>{};
    final lines = <String>[];

    void addLine(String raw) {
      final line = raw.trim();
      if (line.isEmpty) return;
      if (line.startsWith('#')) {
        if (!lines.contains(line)) lines.add(line);
        return;
      }
      final key = zapretListEntryKey(line);
      if (seen.add(key)) lines.add(line);
    }

    for (final line in upstream.split(RegExp(r'\r?\n'))) {
      addLine(line);
    }
    // Match zapret2-gui: keep local additions when upstream removes an entry.
    for (final line in existing.split(RegExp(r'\r?\n'))) {
      addLine(line);
    }
    if (filename == 'list-google.txt') addLine('dl.google.com');
    if (filename == 'list-general.txt') {
      for (final domain in _gifDomains) {
        addLine(domain);
      }
    }
    return '${lines.join('\n')}\n';
  }

  Future<ZapretListUpdateResult> _run(AppLocalizations l, bool Function()? canCommit) async {
    final staged = <String, String>{};
    final originals = <String, String>{};
    final applied = <String>[];
    final attempted = <String>{};
    final details = <String>[];
    final rollbackFailures = <String>[];

    try {
      // Download and validate every upstream file before touching the disk.
      for (final entry in _sources.entries) {
        final current = await _client.readZapretList(entry.key);
        final response = await _http.get<String>(entry.value);
        final upstream = response.data;
        if (upstream == null || (entry.key != 'ipset-all.txt' && upstream.trim().length < 20)) {
          throw StateError('${entry.key}: ${l.forkEmptySourceFile}');
        }

        final upstreamCount = upstream
            .split(RegExp(r'\r?\n'))
            .where((line) => line.trim().isNotEmpty && !line.trim().startsWith('#'))
            .length;
        if (upstreamCount == 0 && entry.key != 'ipset-all.txt') {
          throw StateError(
            '${entry.key}: ${l.forkSourceNoEntries}',
          );
        }

        if (entry.key == 'ipset-all.txt' && upstreamCount == 0) {
          details.add('ipset-all.txt: ${l.forkKeepEmptyTemplate}');
          continue;
        }

        // The upstream GUI merges local rows after downloading. Do not compare
        // the upstream count with the installed file: that file may contain
        // many valid local additions which are intentionally retained.
        final merged = _mergeList(upstream, current.content, entry.key);
        if (utf8.encode(merged).length > 2 * 1024 * 1024) {
          throw StateError('${entry.key}: ${l.forkListSizeLimit}');
        }
        originals[entry.key] = current.content;
        staged[entry.key] = merged;
      }

      // Apply staged files. Re-read before each write so an edit made in
      // another editor during download is not silently overwritten.
      for (final entry in staged.entries) {
        if (canCommit?.call() == false) throw StateError(l.forkCoreBusy);
        final current = await _client.readZapretList(entry.key);
        if (canCommit?.call() == false) throw StateError(l.forkCoreBusy);
        if (!sameZapretList(current.content, originals[entry.key]!)) {
          throw StateError(
            '${entry.key}: ${l.forkConcurrentEdit}',
          );
        }
        if (sameZapretList(current.content, entry.value)) continue;
        attempted.add(entry.key);
        final saved = await _client.writeZapretList(entry.key, entry.value);
        applied.add(entry.key);
        details.add('${saved.filename}: ${saved.entries}');
      }

      return ZapretListUpdateResult(
        notice: '${l.forkFilesUpdated}: ${applied.length}. ${details.join(' · ')}. ${l.forkUserFilesKept}',
      );
    } catch (error) {
      // A request can fail after Helper has already replaced the file but
      // before the response reaches the client. Detect that ambiguous case.
      for (final entry in staged.entries) {
        if (!attempted.contains(entry.key) || applied.contains(entry.key)) continue;
        try {
          final current = await _client.readZapretList(entry.key);
          if (sameZapretList(current.content, entry.value) &&
              !sameZapretList(current.content, originals[entry.key]!)) {
            applied.add(entry.key);
          } else if (!sameZapretList(current.content, originals[entry.key]!)) {
            rollbackFailures.add(
              '${entry.key}: ${l.forkRollbackConcurrent}',
            );
          }
        } catch (verificationError) {
          rollbackFailures.add(
            '${entry.key}: ${l.forkWriteVerificationFailed}: $verificationError',
          );
        }
      }

      // Roll back already-applied files in reverse order. Before restoring,
      // verify that nobody has changed the file since this updater wrote it.
      for (final filename in applied.reversed) {
        try {
          final current = await _client.readZapretList(filename);
          if (!sameZapretList(current.content, staged[filename]!)) {
            rollbackFailures.add(
              '$filename: ${l.forkRollbackConcurrent}',
            );
            continue;
          }
          await _client.writeZapretList(filename, originals[filename]!);
          final restored = await _client.readZapretList(filename);
          if (!sameZapretList(restored.content, originals[filename]!)) {
            throw StateError(l.forkWriteVerificationFailed);
          }
        } catch (rollbackError) {
          rollbackFailures.add('$filename: $rollbackError');
        }
      }
      return ZapretListUpdateResult(
        error: error is HelperException ? error.message : error.toString(),
        notice: rollbackFailures.isNotEmpty
            ? '${l.forkRollbackUnconfirmed}: ${rollbackFailures.join('; ')}'
            : applied.isNotEmpty
                ? l.forkRollbackRestored
                : null,
      );
    }
  }

}

final zapretListUpdater = ZapretListUpdater();

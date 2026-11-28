import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

/// Rolling, UTC minute buckets. Keep independent counters for all traffic and
/// proxied traffic so changing the statistics preference cannot double-count.
class RollingTrafficWindow {
  static const minutes = 24 * 60;
  final _buckets = <int, List<int>>{};
  final _previous = List<int?>.filled(4, null);

  static int minute(DateTime at) => at.millisecondsSinceEpoch ~/ 60000;

  void resetBaseline({bool confirmed = true}) {
    for (var i = 0; i < _previous.length; i++) {
      _previous[i] = confirmed ? 0 : null;
    }
  }

  void prune(DateTime at) {
    final now = minute(at);
    _buckets.removeWhere((key, _) => key <= now - minutes || key > now);
  }

  void record(DateTime at, {Traffic? all, Traffic? proxy}) {
    prune(at);
    final samples = [all?.up, all?.down, proxy?.up, proxy?.down];
    for (var i = 0; i < samples.length; i++) {
      final value = samples[i];
      if (value == null || !value.isFinite || value < 0) continue;
      final current = value.toInt();
      final previous = _previous[i];
      _previous[i] = current;
      if (previous == null) continue;
      final delta = current >= previous ? current - previous : current;
      if (delta == 0) continue;
      final bucket = _buckets.putIfAbsent(minute(at), () => List.filled(4, 0));
      bucket[i] += delta;
    }
  }

  Traffic total(DateTime at, {required bool onlyProxy}) {
    prune(at);
    final offset = onlyProxy ? 2 : 0;
    var up = 0;
    var down = 0;
    for (final bucket in _buckets.values) {
      up += bucket[offset];
      down += bucket[offset + 1];
    }
    return Traffic(up: up, down: down);
  }

  Map<String, Object> toJson() => {
    for (final entry in _buckets.entries) entry.key.toString(): entry.value,
  };

  void restore(Object? json, DateTime at) {
    if (json is! Map) return;
    final now = minute(at);
    for (final entry in json.entries) {
      final key = int.tryParse(entry.key.toString());
      final value = entry.value;
      if (key == null || key <= now - minutes || key > now ||
          value is! List || value.length != 4 ||
          value.any((element) => element is! int || element < 0)) {
        continue;
      }
      _buckets[key] = List<int>.from(value);
    }
  }
}

/// The history is independent of the sidebar lifecycle. It keeps recording
/// while the Windows window is in the tray and survives normal restarts.
class TrafficHistory {
  TrafficHistory({this.persist = true});

  final bool persist;
  final window = RollingTrafficWindow();
  final revision = ValueNotifier<int>(0);
  Future<void>? _loading;
  Future<void> _writes = Future.value();
  DateTime? _lastSave;
  int generation = 0;
  bool loaded = false;
  bool resetting = false;
  bool _disposed = false;

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    generation++;
    revision.dispose();
  }

  Future<File> _file() async =>
      File(p.join(await appPath.homeDirPath, 'traffic-history-v1.json'));

  Future<void> load() => _loading ??= _load();

  Future<void> _load() async {
    try {
      if (!persist) return;
      final file = await _file();
      if (await file.exists()) {
        window.restore(jsonDecode(await file.readAsString()), DateTime.now());
      }
    } catch (error) {
      commonPrint.log('Traffic history read: ${compactError(error)}',
          logLevel: LogLevel.warning);
    } finally {
      loaded = true;
      if (!_disposed) revision.value++;
    }
  }

  Future<void> record({required int generation, Traffic? all, Traffic? proxy}) async {
    if (_disposed || resetting || generation != this.generation) return;
    await load();
    if (_disposed || resetting || generation != this.generation) return;
    final now = DateTime.now();
    window.record(now, all: all, proxy: proxy);
    revision.value++;
    final last = _lastSave;
    if (last == null || now.difference(last).abs() >= const Duration(minutes: 1)) {
      _lastSave = now;
      unawaited(flush());
    }
  }

  int beginReset() {
    resetting = true;
    return ++generation;
  }

  void finishReset(int token, {required bool confirmed}) {
    if (_disposed || token != generation) return;
    window.resetBaseline(confirmed: confirmed);
    resetting = false;
    revision.value++;
    unawaited(flush());
  }

  Future<void> flush() {
    if (!persist) return Future<void>.value();
    return _writes = _writes.then((_) async {
      try {
        await load();
        window.prune(DateTime.now());
        final file = await _file();
        await file.writeAsStringAtomically(jsonEncode(window.toJson()));
      } catch (error) {
        commonPrint.log('Traffic history save: ${compactError(error)}',
            logLevel: LogLevel.warning);
      }
    });
  }
}

final trafficHistoryProvider = Provider<TrafficHistory>((ref) {
  final history = TrafficHistory();
  ref.onDispose(history.dispose);
  return history;
});

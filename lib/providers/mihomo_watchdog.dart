import 'dart:async';

import 'package:fl_clash/common/print.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final mihomoWatchdogProvider = NotifierProvider<MihomoWatchdog, bool>(MihomoWatchdog.new);

class MihomoWatchdog extends Notifier<bool> {
  static const _key = 'mihomo.watchdog';
  int _revision = 0;
  bool? _confirmed;
  Future<void> _writes = Future.value();

  @override
  bool build() {
    final revision = _revision;
    scheduleMicrotask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (ref.mounted && revision == _revision) {
          _confirmed = prefs.getBool(_key) ?? true;
          state = _confirmed!;
        }
      } catch (_) {
        commonPrint.log('Mihomo watchdog settings unavailable', logLevel: LogLevel.warning);
      }
    });
    return true;
  }

  Future<void> setEnabled(bool value) {
    final revision = ++_revision;
    state = value;
    final operation = _writes.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        _confirmed = prefs.getBool(_key) ?? true;
        if (!await prefs.setBool(_key, value)) {
          throw StateError('Watchdog preference write rejected');
        }
        _confirmed = value;
      } catch (_) {
        // Restore only a confirmed persisted value, and never overwrite
        // a newer user intent with a late failure.
        if (ref.mounted && revision == _revision && _confirmed != null) {
          state = _confirmed!;
        }
        commonPrint.log('Mihomo watchdog settings save failed', logLevel: LogLevel.warning);
      }
    });
    _writes = operation;
    return operation;
  }
}

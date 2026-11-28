import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/file.dart';
import 'package:fl_clash/common/print.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';
import 'package:shared_preferences_platform_interface/types.dart';

const _defaultPrefix = 'flutter.';
const independentSettingsBackupName = 'settings.last-good.v1.json';

/// Stands in for the Windows and Linux stores, which truncate the file before
/// writing it (flutter/flutter#89211): same file and format, but each save
/// replaces it with a flushed sibling.
class AtomicFilePreferencesStore extends SharedPreferencesStorePlatform {
  AtomicFilePreferencesStore(this._path, {this.enableRecovery = false});

  final bool enableRecovery;

  final Future<String> _path;
  Future<Map<String, Object>>? _values;
  Future<bool> _lastWrite = Future.value(true);

  Future<Map<String, Object>> _read() {
    return _values ??= _load().catchError((Object error, StackTrace stack) {
      _values = null;
      Error.throwWithStackTrace(error, stack);
    });
  }

  Map<String, Object> _decode(String raw) {
    final data = json.decode(raw);
    if (data is! Map) throw const FormatException('Preferences map required');
    final values = Map<String, Object>.from(data);
    // SharedPreferences accepts scalar values and string lists. A syntactically
    // valid but structurally damaged primary must not displace a good backup.
    for (final entry in values.entries) {
      if (!entry.key.startsWith(_defaultPrefix)) continue;
      final value = entry.value;
      if (value is! bool && value is! num && value is! String &&
          !(value is List && value.every((item) => item is String))) {
        throw const FormatException('Invalid preferences value');
      }
    }
    return values;
  }

  Future<Map<String, Object>> _load() async {
    final file = File(await _path);
    final backup = File('${file.path}.last-good');
    // File.exists() is false for directories and dangling links. Such an
    // obstruction is not a new installation and must not trigger import or
    // writes through an unexpected symlink. Inspect both paths without following
    // links before attempting recovery.
    final primaryType = await FileSystemEntity.type(file.path, followLinks: false);
    final backupType = enableRecovery
        ? await FileSystemEntity.type(backup.path, followLinks: false)
        : FileSystemEntityType.notFound;
    if (primaryType != FileSystemEntityType.file &&
        primaryType != FileSystemEntityType.notFound) {
      throw FileSystemException('Invalid preferences path', file.path);
    }
    try {
      if (primaryType == FileSystemEntityType.notFound) {
        if (enableRecovery && backupType != FileSystemEntityType.notFound) {
          throw const FormatException('Preferences missing');
        }
        return {};
      }
      final content = await file.readAsString();
      if (content.isEmpty && !enableRecovery) return {};
      return _decode(content);
    } catch (_) {
      if (!enableRecovery || backupType != FileSystemEntityType.file) rethrow;
      final recovered = _decode(await backup.readAsString());
      if (primaryType == FileSystemEntityType.file) {
        // Preserve the exact damaged bytes, without exposing them in logs.
        final evidence = '${file.path}.corrupt-${DateTime.now().microsecondsSinceEpoch}';
        await file.copy(evidence);
      }
      await file.writeAsStringAtomically(jsonEncode(recovered));
      commonPrint.log('Recovered complete preferences store from backup',
        logLevel: LogLevel.warning);
      return recovered;
    }
  }

  Future<bool> _update(
    void Function(Map<String, Object> values) change, {
    bool clearing = false,
  }) {
    final operation = _lastWrite.catchError((_) => false).then((_) async {
      try {
        final current = await _read();
        final next = Map<String, Object>.of(current);
        change(next);
        final encoded = json.encode(next);
        final validated = _decode(encoded);
        if (!await _write(encoded, previous: json.encode(current), clearing: clearing)) {
          return false;
        }
        _values = Future.value(validated);
        return true;
      } catch (_) {
        // A failed read or invalid mutation is also a failed save. Never
        // replace unreadable existing preferences with an empty map.
        commonPrint.log('Preferences mutation rejected', logLevel: LogLevel.warning);
        return false;
      }
    });
    return _lastWrite = operation;
  }

  Future<bool> _write(
    String content, {
    required String previous,
    required bool clearing,
  }) async {
    final file = File(await _path);
    final backup = File('${file.path}.last-good');
    var resetBackupPrepared = false;
    try {
      final primaryType = await FileSystemEntity.type(file.path, followLinks: false);
      if (primaryType != FileSystemEntityType.file &&
          primaryType != FileSystemEntityType.notFound) {
        throw FileSystemException('Invalid preferences path', file.path);
      }
      if (enableRecovery) {
        final backupType = await FileSystemEntity.type(backup.path, followLinks: false);
        if (backupType != FileSystemEntityType.file &&
            backupType != FileSystemEntityType.notFound) {
          throw FileSystemException('Invalid preferences recovery path', backup.path);
        }
      }
      // A clear is destructive: never acknowledge it while an older recovery
      // copy could still resurrect the cleared keys. Prepare it before primary.
      if (enableRecovery && clearing) {
        await backup.writeAsStringAtomically(content);
        resetBackupPrepared = true;
      } else if (enableRecovery && !await backup.exists() && await file.exists()) {
        await backup.writeAsStringAtomically(previous);
      }
      await file.writeAsStringAtomically(content);
    } catch (error) {
      if (resetBackupPrepared) {
        try {
          await backup.writeAsStringAtomically(previous);
        } catch (_) {
          commonPrint.log('Unable to restore preferences backup after failed clear',
              logLevel: LogLevel.warning);
        }
      }
      commonPrint.log(
        'Save preferences failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      return false;
    }
    if (enableRecovery && !clearing) {
      try {
        await backup.writeAsStringAtomically(content);
      } catch (_) {
        // The primary commit succeeded. Keep the previous backup and report
        // the reduced recovery guarantee without rolling back the live state.
        commonPrint.log('Preferences backup write failed', logLevel: LogLevel.warning);
      }
    }
    return true;
  }

  @override
  Future<Map<String, Object>> getAll() {
    return getAllWithParameters(
      GetAllParameters(filter: PreferencesFilter(prefix: _defaultPrefix)),
    );
  }

  @override
  Future<Map<String, Object>> getAllWithParameters(
    GetAllParameters parameters,
  ) async {
    final filter = parameters.filter;
    final values = await _read();
    return {
      for (final entry in values.entries)
        if (_matches(filter, entry.key))
          entry.key: entry.value is List ? List<Object?>.of(entry.value as List) : entry.value,
    };
  }

  @override
  Future<bool> setValue(String valueType, String key, Object value) {
    // Copy mutable input before the asynchronous queue can observe a change.
    final snapshot = value is List ? List<Object?>.of(value) : value;
    return _update((values) => values[key] = snapshot);
  }

  @override
  Future<bool> remove(String key) {
    return _update((values) => values.remove(key));
  }

  @override
  Future<bool> clear() {
    return clearWithParameters(
      ClearParameters(filter: PreferencesFilter(prefix: _defaultPrefix)),
    );
  }

  @override
  Future<bool> clearWithParameters(ClearParameters parameters) {
    return _update(
      (values) =>
          values.removeWhere((key, _) => _matches(parameters.filter, key)),
      clearing: true,
    );
  }

  bool _matches(PreferencesFilter filter, String key) {
    return key.startsWith(filter.prefix) &&
        (filter.allowList?.contains(key) ?? true);
  }
}

/// Only used after explicit confirmation of an unreadable desktop store
/// reset. Validate every path first; never delete directories or links.
Future<void> clearUnreadableFilePreferences(
  File primary, {
  File? independentBackup,
}) async {
  final files = [
    if (independentBackup != null) independentBackup,
    File('${primary.path}.last-good'),
    primary,
  ];
  for (final file in files) {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type != FileSystemEntityType.file &&
        type != FileSystemEntityType.notFound) {
      throw FileSystemException('Invalid preferences recovery path', file.path);
    }
  }
  // Delete recovery sources first so the next launch cannot resurrect them.
  for (final file in files) {
    if (await file.exists()) await file.delete();
  }
}

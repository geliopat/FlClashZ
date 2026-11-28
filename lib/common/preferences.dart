import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:fl_clash/common/settings_recovery.dart';

import 'package:fl_clash/common/boot_record.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/system_dns.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Preferences {
  static Preferences? _instance;
  var _store = ResolveOnce(_open);
  static const _lastGoodConfigKey = 'config.lastGood.v1';
  Future<bool> _configWrite = Future.value(true);

  Future<bool> get isInit async => await _store.value != null;

  @visibleForTesting
  Future<File?> Function()? recoveryFileOverride;

  Future<SettingsRecovery?> _recoveryFile() async {
    final override = recoveryFileOverride;
    final file = override != null ? await override() : Platform.isWindows
        ? File(p.join(await appPath.homeDirPath, 'settings.last-good.v1.json'))
        : null;
    return file == null ? null : SettingsRecovery(file, _validateConfig);
  }

  Future<Map<String, Object?>?> _readRecoveryFile() async {
    try {
      final map = await (await _recoveryFile())?.read();
      if (map != null) commonPrint.log('Recovered settings from independent backup', logLevel: LogLevel.warning);
      return map;
    } catch (_) {
      commonPrint.log('Independent settings backup unavailable', logLevel: LogLevel.warning);
      return null;
    }
  }

  Preferences._internal();

  static Future<SharedPreferences?> _open() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  @visibleForTesting
  Future<void> rebind() async {
    await _configWrite.catchError((_) => false);
    recoveryFileOverride = () async => null;
    _store = ResolveOnce(_open);
    await _store.value;
  }

  factory Preferences() {
    _instance ??= Preferences._internal();
    return _instance!;
  }

  Future<int> getVersion() async {
    final preferences = await _store.value;
    return preferences?.getInt('version') ?? 0;
  }

  Future<void> setVersion(int version) async {
    final preferences = await _store.value;
    if (preferences == null || !await preferences.setInt('version', version)) {
      await preferences?.reload();
      throw StateError('Unable to commit data version');
    }
  }

  Future<int> getUpgradeVersion() async {
    final preferences = await _store.value;
    return preferences?.getInt('upgradeVersion') ?? 0;
  }

  Future<void> setUpgradeVersion(int version) async {
    final preferences = await _store.value;
    if (preferences == null || !await preferences.setInt('upgradeVersion', version)) {
      await preferences?.reload();
      throw StateError('Unable to commit upgrade version');
    }
  }

  Future<bool> getLegacyImported() async {
    final preferences = await _store.value;
    return preferences?.getBool('legacyImported') ?? false;
  }

  Future<void> setLegacyImported() async {
    final preferences = await _store.value;
    if (preferences == null || !await preferences.setBool('legacyImported', true)) {
      await preferences?.reload();
      throw StateError('Unable to commit legacy import marker');
    }
  }

  Future<bool> getPreChannelTipShown() async {
    final preferences = await _store.value;
    return preferences?.getBool('preChannelTipShown') ?? false;
  }

  Future<void> setPreChannelTipShown() async {
    final preferences = await _store.value;
    await preferences?.setBool('preChannelTipShown', true);
  }

  Future<void> saveShareState(SharedState shareState) async {
    final preferences = await _store.value;
    await preferences?.setString('sharedState', json.encode(shareState));
  }

  /// The md5 of the config.yaml the Core last accepted, which is also what
  /// the Android service applies when it starts without Flutter.
  Future<String?> getAppliedConfigMd5() async {
    final preferences = await _store.value;
    return preferences?.getString(appliedConfigMd5Key);
  }

  Future<void> saveAppliedConfigMd5(String? md5) async {
    final preferences = await _store.value;
    if (md5 == null) {
      await preferences?.remove(appliedConfigMd5Key);
    } else {
      await preferences?.setString(appliedConfigMd5Key, md5);
    }
  }

  Future<Map<String, Object?>?> getConfigMap() async {
    Map<String, Object?>? primary;
    try {
      final preferences = await _store.value;
      final configString = preferences?.getString(configKey);
      if (configString == null) {
        if (preferences?.containsKey(_lastGoodConfigKey) != true) return await _readRecoveryFile();
        throw const FormatException('missing primary config');
      }
      final decoded = json.decode(configString);
      if (decoded is! Map<String, Object?>) throw const FormatException('config');
      primary = decoded;
      _validateConfig(decoded);
      return decoded;
    } catch (_) {
      commonPrint.log('Invalid settings JSON; checking last known good copy', logLevel: LogLevel.warning);
      try {
        final store = await _store.value;
        final raw = store?.getString(_lastGoodConfigKey);
        if (raw == null) return await _readRecoveryFile() ?? primary;
        final map = jsonDecode(raw) as Map<String, Object?>;
        _validateConfig(map);
        commonPrint.log('Recovered last known good settings', logLevel: LogLevel.warning);
        return map;
      } catch (_) {
        // Older partially valid maps must still reach the existing salvage
        // decoder when neither a valid primary nor a backup is available.
        if (primary != null) {
          commonPrint.log('No valid settings backup; using legacy field recovery',
              logLevel: LogLevel.warning);
        }
        return await _readRecoveryFile() ?? primary;
      }
    }
  }

  Future<Map<String, Object?>?> getClashConfigMap() async {
    try {
      final preferences = await _store.value;
      final clashConfigString = preferences?.getString(clashConfigKey);
      if (clashConfigString == null) return null;
      return json.decode(clashConfigString);
    } catch (e) {
      commonPrint.log(
        'getClashConfigMap error ${e.toString()}',
        logLevel: LogLevel.warning,
      );
      return null;
    }
  }

  Future<void> clearClashConfig() async {
    try {
      final preferences = await _store.value;
      await preferences?.remove(clashConfigKey);
      return;
    } catch (e) {
      commonPrint.log(
        'clearClashConfig error ${e.toString()}',
        logLevel: LogLevel.warning,
      );
      return;
    }
  }

  static void _validateConfig(Map<String, Object?> map) {
    // Config.strictFromJson still salvages the nested app/theme settings.
    // Validate those explicitly before trusting a recovery copy.
    if (map['appSettingProps'] != null) {
      AppSettingProps.fromJson(Map<String, Object?>.from(map['appSettingProps'] as Map));
    }
    ThemeProps.fromJson(Map<String, Object?>.from(map['themeProps'] as Map));
    Config.strictFromJson(map);
  }

  Future<bool> saveConfig(Config config) {
    final operation = _configWrite.catchError((_) => false).then((_) async {
      final store = await _store.value;
      if (store == null) return false;
      var next = jsonDecode(jsonEncode(config)) as Map<String, Object?>;
      if (store.getInt('version') == 1) {
        // Use only a structurally validated snapshot of the current schema.
        // Legacy migration must not copy old ownership/credential aliases.
        final previous = await getConfigMap();
        if (previous != null && !previous.containsKey('proxiesStyle')) {
          var valid = false;
          try { _validateConfig(previous); valid = true; } catch (_) {}
          if (valid) next = preserveUnknownSettings(previous, next);
        }
      }
      _validateConfig(next);
      final encoded = jsonEncode(next);
      // Keep an independent copy of the prior valid state before touching
      // the preferences file on first migration. Never write corrupt data.
      final recovery = await _recoveryFile();
      if (recovery != null && !await recovery.file.exists()) {
        for (final previous in [store.getString(configKey), store.getString(_lastGoodConfigKey)]) {
          if (previous == null) continue;
          try { recovery.decode(previous); } catch (_) { continue; }
          await recovery.save(previous);
          break;
        }
      }
      if (!await store.setString(configKey, encoded)) {
        // SharedPreferences updates its own cache optimistically before its
        // platform backend acknowledges the write.
        await store.reload();
        return false;
      }
      try {
        if (!await store.setString(_lastGoodConfigKey, encoded)) {
          await store.reload();
          commonPrint.log('Settings backup write rejected', logLevel: LogLevel.warning);
        }
        await recovery?.save(encoded);
      } catch (_) {
        // Primary config was already committed. A backup failure must not
        // make migration retry an already successful primary write.
        commonPrint.log('Settings recovery copy write failed', logLevel: LogLevel.warning);
      }
      return true;
    });
    _configWrite = operation;
    return operation;
  }

  Future<SystemDnsRecord?> getSystemDnsRecord() async {
    try {
      final sharedPreferencesIns = await _store.value;
      final raw = sharedPreferencesIns?.getString(systemDnsRecordKey);
      if (raw == null) {
        return null;
      }
      return SystemDnsRecord.fromJson(json.decode(raw));
    } catch (e) {
      commonPrint.log(
        'getSystemDnsRecord error ${e.toString()}',
        logLevel: LogLevel.warning,
      );
      return null;
    }
  }

  Future<void> saveSystemDnsRecord(SystemDnsRecord record) async {
    final sharedPreferencesIns = await _store.value;
    await sharedPreferencesIns?.setString(
      systemDnsRecordKey,
      json.encode(record),
    );
  }

  Future<void> clearSystemDnsRecord() async {
    final sharedPreferencesIns = await _store.value;
    await sharedPreferencesIns?.remove(systemDnsRecordKey);
  }

  Future<bool> getSystemProxyApplied() async {
    final sharedPreferencesIns = await _store.value;
    return sharedPreferencesIns?.getBool(systemProxyAppliedKey) ?? false;
  }

  Future<bool> saveSystemProxyApplied(bool applied) async {
    final sharedPreferencesIns = await _store.value;
    if (sharedPreferencesIns == null) {
      return false;
    }
    return applied
        ? sharedPreferencesIns.setBool(systemProxyAppliedKey, true)
        : sharedPreferencesIns.remove(systemProxyAppliedKey);
  }

  Future<BootRecord?> getBootRecord() async {
    try {
      final sharedPreferencesIns = await _store.value;
      final raw = sharedPreferencesIns?.getString(bootRecordKey);
      if (raw == null) {
        return null;
      }
      return BootRecord.fromJson(json.decode(raw));
    } catch (e) {
      commonPrint.log(
        'getBootRecord error ${e.toString()}',
        logLevel: LogLevel.warning,
      );
      return null;
    }
  }

  Future<void> saveBootRecord(BootRecord record) async {
    final sharedPreferencesIns = await _store.value;
    await sharedPreferencesIns?.setString(bootRecordKey, json.encode(record));
  }

  Future<void> clearPreferences() async {
    final operation = _configWrite.catchError((_) => false).then((_) async {
      final store = await _store.value;
      if (store == null) return false;
      if (!await store.clear()) {
        await store.reload();
        return false;
      }
      await (await _recoveryFile())?.clear();
      return true;
    });
    _configWrite = operation;
    if (!await operation) throw StateError('Unable to clear preferences');
  }
}

final preferences = Preferences();

import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/file.dart';

/// Independent recovery copy for cases where the whole preferences store is
/// unreadable. The legacy store remains authoritative when it is valid.
class SettingsRecovery {
  SettingsRecovery(this.file, this.validate);

  final File file;
  final void Function(Map<String, Object?>) validate;

  Map<String, Object?> decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, Object?>) throw const FormatException('Settings map required');
    validate(decoded);
    return decoded;
  }

  Future<Map<String, Object?>?> read() async {
    if (!await file.exists()) return null;
    return decode(await file.readAsString());
  }

  Future<void> save(String raw) async {
    decode(raw);
    await file.writeAsStringAtomically(raw);
  }

  /// Capture and remove the independent copy before a destructive reset.
  /// A non-file obstruction is an error, not an absent backup.
  Future<String?> takeForClear() async {
    final type = await FileSystemEntity.type(file.path, followLinks: false);
    if (type == FileSystemEntityType.notFound) return null;
    if (type != FileSystemEntityType.file) {
      throw FileSystemException('Invalid settings recovery path', file.path);
    }
    final previous = await file.readAsString();
    await file.delete();
    return previous;
  }

  Future<void> restoreAfterFailedClear(String previous) =>
      file.writeAsStringAtomically(previous);

  Future<void> clear() => file.safeDelete();
}

/// Preserve fields introduced by a different compatible release. Recurse
/// only into model objects, not arbitrary user dictionaries (hosts, policy,
/// column widths, resource URLs): removed dictionary entries stay removed.
Map<String, Object?> preserveUnknownSettings(
  Map<String, Object?> previous, Map<String, Object?> next,
) {
  const objects = {
    'appSettingProps', 'themeProps', 'networkProps',
    'networkProps.authentication', 'vpnProps', 'vpnProps.accessControlProps',
    'proxiesStyleProps', 'windowGeometry', 'patchClashConfig',
    'patchClashConfig.tun', 'patchClashConfig.tun-override',
    'patchClashConfig.dns', 'patchClashConfig.dns.fallback-filter',
  };
  const retired = {
    'overrideDns', 'dav', 'davProps', 'proxiesStyle', 'networkProps.routeMode',
    'appSettingProps.checkCertificate', 'appSettingProps.restoreStrategy',
    'appSettingProps.recoveryStrategy',
  };
  Map<String, Object?> merge(Map<String, Object?> old, Map<String, Object?> fresh, String prefix) {
    final result = Map<String, Object?>.of(fresh);
    for (final entry in old.entries) {
      final path = prefix.isEmpty ? entry.key : '$prefix.${entry.key}';
      if (retired.contains(path)) continue;
      if (!fresh.containsKey(entry.key)) {
        result[entry.key] = entry.value;
      } else if (objects.contains(path) && entry.value is Map && fresh[entry.key] is Map) {
        result[entry.key] = merge(
          Map<String, Object?>.from(entry.value as Map),
          Map<String, Object?>.from(fresh[entry.key] as Map), path,
        );
      }
    }
    return result;
  }
  return merge(previous, next, '');
}

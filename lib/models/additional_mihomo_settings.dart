import 'package:fl_clash/common/yaml.dart';

enum MihomoValueKind { boolean, integer, string, strings }

/// Remaining editable fields of the released FlClashZ Core v1.19.34-z.3.
/// Engine d6f29e555e63906208d9b5cba098af802126ba24;
/// source-settings contract: host 03c93c9adf1d847be367f1ecd1f3381d6bb25183.
/// Routing definitions, credentials, internal file descriptors, unsafe
/// controller transports, OS-specific and non-public knobs are not an
/// arbitrary override surface. Existing typed editors own their fields.
const additionalMihomoKeys = <String, MihomoValueKind>{
  'inbound-tfo': MihomoValueKind.boolean,
  // Accepted by the core; actual MPTCP availability depends on the OS.
  'inbound-mptcp': MihomoValueKind.boolean,
  'lan-allowed-ips': MihomoValueKind.strings,
  'lan-disallowed-ips': MihomoValueKind.strings,
  'bind-address': MihomoValueKind.string,
  'geodata-mode': MihomoValueKind.boolean,
  'geosite-matcher': MihomoValueKind.string,
  'etag-support': MihomoValueKind.boolean,
  'profile.store-fake-ip': MihomoValueKind.boolean,
  'experimental.quic-go-disable-gso': MihomoValueKind.boolean,
  'experimental.quic-go-disable-ecn': MihomoValueKind.boolean,
  'experimental.dialer-ip4p-convert': MihomoValueKind.boolean,
  'tun.inet6-address': MihomoValueKind.strings,
  'tun.loopback-address': MihomoValueKind.strings,
  'tun.endpoint-independent-nat': MihomoValueKind.boolean,
  'tun.icmp-timeout': MihomoValueKind.integer,
  'tun.inet4-route-address': MihomoValueKind.strings,
  'tun.inet6-route-address': MihomoValueKind.strings,
  'tun.inet4-route-exclude-address': MihomoValueKind.strings,
  'tun.inet6-route-exclude-address': MihomoValueKind.strings,
  'sniffer.sniffing': MihomoValueKind.strings,
  'sniffer.port-whitelist': MihomoValueKind.strings,
};

/// Never infer absence from null/false/zero. Map keys are fixed paths only;
/// policy domains and lists remain values rather than split path components.
({bool present, Object? value}) additionalSourceOf(Map<String, dynamic> config, String path) {
  Object? value = config;
  for (final part in path.split('.')) {
    if (value is! Map || !value.containsKey(part)) return (present: false, value: null);
    value = value[part];
  }
  return (present: true, value: value);
}

Object additionalDefault(MihomoValueKind kind) => switch (kind) {
  MihomoValueKind.boolean => false,
  MihomoValueKind.integer => 0,
  MihomoValueKind.string => '',
  MihomoValueKind.strings => <String>[],
};

Object validateAdditionalValue(String path, Object? value) {
  final kind = additionalMihomoKeys[path];
  if (kind == null) throw FormatException('Unsupported or protected Mihomo setting: $path');
  final valid = switch (kind) {
    MihomoValueKind.boolean => value is bool,
    MihomoValueKind.integer => value is int && value >= 0 && value <= 0x7fffffff,
    MihomoValueKind.string => value is String,
    MihomoValueKind.strings => value is List && value.every((item) => item is String || (path == 'sniffer.port-whitelist' && item is int)),
  };
  if (!valid) throw FormatException('Invalid value for $path');
  if (kind == MihomoValueKind.strings) return (value as List).map((item) => item.toString()).toList();
  return value!;
}

Map<String, Object> decodeAdditionalSettings(String content) {
  final decoded = loadPlainYaml(content);
  if (decoded == null) return {};
  if (decoded is! Map) throw const FormatException('Additional settings must be a mapping');
  return {for (final e in decoded.entries) e.key.toString(): validateAdditionalValue(e.key.toString(), e.value)};
}

/// Restore explicitly supplied section values before the application's
/// controlled overlays. Do not let a typed/default-filled core representation
/// turn an empty list/map, false or zero into an implicit default.
Map<String, dynamic> restoreExplicitMihomoSettings(
  Map<String, dynamic> raw, Map<String, dynamic> explicit,
) {
  final result = Map<String, dynamic>.of(raw);
  for (final section in ['dns', 'tun', 'sniffer', 'ntp', 'profile', 'experimental']) {
    final source = explicit[section];
    if (source is! Map) continue;
    final previous = result[section];
    final merged = <String, dynamic>{
      if (previous is Map) ...previous.cast<String, dynamic>(),
      ...source.cast<String, dynamic>(),
    };
    if (section == 'dns' && previous is Map) {
      // Mihomo's policy maps are ordered. The typed base carries their
      // order, whereas sourceSettings is a Go map serialized by key.
      for (final key in ['nameserver-policy', 'proxy-server-nameserver-policy']) {
        final supplied = source[key];
        final parsed = previous[key];
        if (supplied is Map && supplied.isNotEmpty && parsed is Map &&
            parsed.length == supplied.length &&
            supplied.keys.every(parsed.containsKey)) {
          merged[key] = parsed;
        }
      }
      final fallback = source['fallback-filter'];
      final parsedFallback = previous['fallback-filter'];
      if (fallback is Map && fallback.isNotEmpty && parsedFallback is Map) {
        merged['fallback-filter'] = {...parsedFallback, ...fallback};
      }
    }
    result[section] = merged;
  }
  for (final key in additionalMihomoKeys.keys.where((key) => !key.contains('.'))) {
    if (explicit.containsKey(key)) result[key] = explicit[key];
  }
  return result;
}

void applyAdditionalSettings(Map<dynamic, dynamic> raw, String content) {
  final values = decodeAdditionalSettings(content);
  for (final entry in values.entries) {
    final parts = entry.key.split('.');
    if (parts.length == 1) {
      raw[parts.single] = entry.value;
    } else {
      final previous = raw[parts.first];
      raw[parts.first] = {if (previous is Map) ...previous, parts.last: entry.value};
    }
  }
}

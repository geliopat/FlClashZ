import 'dart:convert';

import 'package:fl_clash/models/models.dart';
import 'package:test/test.dart';

void main() {
  test('Z3 flags with process-wide environment semantics are marked restart-required', () {
    expect(additionalRequiresCoreRestart('experimental.quic-go-disable-gso'), isTrue);
    expect(additionalRequiresCoreRestart('experimental.quic-go-disable-ecn'), isTrue);
    expect(additionalRequiresCoreRestart('experimental.dialer-ip4p-convert'), isFalse);
    expect(additionalRequiresCoreRestart('geodata-mode'), isFalse);
  });
  test('TUN aliases are compatibility inputs, not extra controls', () {
    const path = 'tun.inet6-route-address';
    expect(additionalMihomoKeys.containsKey(path), isFalse);
    expect(() => validateAdditionalValue(path, ['2001:db8::/32']), throwsFormatException);
    final raw = <String, dynamic>{'tun': {'route-address': ['192.0.2.0/24']}};
    applyAdditionalSettings(raw, '$path: ["2001:db8::/32"]');
    expect(normalizeTunRouteAliases(Map<String, dynamic>.from(raw['tun'] as Map)), {
      'route-address': ['192.0.2.0/24', '2001:db8::/32'],
    });
    expect(yamlSectionSourcesOf(1, raw).tun['route-address'],
        ['192.0.2.0/24', '2001:db8::/32']);
    expect(normalizeTunRouteAliases({'inet4-route-address': []}), {'route-address': []});
    expect(normalizeTunRouteAliases({'inet4-route-address': 'invalid'}),
        {'inet4-route-address': 'invalid'});
  });
  test('obsolete local sniffer fields do not invalidate other settings', () {
    expect(decodeAdditionalSettings(
      'sniffer.sniffing: [TLS]\nsniffer.port-whitelist: [443]\ngeodata-mode: true',
    ), {'geodata-mode': true});
    expect(additionalMihomoKeys.containsKey('sniffer.sniffing'), isFalse);
    expect(additionalMihomoKeys.containsKey('sniffer.port-whitelist'), isFalse);
    expect(() => validateAdditionalValue('sniffer.sniffing', ['TLS']),
        throwsFormatException);
  });
  test('additional overrides replace only explicit paths, preserve zero/false/empty', () {
    final raw = <String,dynamic>{
      'geodata-mode': true, 'tun': {'auto-route': true, 'icmp-timeout': 20, 'loopback-address': ['127.0.0.1']},
      'profile': {'store-selected': false, 'store-fake-ip': true},
    };
    applyAdditionalSettings(raw, 'geodata-mode: false\ntun.icmp-timeout: 0\ntun.loopback-address: []\nprofile.store-fake-ip: false');
    expect(raw['geodata-mode'], false);
    expect(raw['tun'], {'auto-route': true, 'icmp-timeout': 0, 'loopback-address': []});
    expect(raw['profile'], {'store-selected': false, 'store-fake-ip': false});
  });
  test('Windows does not expose unsupported MPTCP as an inbound option', () {
    expect(additionalMihomoKeys.containsKey('inbound-mptcp'), isFalse);
    expect(() => validateAdditionalValue('inbound-mptcp', true), throwsFormatException);
    expect(decodeAdditionalSettings('inbound-mptcp: true\ngeodata-mode: false'),
        {'geodata-mode': false});
    expect(additionalMihomoKeys.containsKey('inbound-tfo'), isTrue);
    expect(additionalMihomoKeys.containsKey('global-client-fingerprint'), isFalse);
  });

  test('source recovery retains explicit values and ordered DNS policies', () {
    final policy = <String, Object>{
      'geosite:private': 'https://dns.example/dns-query#DIRECT',
      'example.com': ['https://dns.example/dns-query#Москва'],
    };
    final parsed = <String, dynamic>{
      'dns': {'nameserver-policy': policy, 'fallback': ['default'], 'ipv6': true,
        'fallback-filter': {'geoip': true, 'geoip-code': 'CN'}},
      'tun': {'icmp-timeout': 30, 'loopback-address': ['127.0.0.1']},
      'sniffer': {'enable': true},
    };
    final result = restoreExplicitMihomoSettings(parsed, {
      'dns': {'nameserver-policy': {'example.com': policy['example.com'],
        'geosite:private': policy['geosite:private']},
        'fallback': [], 'ipv6': false, 'fallback-filter': {'geoip': false}},
      'tun': {'icmp-timeout': 0, 'loopback-address': []},
      'sniffer': {'enable': false, 'future-field': 'retained'},
      'geodata-mode': false,
    });
    expect((result['dns']['nameserver-policy'] as Map).keys.toList(), policy.keys.toList());
    expect(result['dns']['nameserver-policy'], policy);
    expect(result['dns']['fallback'], isEmpty);
    expect(result['dns']['ipv6'], isFalse);
    expect(result['dns']['fallback-filter'], {'geoip': false, 'geoip-code': 'CN'});
    expect(result['tun'], {'icmp-timeout': 0, 'loopback-address': []});
    expect(result['sniffer']['future-field'], 'retained');
    expect(result['geodata-mode'], isFalse);
    expect(parsed['dns']['fallback'], ['default']);
  });
  test('app owned and arbitrary paths are refused', () {
    for (final path in ['tun.auto-route', 'tun.file-descriptor', 'external-controller-pipe', 'authentication', 'listeners', 'proxy-providers']) {
      expect(() => decodeAdditionalSettings('$path: false'), throwsFormatException);
    }
    expect(() => decodeAdditionalSettings('tun.icmp-timeout: -1'), throwsFormatException);
  });
  test('profile persistence and release are independent', () {
    const initial = ProfileOverrides(additionalSettingsYaml: 'geodata-mode: false');
    final restored = ProfileOverrides.fromJson(jsonDecode(jsonEncode(initial)) as Map<String, dynamic>);
    expect(restored.additionalSettingsYaml, initial.additionalSettingsYaml);
    expect(restored.copyWith(additionalSettingsYaml: '').additionalSettingsYaml, '');
    expect(restored.copyWith(), restored);
  });
}

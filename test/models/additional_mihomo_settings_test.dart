import 'dart:convert';

import 'package:fl_clash/models/models.dart';
import 'package:test/test.dart';

void main() {
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
  test('Z3 inbound MPTCP inherits explicit false and can be overridden', () {
    final raw = restoreExplicitMihomoSettings(
      {'inbound-mptcp': true}, {'inbound-mptcp': false},
    );
    expect(additionalSourceOf(raw, 'inbound-mptcp'),
        (present: true, value: false));
    applyAdditionalSettings(raw, 'inbound-mptcp: true');
    expect(raw['inbound-mptcp'], isTrue);
    expect(() => decodeAdditionalSettings('inbound-mptcp: 1'),
        throwsFormatException);
    expect(additionalMihomoKeys.containsKey('global-client-fingerprint'),
        isFalse);
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

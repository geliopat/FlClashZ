import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:yaml/yaml.dart';

const _profileDns = <String, dynamic>{
  'enable': true,
  'listen': '0.0.0.0:53',
  'nameserver': ['9.9.9.9'],
  'fallback-filter': {
    'geoip': false,
    'domain': ['keep.me'],
  },
};

const _dns = Dns(
  listen: ':1053',
  ipv6: true,
  nameserver: ['1.1.1.1'],
  fallbackFilter: FallbackFilter(geoip: true),
);

const _keys = {
  DnsOverrideKey.nameserver,
  DnsOverrideKey.fallbackFilterGeoip,
  DnsOverrideKey.ipv6,
};

Future<YamlMap> _dnsOf({
  required Map<String, dynamic> rawConfig,
  Dns dns = _dns,
  Set<DnsOverrideKey> keys = _keys,
  bool keepEmpty = false,
}) async {
  final result = await makeRealProfileTask(
    MakeRealProfileState(
      profilesPath: '/profiles',
      profileId: 1,
      rawConfig: rawConfig,
      realPatchConfig: const PatchClashConfig(),
      overrides: ProfileOverrides(dns: dns, dnsOverrideKeys: keys),
      keepEmptyDnsOverrides: keepEmpty,
      appendSystemDns: false,
      proxyGroups: const [],
      rules: const [],
      addedRules: const [],
      defaultUA: 'FlClash-Test',
    ),
  );
  final config = loadYaml(result.yaml) as YamlMap;
  return config['dns'] as YamlMap;
}

void main() {
  test('overrides only the selected DNS keys of an enabled profile', () async {
    final dns = await _dnsOf(rawConfig: {'dns': _profileDns});

    expect(dns['nameserver'], ['1.1.1.1']);
    expect(dns['ipv6'], true);
    expect(dns['listen'], '0.0.0.0:53');
    expect(dns['fallback-filter'], {
      'geoip': true,
      'domain': ['keep.me'],
    });
  });

  test('leaves an enabled profile alone without picked keys', () async {
    final dns = await _dnsOf(rawConfig: {'dns': _profileDns}, keys: {});

    expect(dns['nameserver'], ['9.9.9.9']);
    expect(dns.containsKey('ipv6'), isFalse);
    expect(dns['fallback-filter'], {
      'geoip': false,
      'domain': ['keep.me'],
    });
  });

  test(
    'fills the minimal defaults plus overrides for a profile without DNS',
    () async {
      final dns = await _dnsOf(rawConfig: {});

      expect(dns, {
        'enable': true,
        'enhanced-mode': 'fake-ip',
        'nameserver': ['1.1.1.1'],
        'ipv6': true,
        'fallback-filter': {'geoip': true},
      });
    },
  );

  test('Windows DNS protection preserves supplied resolvers and mode', () async {
    final dns = await _dnsOf(
      rawConfig: {
        'dns': {
          'enable': false,
          'enhanced-mode': 'redir-host',
          'nameserver': ['https://dns.example/dns-query#DIRECT'],
          'respect-rules': true,
          'fallback': [],
        },
      },
      keys: {},
    );
    expect(dns['enable'], isTrue);
    expect(dns['enhanced-mode'], Platform.isWindows ? 'redir-host' : 'fake-ip');
    expect(dns['nameserver'], Platform.isWindows
        ? ['https://dns.example/dns-query#DIRECT']
        : baselineDns.nameserver);
    expect(dns['respect-rules'], isTrue);
    expect(dns['fallback'], isEmpty);
  });

  test('missing or empty resolvers get a usable Windows DNS baseline', () async {
    final dns = await _dnsOf(
      rawConfig: {'dns': {'enable': false, 'nameserver': []}},
      keys: {},
    );
    expect(dns['enable'], isTrue);
    expect(dns['nameserver'], baselineDns.nameserver);
  });

  test('a key picked without a value writes nothing', () async {
    final dns = await _dnsOf(
      rawConfig: {'dns': _profileDns},
      dns: const Dns(nameserver: [], listen: ''),
      keys: {DnsOverrideKey.nameserver, DnsOverrideKey.listen},
    );

    expect(dns['nameserver'], ['9.9.9.9']);
    expect(dns['listen'], '0.0.0.0:53');
  });

  test('an app entry emptied over a subscription replaces its value, save '
      'nameserver', () async {
    final dns = await _dnsOf(
      rawConfig: {'dns': _profileDns},
      dns: const Dns(
        nameserver: [],
        listen: '',
        fallbackFilter: FallbackFilter(domain: []),
      ),
      keys: {
        DnsOverrideKey.nameserver,
        DnsOverrideKey.listen,
        DnsOverrideKey.fallbackFilterDomain,
      },
      keepEmpty: true,
    );

    expect(dns['nameserver'], ['9.9.9.9']);
    expect(dns['listen'], '');
    expect(dns['fallback-filter'], {'geoip': false, 'domain': []});
  });
}

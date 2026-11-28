import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';

import '../helpers/app_paths.dart';

void main() {
  late Directory root;

  setUpAll(() async {
    root = Directory.systemTemp.createTempSync('legacy_migration_task_test');
    // File.copy does not create parent directories; in production these are the
    // already-existing temp and cache dirs the platform hands out.
    Directory(join(root.path, 'tmp')).createSync(recursive: true);
    Directory(join(root.path, 'archive')).createSync(recursive: true);
    await useAppPaths(root);
  });

  tearDownAll(() {
    try {
      root.deleteSync(recursive: true);
    } catch (_) {}
  });

  Directory makeDir(String name) =>
      Directory(join(root.path, name, uniqueId))..createSync(recursive: true);

  File writeFile(String path, String content) => File(path)
    ..createSync(recursive: true)
    ..writeAsStringSync(content);

  group('shakeOrphanFiles', () {
    test('reports only the files whose name is not a live id', () {
      final profiles = makeDir('profiles');
      final scripts = makeDir('scripts');
      final providers = makeDir('providers');
      writeFile(join(profiles.path, '1.yaml'), 'keep');
      writeFile(join(profiles.path, '2.yaml'), 'drop');
      writeFile(join(scripts.path, '10.js'), 'keep');
      writeFile(join(scripts.path, '20.js'), 'drop');
      writeFile(join(providers.path, '1', 'proxies', 'abc'), 'keep');
      writeFile(join(providers.path, '2', 'proxies', 'abc'), 'drop');

      final orphans = shakeOrphanFiles(
        profileIds: [1],
        scriptIds: [10],
        profilesDirPath: profiles.path,
        providersDirPath: providers.path,
        scriptsDirPath: scripts.path,
        providerFileNames: const [],
        providerCacheDirPath: join(root.path, 'missing'),
      );

      expect(orphans.map(basename), unorderedEquals(['2.yaml', '20.js', '2']));
      expect(
        orphans.singleWhere((path) => basename(path) == '2'),
        join(providers.path, '2'),
      );
    });

    test('reports the whole provider directory a dead profile left behind', () {
      final providers = makeDir('providers');
      writeFile(join(providers.path, '3', 'proxies', 'abc'), 'drop');
      writeFile(join(providers.path, '3', 'rules', 'def'), 'drop');
      writeFile(join(providers.path, 'stray'), 'drop');

      final orphans = shakeOrphanFiles(
        profileIds: const [],
        scriptIds: const [],
        profilesDirPath: join(root.path, 'missing'),
        providersDirPath: providers.path,
        scriptsDirPath: join(root.path, 'missing'),
        providerFileNames: const [],
        providerCacheDirPath: join(root.path, 'missing'),
      );

      expect(
        orphans,
        unorderedEquals([
          join(providers.path, '3'),
          join(providers.path, 'stray'),
        ]),
      );
    });

    test('treats an unparsable file name as an orphan', () {
      final profiles = makeDir('profiles');
      writeFile(join(profiles.path, 'stray.yaml'), 'drop');

      final orphans = shakeOrphanFiles(
        profileIds: [1],
        scriptIds: const [],
        profilesDirPath: profiles.path,
        providersDirPath: join(root.path, 'missing'),
        scriptsDirPath: join(root.path, 'missing'),
        providerFileNames: const [],
        providerCacheDirPath: join(root.path, 'missing'),
      );

      expect(orphans.map(basename), ['stray.yaml']);
    });

    test('does not descend into the nested providers folder', () {
      final profiles = makeDir('profiles');
      final nested = Directory(join(profiles.path, 'providers'))
        ..createSync(recursive: true);
      writeFile(join(nested.path, '99.yaml'), 'not scanned here');

      final orphans = shakeOrphanFiles(
        profileIds: [1],
        scriptIds: const [],
        profilesDirPath: profiles.path,
        providersDirPath: join(root.path, 'missing'),
        scriptsDirPath: join(root.path, 'missing'),
        providerFileNames: const [],
        providerCacheDirPath: join(root.path, 'missing'),
      );

      expect(orphans, isEmpty);
    });

    test('reports a provider cache file no row names any more', () {
      final cache = makeDir('provider_cache');
      writeFile(join(cache.path, 'rules', 'live'), 'keep');
      writeFile(join(cache.path, 'rules', 'stale'), 'drop');

      final orphans = shakeOrphanFiles(
        profileIds: const [],
        scriptIds: const [],
        providerFileNames: const ['live'],
        profilesDirPath: join(root.path, 'missing'),
        providersDirPath: join(root.path, 'missing'),
        providerCacheDirPath: cache.path,
        scriptsDirPath: join(root.path, 'missing'),
      );

      expect(orphans, [join(cache.path, 'rules', 'stale')]);
    });

    test('ignores directories that do not exist', () {
      expect(
        shakeOrphanFiles(
          profileIds: const [],
          scriptIds: const [],
          profilesDirPath: join(root.path, 'nope'),
          providersDirPath: join(root.path, 'nope'),
          scriptsDirPath: join(root.path, 'nope'),
          providerFileNames: const [],
          providerCacheDirPath: join(root.path, 'missing'),
        ),
        isEmpty,
      );
    });
  });

  group('migrateLegacyConfig', () {
    late Directory source;
    late Directory target;

    setUp(() {
      source = makeDir('legacy_source');
      target = makeDir('legacy_target');
    });

    Map<String, Object?> legacyConfig({
      List<Object?> scripts = const [],
      List<Object?> rules = const [],
      List<Object?> profiles = const [],
      Map<String, Object?> extra = const {},
    }) => {'scripts': scripts, 'rules': rules, 'profiles': profiles, ...extra};

    test(
      'rewrites script ids and writes the content into the target',
      () async {
        final data = await migrateLegacyConfig(
          configMap: legacyConfig(
            scripts: [
              {'id': 'script-a', 'label': 'A', 'content': 'export default 1;'},
            ],
          ),
          sourcePath: source.path,
          targetPath: target.path,
        );

        final script = data.scripts.single;
        expect(script.label, 'A');
        expect(
          File(
            join(target.path, 'scripts', '${script.id}.js'),
          ).readAsStringSync(),
          'export default 1;',
        );
      },
    );

    test('skips a script entry that is missing a required field', () async {
      final data = await migrateLegacyConfig(
        configMap: legacyConfig(
          scripts: [
            {'id': 'no-content', 'label': 'A'},
            {'id': 'ok', 'label': 'B', 'content': 'body'},
          ],
        ),
        sourcePath: source.path,
        targetPath: target.path,
      );

      expect(data.scripts.map((item) => item.label), ['B']);
    });

    test('falls back to scriptProps when the scripts list is empty', () async {
      final data = await migrateLegacyConfig(
        configMap: legacyConfig(
          extra: {
            'scriptProps': {
              'scripts': [
                {'id': 'nested', 'label': 'Nested', 'content': 'body'},
              ],
            },
          },
        ),
        sourcePath: source.path,
        targetPath: target.path,
      );

      expect(data.scripts.map((item) => item.label), ['Nested']);
    });

    test('copies the profile file under its new id', () async {
      writeFile(join(source.path, 'profiles', 'old-1.yaml'), 'proxies: []');

      final data = await migrateLegacyConfig(
        configMap: legacyConfig(
          profiles: [
            {'id': 'old-1', 'label': 'Legacy', 'autoUpdateDuration': 0},
          ],
        ),
        sourcePath: source.path,
        targetPath: target.path,
      );

      final profile = data.profiles.single;
      expect(profile.label, 'Legacy');
      expect(
        File(
          join(target.path, 'profiles', '${profile.id}.yaml'),
        ).readAsStringSync(),
        'proxies: []',
      );
    });

    test('a profile id that is a path reaches no file outside', () async {
      final outside = makeDir('legacy_outside');
      writeFile(join(outside.path, 'secret.yaml'), 'secret: 1');
      final escape = posix.relative(
        join(outside.path, 'secret'),
        from: join(source.path, 'profiles'),
      );

      final data = await migrateLegacyConfig(
        configMap: legacyConfig(
          profiles: [
            {'id': escape, 'label': 'Escape', 'autoUpdateDuration': 0},
            {'id': 'missing', 'label': 'Missing', 'autoUpdateDuration': 0},
          ],
        ),
        sourcePath: source.path,
        targetPath: target.path,
      );

      expect(data.profiles.map((profile) => profile.label), ['Missing']);
      expect(Directory(join(target.path, 'profiles')).existsSync(), isFalse);
      expect(
        File(join(source.path, 'profiles', 'missing.yaml')).existsSync(),
        isFalse,
      );
    });

    test('carries a FlClashX 0.4 profile with its headers and rules', () async {
      writeFile(
        join(source.path, 'profiles', '1720000000000.yaml'),
        'proxies: []',
      );

      final data = await migrateLegacyConfig(
        configMap: legacyConfig(
          profiles: [
            {
              'id': '1720000000000',
              'label': 'Remna',
              'url': 'https://sub.example.com/abc',
              'autoUpdateDuration': 86400000000,
              'autoUpdate': true,
              'selectedMap': {'Auto': 'NL'},
              'unfoldSet': ['Auto'],
              'subscriptionInfo': {
                'upload': 1,
                'download': 2,
                'total': 3,
                'expire': 4,
              },
              'providerHeaders': {
                'announce': 'Hi',
                'flclashx-newboard': 'true',
              },
              'overrideData': {
                'enable': true,
                'rule': {
                  'type': 'added',
                  'overrideRules': [
                    {'id': 'o1', 'value': 'DOMAIN,ignored.com,DIRECT'},
                  ],
                  'addedRules': [
                    {'id': 'a1', 'value': 'DOMAIN,example.com,DIRECT'},
                  ],
                },
              },
            },
            {
              'id': '1720000000001',
              'autoUpdateDuration': 0,
              'overrideData': {
                'enable': false,
                'rule': {
                  'type': 'added',
                  'addedRules': [
                    {'id': 'a2', 'value': 'DOMAIN,off.com,DIRECT'},
                  ],
                },
              },
            },
          ],
          extra: {
            'currentProfileId': '1720000000000',
            'appSetting': {
              'newDashboard': true,
              'dashboardWidgets': ['announce', 'metainfo', 'zashboardButton'],
            },
          },
        ),
        sourcePath: source.path,
        targetPath: target.path,
      );

      final profile = data.profiles.first;
      expect(profile.type, ProfileType.url);
      expect(profile.label, 'Remna');
      expect(profile.providerHeaders, {
        'announce': 'Hi',
        'flclashx-newboard': 'true',
      });
      expect(profile.selectedMap, {'Auto': 'NL'});
      expect(profile.subscriptionInfo?.total, 3);
      expect(profile.autoUpdateDuration, const Duration(days: 1));
      expect(data.rules.map((rule) => rule.content), ['example.com']);
      expect(data.rules.single.profileId, profile.id);
      expect(data.configMap?['currentProfileId'], profile.id);
      expect(
        File(
          join(target.path, 'profiles', '${profile.id}.yaml'),
        ).readAsStringSync(),
        'proxies: []',
      );

      final config = Config.realFromJson(data.configMap);
      expect(config.appSettingProps.dashboardWidgets, [
        DashboardWidget.currentOutbound,
        DashboardWidget.announcement,
        DashboardWidget.profiles,
      ]);
    });

    test(
      'turns the FlClashX 0.4 override switches into owned settings',
      () async {
        final data = await migrateLegacyConfig(
          configMap: legacyConfig(
            extra: {
              'appSetting': {
                'overrideNetworkSettings': true,
                'overrideProviderSettings': true,
              },
            },
          ),
          sourcePath: source.path,
          targetPath: target.path,
        );

        final owned = Config.realFromJson(
          data.configMap,
        ).appSettingProps.ownedSettings;
        expect(
          owned,
          containsAll([
            'clash.mixed-port',
            'clash.allow-lan',
            'clash.ipv6',
            'clash.find-process-mode',
            'clash.tun.stack',
            ...appSwitchSettings.values,
          ]),
        );
        expect(owned, hasLength(5 + appSwitchSettings.length));

        final untouched = await migrateLegacyConfig(
          configMap: legacyConfig(
            extra: {
              'appSetting': {
                'overrideNetworkSettings': false,
                'overrideProviderSettings': false,
              },
            },
          ),
          sourcePath: source.path,
          targetPath: target.path,
        );
        expect(
          Config.realFromJson(
            untouched.configMap,
          ).appSettingProps.ownedSettings,
          isEmpty,
        );
      },
    );

    test('links added rules to the profile that declared them', () async {
      writeFile(join(source.path, 'profiles', 'p1.yaml'), '');

      final data = await migrateLegacyConfig(
        configMap: legacyConfig(
          profiles: [
            {
              'id': 'p1',
              'autoUpdateDuration': 0,
              'overwrite': {
                'type': 'standard',
                'standardOverwrite': {
                  'addedRules': [
                    {'id': 'r1', 'value': 'DOMAIN,example.com,DIRECT'},
                  ],
                },
              },
            },
          ],
        ),
        sourcePath: source.path,
        targetPath: target.path,
      );

      final profile = data.profiles.single;
      final rule = data.rules.single;
      expect(rule.content, 'example.com');
      expect(rule.profileId, profile.id);
      expect(profile.type, ProfileType.file);
      expect(data.disabledRules, isEmpty);
    });

    test(
      'keeps a disabled rule only for a rule id it has already seen',
      () async {
        writeFile(join(source.path, 'profiles', 'p1.yaml'), '');

        final data = await migrateLegacyConfig(
          configMap: legacyConfig(
            profiles: [
              {
                'id': 'p1',
                'autoUpdateDuration': 0,
                'overwrite': {
                  'type': 'standard',
                  'standardOverwrite': {
                    'addedRules': [
                      {'id': 'r1', 'value': 'DOMAIN,example.com,DIRECT'},
                    ],
                    'disabledRuleIds': ['r1', 'never-seen'],
                  },
                },
              },
            ],
          ),
          sourcePath: source.path,
          targetPath: target.path,
        );

        expect(data.disabledRules, [
          DisabledRule(
            profileId: data.profiles.single.id,
            ruleId: data.rules.single.id,
          ),
        ]);
      },
    );

    test('gives a profile with a url the url type', () async {
      writeFile(join(source.path, 'profiles', 'p1.yaml'), '');

      final data = await migrateLegacyConfig(
        configMap: legacyConfig(
          profiles: [
            {
              'id': 'p1',
              'url': 'https://example.com/sub',
              'autoUpdateDuration': 0,
            },
          ],
        ),
        sourcePath: source.path,
        targetPath: target.path,
      );

      expect(data.profiles.single.type, ProfileType.url);
    });

    test('points the profile at its remapped script id', () async {
      writeFile(join(source.path, 'profiles', 'p1.yaml'), '');

      final data = await migrateLegacyConfig(
        configMap: legacyConfig(
          scripts: [
            {'id': 's1', 'label': 'S', 'content': 'body'},
          ],
          profiles: [
            {
              'id': 'p1',
              'autoUpdateDuration': 0,
              'overwrite': {
                'type': 'script',
                'scriptOverwrite': {'scriptId': 's1'},
              },
            },
          ],
        ),
        sourcePath: source.path,
        targetPath: target.path,
      );

      expect(data.profiles.single.scriptId, data.scripts.single.id);
      expect(data.profiles.single.extendType, ExtendType.script);
    });

    test('binds the script FlClashX 0.4 ran on every profile', () async {
      writeFile(join(source.path, 'profiles', 'p1.yaml'), '');

      final data = await migrateLegacyConfig(
        configMap: legacyConfig(
          profiles: [
            {
              'id': 'p1',
              'autoUpdateDuration': 0,
              'overrideData': {
                'enable': true,
                'rule': {
                  'type': 'added',
                  'addedRules': [
                    {'id': 'a1', 'value': 'DOMAIN,example.com,DIRECT'},
                  ],
                },
              },
            },
          ],
          extra: {
            'scriptProps': {
              'currentId': 's1',
              'scripts': [
                {'id': 's1', 'label': 'S', 'content': 'body'},
              ],
            },
          },
        ),
        sourcePath: source.path,
        targetPath: target.path,
      );

      final profile = data.profiles.single;
      expect(profile.extendType, ExtendType.script);
      expect(profile.scriptId, data.scripts.single.id);
      expect(data.rules.single.profileId, profile.id);
    });

    test(
      'keeps a FlClashX 0.4 override list replacing the profile rules',
      () async {
        writeFile(join(source.path, 'profiles', 'p1.yaml'), '');
        writeFile(join(source.path, 'profiles', 'p2.yaml'), '');

        final data = await migrateLegacyConfig(
          configMap: legacyConfig(
            profiles: [
              {
                'id': 'p1',
                'label': 'Work',
                'autoUpdateDuration': 0,
                'overrideData': {
                  'enable': true,
                  'rule': {
                    'type': 'override',
                    'overrideRules': [
                      {'id': 'o1', 'value': 'DOMAIN,example.com,DIRECT'},
                      {'id': 'o2', 'value': 'MATCH,Proxy'},
                    ],
                    'addedRules': [
                      {'id': 'a1', 'value': 'DOMAIN,unused.com,DIRECT'},
                    ],
                  },
                },
              },
              {
                'id': 'p2',
                'autoUpdateDuration': 0,
                'overrideData': {
                  'enable': true,
                  'rule': {'type': 'override', 'overrideRules': []},
                },
              },
            ],
          ),
          sourcePath: source.path,
          targetPath: target.path,
        );

        expect(data.scripts, isEmpty);
        List<String?> rulesOf(Profile profile) {
          expect(profile.extendType, ExtendType.standard);
          return [
            for (final rule in data.rules)
              if (rule.profileId == profile.id) rule.rawValue,
          ];
        }

        expect(rulesOf(data.profiles.first), [
          'DOMAIN,example.com,DIRECT',
          'MATCH,Proxy',
        ]);
        expect(rulesOf(data.profiles.last), ['MATCH,DIRECT']);
      },
    );

    test('falls a custom overwrite back to a standard one', () async {
      writeFile(join(source.path, 'profiles', 'p1.yaml'), '');

      final data = await migrateLegacyConfig(
        configMap: legacyConfig(
          profiles: [
            {
              'id': 'p1',
              'autoUpdateDuration': 0,
              'overwrite': {'type': 'custom'},
            },
          ],
        ),
        sourcePath: source.path,
        targetPath: target.path,
      );

      expect(data.profiles.single.extendType, ExtendType.standard);
    });

    test('remaps currentProfileId and nulls it when there is none', () async {
      writeFile(join(source.path, 'profiles', 'p1.yaml'), '');
      final configMap = legacyConfig(
        profiles: [
          {'id': 'p1', 'autoUpdateDuration': 0},
        ],
        extra: {'currentProfileId': 'p1'},
      );

      final data = await migrateLegacyConfig(
        configMap: configMap,
        sourcePath: source.path,
        targetPath: target.path,
      );

      expect(data.configMap?['currentProfileId'], data.profiles.single.id);

      final without = await migrateLegacyConfig(
        configMap: legacyConfig(),
        sourcePath: source.path,
        targetPath: target.path,
      );
      expect(without.configMap?['currentProfileId'], isNull);
    });

    test('renames the config keys the current schema expects', () async {
      final data = await migrateLegacyConfig(
        configMap: legacyConfig(
          extra: {
            'accessControl': <String, Object?>{'acceptList': <String>[]},
            'isAccessControl': true,
            'vpnProps': <String, Object?>{},
            'dav': {'uri': 'https://dav.example'},
            'appSetting': {'recoveryStrategy': 'compatible'},
            'proxiesStyle': {'cardType': 'expand'},
          },
        ),
        sourcePath: source.path,
        targetPath: target.path,
      );

      final configMap = data.configMap!;
      final vpnProps = configMap['vpnProps']! as Map;
      expect((vpnProps['accessControl'] as Map)['enable'], isTrue);
      expect(vpnProps['accessControlProps'], vpnProps['accessControl']);
      expect(configMap.containsKey('dav'), isFalse);
      expect(configMap.containsKey('davProps'), isFalse);
      expect((configMap['appSettingProps'] as Map).containsKey('restoreStrategy'), isFalse);
      expect((configMap['appSettingProps'] as Map).containsKey('recoveryStrategy'), isFalse);
      expect(configMap['proxiesStyleProps'], configMap['proxiesStyle']);
    });

    test('skips a profile entry without an id', () async {
      final data = await migrateLegacyConfig(
        configMap: legacyConfig(
          profiles: [
            {'label': 'no id', 'autoUpdateDuration': 0},
          ],
        ),
        sourcePath: source.path,
        targetPath: target.path,
      );

      expect(data.profiles, isEmpty);
    });
  });
}

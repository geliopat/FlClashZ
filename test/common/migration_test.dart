import 'dart:convert';

import 'package:fl_clash/common/migration.dart';
import 'package:fl_clash/common/constant.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/ui/color.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Migration', () {
    test('returns current config without rewriting storage', () async {
      final configMap = _createConfigMap();
      final store = _FakeMigrationStore(
        configMap: configMap,
        version: Migration.currentVersion,
      );

      final config = await Migration(store: store).run();

      expect(config, Config.realFromJson(configMap));
      expect(store.events, ['getConfigMap', 'isAvailable', 'getVersion']);
    });

    test('removes retired backup settings without losing other settings', () async {
      final configMap = _createConfigMap()
        ..['davProps'] = {'password': 'secret'}
        ..['currentProfileId'] = 42;
      (configMap['appSettingProps'] as Map)['restoreStrategy'] = 'override';
      final store = _FakeMigrationStore(configMap: configMap, version: 1);
      final config = await Migration(store: store).run();
      expect(config.currentProfileId, 42);
      final saved = jsonDecode(jsonEncode(store.savedConfig)) as Map;
      expect(saved.containsKey('davProps'), isFalse);
      expect((saved['appSettingProps'] as Map).containsKey('restoreStrategy'), isFalse);
      expect(store.events, ['getConfigMap', 'isAvailable', 'getVersion', 'saveConfig']);
    });

    test(
      'commits v0 cleanup and version only after migrated data is saved',
      () async {
        final configMap = <String, Object?>{
          'proxiesStyle': <String, Object?>{},
          'dav': <String, Object?>{
            'uri': 'https://example.com/dav',
            'user': 'user',
            'password': 'secret',
          },
        };
        final store = _FakeMigrationStore(
          configMap: configMap,
          version: 0,
          clashConfigMap: <String, Object?>{'mixed-port': 7890},
        );
        final migration = Migration(
          store: store,
          migrateV0: (configMap) async {
            store.events.add('migrateV0');
            expect(configMap['patchClashConfig'], store.clashConfigMap);
            return MigrationData(
              configMap: _createConfigMap(),
            );
          },
        );

        await migration.run();

        expect(store.events, [
          'getConfigMap',
          'isAvailable',
          'getVersion',
          'getClashConfigMap',
          'migrateV0',
          'restore',
          'saveConfig',
          'clearClashConfig',
          'setVersion',
        ]);
        expect(store.savedConfig, isNotNull);
        expect(store.didClearClashConfig, isTrue);
        expect(store.version, Migration.currentVersion);
      },
    );

    test(
      'preserves legacy clash config when current-shaped data has version zero',
      () async {
        final configMap = _createConfigMap()..remove('patchClashConfig');
        final clashConfigMap = _createClashConfigMap(mixedPort: 1234);
        final store = _FakeMigrationStore(
          configMap: configMap,
          version: 0,
          clashConfigMap: clashConfigMap,
        );

        final config = await Migration(store: store).run();

        expect(config.patchClashConfig.mixedPort, 1234);
        expect(store.savedConfig?.patchClashConfig.mixedPort, 1234);
        expect(store.didClearClashConfig, isTrue);
        expect(store.events, [
          'getConfigMap',
          'isAvailable',
          'getVersion',
          'getClashConfigMap',
          'restore',
          'saveConfig',
          'clearClashConfig',
          'setVersion',
        ]);
      },
    );

    test('does not clear legacy clash config when saving fails', () async {
      final configMap = _createConfigMap()..remove('patchClashConfig');
      final store = _FakeMigrationStore(
        configMap: configMap,
        version: 0,
        clashConfigMap: _createClashConfigMap(mixedPort: 1234),
        configSaveResult: false,
      );

      await expectLater(
        Migration(store: store).run(),
        throwsA(isA<StateError>()),
      );

      expect(store.didClearClashConfig, isFalse);
      expect(store.version, 0);
      expect(store.events, [
        'getConfigMap',
        'isAvailable',
        'getVersion',
        'getClashConfigMap',
        'restore',
        'saveConfig',
      ]);
    });

    test('starts with defaults when the store cannot be opened', () async {
      final store = _FakeMigrationStore(
        configMap: null,
        version: 0,
        configSaveResult: false,
        available: false,
      );

      final config = await Migration(store: store).run();

      expect(config, isNotNull);
      expect(store.didClearClashConfig, isFalse);
      expect(store.version, 0);
      expect(store.events, ['getConfigMap', 'isAvailable']);
    });

    test('unavailable store never imports, restores or writes markers', () async {
      final store = _FakeMigrationStore(
        configMap: _createConfigMap()..['currentProfileId'] = 42,
        version: 0,
        available: false,
        upgradeVersion: 0,
      );
      final config = await Migration(
        store: store,
        importLegacy: () async => throw StateError('must not import'),
        migrateV0: (_) async => throw StateError('must not migrate'),
      ).run();
      expect(config.currentProfileId, 42);
      expect(store.events, ['getConfigMap', 'isAvailable']);
      expect(store.legacyImported, isFalse);
      expect(store.upgradeVersion, 0);
    });

    test('rejects unsupported versions before importing or writing', () async {
      for (final version in [-1, Migration.currentVersion + 1]) {
        final store = _FakeMigrationStore(configMap: null, version: version);
        await expectLater(
          Migration(store: store, importLegacy: () async => throw StateError('must not import')).run(),
          throwsStateError,
        );
        expect(store.events, ['getConfigMap', 'isAvailable', 'getVersion']);
        expect(store.version, version);
      }
    });

    test('failed legacy cleanup leaves version uncommitted for retry', () async {
      final store = _FakeMigrationStore(
        configMap: _createConfigMap()..remove('patchClashConfig'),
        clashConfigMap: _createClashConfigMap(mixedPort: 1234),
        version: 0,
      )..clearError = StateError('blocked cleanup');
      await expectLater(Migration(store: store).run(), throwsStateError);
      expect(store.savedConfig?.patchClashConfig.mixedPort, 1234);
      expect(store.version, 0);
      expect(store.didClearClashConfig, isFalse);
      store.clearError = null;
      await Migration(store: store).run();
      expect(store.version, Migration.currentVersion);
      expect(store.didClearClashConfig, isTrue);
    });

    test('migrates the FlClashX 0.4 config a fresh store imports', () async {
      final store = _FakeMigrationStore(configMap: null, version: 0);
      final legacy = <String, Object?>{'proxiesStyle': <String, Object?>{}};
      final legacyClash = <String, Object?>{'mixed-port': 1080};
      Map<String, Object?>? migrated;

      await Migration(
        store: store,
        importLegacy: () async => (config: legacy, clashConfig: legacyClash),
        migrateV0: (configMap) async {
          migrated = configMap;
          return MigrationData(configMap: _createConfigMap());
        },
      ).run();

      expect(migrated?['proxiesStyle'], isNotNull);
      expect(migrated?['patchClashConfig'], legacyClash);
      expect(store.events, isNot(contains('getClashConfigMap')));
      expect(store.version, Migration.currentVersion);
    });

    test('imports nothing over a store that has profiles', () async {
      var imported = false;
      final store = _FakeMigrationStore(
        configMap: _createConfigMap(),
        version: Migration.currentVersion,
      )..profiles = true;

      await Migration(
        store: store,
        importLegacy: () async {
          imported = true;
          return null;
        },
      ).run();

      expect(imported, isFalse);
      expect(store.legacyImported, isTrue);
    });

    test('recovers the 0.4 profiles a prerelease store left behind, once, '
        'keeping its settings', () async {
      final configMap = _createConfigMap()
        ..['currentProfileId'] = null
        ..['themeProps'] = {'primaryColor': 0xFF123456};
      final store = _FakeMigrationStore(
        configMap: configMap,
        version: Migration.currentVersion,
      );
      var imports = 0;
      Migration migration() => Migration(
        store: store,
        importLegacy: () async {
          imports++;
          return (
            config: <String, Object?>{'proxiesStyle': <String, Object?>{}},
            clashConfig: <String, Object?>{'mixed-port': 1080},
          );
        },
        migrateV0: (_) async => MigrationData(
          configMap: _createConfigMap()..['currentProfileId'] = 42,
        ),
      );

      final config = await migration().run();

      expect(store.events, contains('restore'));
      expect(config.currentProfileId, 42);
      expect(
        config.themeProps.primaryColor,
        Config.realFromJson(configMap).themeProps.primaryColor,
      );
      expect(
        config.patchClashConfig,
        Config.realFromJson(configMap).patchClashConfig,
      );
      expect(store.legacyImported, isTrue);

      await migration().run();
      expect(imports, 1);
    });

    test('a recovery cut short finishes on a later launch', () async {
      final store = _FakeMigrationStore(
        configMap: _createConfigMap()..['currentProfileId'] = null,
        version: Migration.currentVersion,
        configSaveResult: false,
      );
      Migration migration() => Migration(
        store: store,
        importLegacy: () async => (
          config: <String, Object?>{'proxiesStyle': <String, Object?>{}},
          clashConfig: null,
        ),
        migrateV0: (_) async => MigrationData(
          configMap: _createConfigMap()..['currentProfileId'] = 42,
          profiles: [Profile.normal(label: 'p').copyWith(id: 42)],
        ),
      );

      await migration().run();
      expect(store.events, isNot(contains('restore')));
      expect(store.legacyImported, isFalse);

      store
        ..configSaveResult = true
        ..restoreError = StateError('exited');
      await expectLater(migration().run(), throwsStateError);
      expect(store.savedConfig?.currentProfileId, 42);
      expect(store.profiles, isFalse);
      expect(store.legacyImported, isFalse);

      store.restoreError = null;
      await migration().run();
      expect(store.restoredData?.profiles.single.id, 42);
      expect(store.savedConfig?.currentProfileId, 42);
      expect(store.legacyImported, isTrue);
    });

    test('marks a store without 0.4 data so it never looks again', () async {
      final store = _FakeMigrationStore(
        configMap: _createConfigMap(),
        version: Migration.currentVersion,
      );

      await Migration(store: store, importLegacy: () async => null).run();

      expect(store.events, isNot(contains('restore')));
      expect(store.legacyImported, isTrue);
    });

    group('upgrade', () {
      Map<String, Object?> customized() =>
          _createConfigMap()
            ..['themeProps'] = {
              'primaryColor': 0xFF123456,
              'primaryColors': [0xFF795548, 0xFF123456],
              'schemeVariant': 'tonalSpot',
              'themeMode': 'dark',
              'pureBlack': true,
              'liquidGlass': true,
              'systemFontFamily': 'Beta Serif',
            };

      test('starts theme colors over once and keeps the rest', () async {
        final store = _FakeMigrationStore(
          configMap: customized(),
          version: Migration.currentVersion,
          upgradeVersion: 0,
        );

        final config = await Migration(store: store).run();

        final theme = config.themeProps;
        expect(theme.primaryColor, defaultPrimaryColor);
        expect(theme.primaryColors, defaultPrimaryColors);
        expect(theme.colorStyle, ColorStyle.vivid);
        expect(theme.themeMode, ThemeMode.dark);
        expect(theme.pureBlack, isTrue);
        expect(theme.liquidGlass, LiquidGlassMode.ultra);
        expect(theme.fontFamily, 'Beta Serif');
        expect(store.savedConfig, config);
        expect(store.version, Migration.currentVersion);
        expect(store.upgradeVersion, Migration.upgradeVersion);
        expect(store.events, [
          'getConfigMap',
          'isAvailable',
          'getVersion',
          'saveConfig',
          'setUpgradeVersion',
        ]);

        final later = _FakeMigrationStore(
          configMap: jsonDecode(
            jsonEncode(config.copyWith.themeProps(primaryColor: 0xFF123456)),
          ),
          version: store.version,
          upgradeVersion: store.upgradeVersion,
        );
        final kept = await Migration(store: later).run();

        expect(kept.themeProps.primaryColor, 0xFF123456);
        expect(later.events, ['getConfigMap', 'isAvailable', 'getVersion']);
      });

      test('keeps standard glass on the ultra tier it became, once', () async {
        Future<LiquidGlassMode> upgrade(String mode, int from) async {
          final configMap = _createConfigMap();
          (configMap['themeProps']! as Map<String, Object?>)['liquidGlass'] =
              mode;
          final store = _FakeMigrationStore(
            configMap: configMap,
            version: Migration.currentVersion,
            upgradeVersion: from,
          );
          return (await Migration(store: store).run()).themeProps.liquidGlass;
        }

        expect(await upgrade('standard', 1), LiquidGlassMode.ultra);
        expect(await upgrade('none', 1), LiquidGlassMode.none);
        expect(await upgrade('standard', 2), LiquidGlassMode.standard);
      });

      test('moves presets picked before to the current system colors, '
          'once', () async {
        Future<ThemeProps> upgrade(int from) async {
          final configMap = _createConfigMap();
          (configMap['themeProps']! as Map<String, Object?>)
            ..['primaryColor'] = 0xFFFF9500
            ..['primaryColors'] = [
              0xFF007AFF,
              0xFFAF52DE,
              0xFFCB30E0,
              0xFFFF9500,
              0xFF123456,
            ];
          final store = _FakeMigrationStore(
            configMap: configMap,
            version: Migration.currentVersion,
            upgradeVersion: from,
          );
          return (await Migration(store: store).run()).themeProps;
        }

        final moved = await upgrade(2);
        expect(moved.primaryColor, 0xFFFF8D28);
        expect(moved.primaryColors, [
          0xFF007AFF,
          0xFFCB30E0,
          0xFFFF8D28,
          0xFF123456,
        ]);
        expect((await upgrade(3)).primaryColor, 0xFFFF9500);
      });

      test('a certificate check turned off before is read back on', () async {
        final configMap = _createConfigMap();
        (configMap['appSettingProps']!
                as Map<String, Object?>)['checkCertificate'] =
            false;
        final store = _FakeMigrationStore(
          configMap: configMap,
          version: Migration.currentVersion,
          upgradeVersion: Migration.upgradeVersion,
        );

        final config = await Migration(store: store).run();

        expect(config.appSettingProps.checkCertificate, isTrue);
      });

      test('a new install only records it', () async {
        final store = _FakeMigrationStore(
          configMap: null,
          version: 0,
          upgradeVersion: 0,
        );

        final config = await Migration(store: store).run();

        expect(config.themeProps, defaultThemeProps);
        expect(store.savedConfig?.themeProps, defaultThemeProps);
        expect(hasYamlSourceVersion(config.appSettingProps.panelSetSettings), isTrue);
        expect(hasYamlSourceVersion(store.savedConfig!.appSettingProps.panelSetSettings), isTrue);
        expect(store.upgradeVersion, Migration.upgradeVersion);
        expect(
          store.events.where((event) => event == 'saveConfig'),
          hasLength(1),
        );
      });

      test('waits for the next launch when saving fails', () async {
        final store = _FakeMigrationStore(
          configMap: customized(),
          version: Migration.currentVersion,
          upgradeVersion: 0,
          configSaveResult: false,
        );

        final config = await Migration(store: store).run();

        expect(config.themeProps.primaryColor, 0xFF123456);
        expect(store.upgradeVersion, 0);
      });
    });

    test('keeps what it can read of a damaged current config', () async {
      final configMap = _createConfigMap()
        ..['currentProfileId'] = 7
        ..['excludeSSIDs'] = 'home';
      final store = _FakeMigrationStore(
        configMap: configMap,
        version: Migration.currentVersion,
      );

      final config = await Migration(store: store).run();

      expect(config.currentProfileId, 7);
      expect(config.excludeSSIDs, isEmpty);
      expect(store.events, ['getConfigMap', 'isAvailable', 'getVersion']);
    });

    test('keeps the current version when retired settings cleanup fails', () async {
      final configMap = _createConfigMap()
        ..['davProps'] = {'password': 'secret'};
      final store = _FakeMigrationStore(
        configMap: configMap,
        version: Migration.currentVersion,
        configSaveResult: false,
      );

      await expectLater(
        Migration(store: store).run(),
        throwsA(isA<StateError>()),
      );

      expect(store.events, ['getConfigMap', 'isAvailable', 'getVersion', 'saveConfig']);
      expect(store.version, Migration.currentVersion);
    });
  });
}

Map<String, Object?> _createConfigMap() {
  return jsonDecode(
        jsonEncode(Config(themeProps: defaultThemeProps)),
      )
      as Map<String, Object?>;
}

Map<String, Object?> _createClashConfigMap({required int mixedPort}) {
  return jsonDecode(jsonEncode(PatchClashConfig(mixedPort: mixedPort)))
      as Map<String, Object?>;
}

class _FakeMigrationStore implements MigrationStore {
  final Map<String, Object?>? configMap;
  final Map<String, Object?>? clashConfigMap;
  bool configSaveResult;
  final bool available;
  final List<String> events = [];
  Error? restoreError;
  Error? clearError;

  int version;
  int upgradeVersion;
  Config? savedConfig;
  MigrationData? restoredData;
  bool didClearClashConfig = false;

  _FakeMigrationStore({
    required this.configMap,
    required this.version,
    this.upgradeVersion = Migration.upgradeVersion,
    this.clashConfigMap,
    this.configSaveResult = true,
    this.available = true,
  });

  @override
  Future<bool> get isAvailable async {
    events.add('isAvailable');
    return available;
  }

  @override
  Future<void> clearClashConfig() async {
    events.add('clearClashConfig');
    if (clearError case final error?) throw error;
    didClearClashConfig = true;
  }

  @override
  Future<Map<String, Object?>?> getClashConfigMap() async {
    events.add('getClashConfigMap');
    return clashConfigMap;
  }

  @override
  Future<Map<String, Object?>?> getConfigMap() async {
    events.add('getConfigMap');
    return configMap;
  }

  @override
  Future<int> getVersion() async {
    events.add('getVersion');
    return version;
  }

  @override
  Future<void> restore(MigrationData data) async {
    events.add('restore');
    if (restoreError case final error?) {
      throw error;
    }
    restoredData = data;
    profiles = profiles || data.profiles.isNotEmpty;
  }

  @override
  Future<bool> saveConfig(Config config) async {
    events.add('saveConfig');
    savedConfig = config;
    return configSaveResult;
  }

  @override
  Future<void> setVersion(int version) async {
    events.add('setVersion');
    this.version = version;
  }

  @override
  Future<int> getUpgradeVersion() async => upgradeVersion;

  @override
  Future<void> setUpgradeVersion(int version) async {
    events.add('setUpgradeVersion');
    upgradeVersion = version;
  }

  bool profiles = false;
  bool legacyImported = false;

  @override
  Future<bool> hasProfiles() async => profiles;

  @override
  Future<bool> getLegacyImported() async => legacyImported;

  @override
  Future<void> setLegacyImported() async {
    events.add('setLegacyImported');
    legacyImported = true;
  }
}

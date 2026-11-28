import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/boot_record.dart';
import 'package:fl_clash/common/constant.dart';
import 'package:fl_clash/common/preferences.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/preferences.dart';

const _sharedState = SharedState(
  stopTip: 'stop',
  startTip: 'start',
  localNetworkTip: 'local',
  currentProfileName: 'profile',
  stopText: 'stopped',
  showStopAction: false,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences store;

  setUp(() async {
    await mockPreferences();
    store = await SharedPreferences.getInstance();
  });

  group('applied config md5', () {
    test('round-trips a written md5 and forgets a cleared one', () async {
      expect(await preferences.getAppliedConfigMd5(), isNull);

      await preferences.saveAppliedConfigMd5('abc');
      expect(await preferences.getAppliedConfigMd5(), 'abc');

      await preferences.saveAppliedConfigMd5(null);
      expect(store.containsKey(appliedConfigMd5Key), isFalse);
    });
  });

  group('version', () {
    test('defaults to 0 when never written', () async {
      expect(await preferences.getVersion(), 0);
    });

    test('round-trips a written version', () async {
      await preferences.setVersion(7);

      expect(await preferences.getVersion(), 7);
    });
  });

  group('config', () {
    test('getConfigMap returns null when nothing is stored', () async {
      expect(await preferences.getConfigMap(), isNull);
    });

    test('saveConfig then getConfigMap round-trips the model', () async {
      const config = Config(
        themeProps: defaultThemeProps,
        currentProfileId: 42,
        excludeSSIDs: ['home'],
      );

      expect(await preferences.saveConfig(config), isTrue);
      final restored = Config.fromJson((await preferences.getConfigMap())!);

      expect(restored.currentProfileId, 42);
      expect(restored.excludeSSIDs, ['home']);
    });

    test('saveConfig preserves the Zapret dashboard widget', () async {
      const config = Config(
        themeProps: defaultThemeProps,
        currentProfileId: 42,
        appSettingProps: AppSettingProps(
          dashboardWidgets: [
            DashboardWidget.currentOutbound,
            DashboardWidget.zapret,
          ],
          dashboardWidgetsChosen: true,
          openLogs: true,
          acceptedDisclaimerVersion: disclaimerVersion,
        ),
      );

      expect(await preferences.saveConfig(config), isTrue);
      final saved = (await preferences.getConfigMap())!;
      final app = saved['appSettingProps'] as Map<String, Object?>;
      expect(app['dashboardWidgets'], ['currentOutbound', 'zapret']);
      expect(Config.strictFromJson(saved), config);
    });

    test('every saved dashboard widget and setting enum survives persistence', () async {
      final app = const AppSettingProps().copyWith(
        dashboardWidgets: DashboardWidget.values,
        dashboardWidgetsChosen: true,
      );
      final base = Config(themeProps: defaultThemeProps, appSettingProps: app);
      final cases = <Config>[
        base,
        for (final value in RequestFeed.values)
          base.copyWith.appSettingProps(requestFeed: value),
        for (final value in TabAnimation.values)
          base.copyWith.appSettingProps(tabAnimation: value),
        for (final value in EditorFontSize.values)
          base.copyWith.appSettingProps(editorFontSize: value),
        for (final value in AccessControlMode.values)
          base.copyWith.vpnProps.accessControlProps(mode: value),
        for (final value in AccessSortType.values)
          base.copyWith.vpnProps.accessControlProps(sort: value),
        for (final value in ProxiesType.values)
          base.copyWith.proxiesStyleProps(type: value),
        for (final value in ProxiesSortType.values)
          base.copyWith.proxiesStyleProps(sortType: value),
        for (final value in ProxiesLayout.values)
          base.copyWith.proxiesStyleProps(layout: value),
        for (final value in ProxiesIconStyle.values)
          base.copyWith.proxiesStyleProps(iconStyle: value),
        for (final value in ProxyCardType.values)
          base.copyWith.proxiesStyleProps(cardType: value),
        for (final value in Mode.values)
          base.copyWith.patchClashConfig(mode: value),
        for (final value in LogLevel.values)
          base.copyWith.patchClashConfig(logLevel: value),
        for (final value in FindProcessMode.values)
          base.copyWith.patchClashConfig(findProcessMode: value),
        for (final value in InterfaceNameMode.values)
          base.copyWith.patchClashConfig(interfaceNameMode: value),
        for (final value in GeodataLoader.values)
          base.copyWith.patchClashConfig(geodataLoader: value),
        for (final value in TunStack.values)
          base.copyWith.patchClashConfig.tun(stack: value),
        base.copyWith.patchClashConfig(
          tunOverrideKeys: TunOverrideKey.values.toSet(),
        ),
      ];
      for (final config in cases) {
        expect(await preferences.saveConfig(config), isTrue);
        expect(Config.strictFromJson((await preferences.getConfigMap())!), config);
      }
    });

    test('corrupted settings JSON restores last successful configuration', () async {
      const config = Config(themeProps: defaultThemeProps, currentProfileId: 42);
      expect(await preferences.saveConfig(config), isTrue);
      await store.setString(configKey, 'broken');
      expect(Config.strictFromJson((await preferences.getConfigMap())!), config);
    });

    test('valid JSON with corrupt model fields restores last known good', () async {
      const config = Config(themeProps: defaultThemeProps, currentProfileId: 42);
      expect(await preferences.saveConfig(config), isTrue);
      final invalid = Map<String, Object?>.from((await preferences.getConfigMap())!);
      invalid['themeProps'] = 123;
      await store.setString(configKey, jsonEncode(invalid));
      expect(Config.strictFromJson((await preferences.getConfigMap())!), config);
    });

    test('a partially valid legacy map remains available for salvage', () async {
      final raw = {'currentProfileId': 42, 'themeProps': 123};
      await store.setString(configKey, jsonEncode(raw));
      expect(await preferences.getConfigMap(), raw);
    });

    test('missing primary settings recover from an existing backup', () async {
      const config = Config(themeProps: defaultThemeProps, currentProfileId: 42);
      expect(await preferences.saveConfig(config), isTrue);
      await store.remove(configKey);
      expect(Config.strictFromJson((await preferences.getConfigMap())!), config);
    });

    test('independent recovery survives loss of both preferences keys', () async {
      final folder = await Directory.systemTemp.createTemp('flclashz-settings-');
      final file = File('${folder.path}${Platform.pathSeparator}backup.json');
      preferences.recoveryFileOverride = () async => file;
      try {
        const config = Config(themeProps: defaultThemeProps, currentProfileId: 42);
        expect(await preferences.saveConfig(config), isTrue);
        await store.setString(configKey, '{broken');
        await store.setString('config.lastGood.v1', '{broken');
        expect(Config.strictFromJson((await preferences.getConfigMap())!), config);
        await preferences.clearPreferences();
        expect(await file.exists(), isFalse);
        expect(await preferences.getConfigMap(), isNull);
      } finally {
        preferences.recoveryFileOverride = () async => null;
        await folder.delete(recursive: true);
      }
    });

    test('compatible saves preserve unknown model fields and explicit removals', () async {
      await preferences.setVersion(1);
      final old = const Config(themeProps: defaultThemeProps).copyWith.patchClashConfig(
        hosts: {'remove.example': '127.0.0.1'},
      );
      final raw = jsonDecode(jsonEncode(old)) as Map<String, Object?>;
      raw['futureSetting'] = {'enabled': false, 'value': 0};
      raw['dav'] = {'password': 'retired'};
      raw['davProps'] = {'password': 'retired'};
      (raw['appSettingProps'] as Map)['restoreStrategy'] = 'override';
      (raw['appSettingProps'] as Map)['recoveryStrategy'] = 'compatible';
      (raw['appSettingProps'] as Map)['futureOption'] = [];
      (raw['patchClashConfig'] as Map)['future-tunable'] = 'keep';
      await store.setString(configKey, jsonEncode(raw));
      final next = old.copyWith.patchClashConfig(hosts: {});
      expect(await preferences.saveConfig(next), isTrue);
      final saved = (await preferences.getConfigMap())!;
      expect(saved['futureSetting'], raw['futureSetting']);
      expect(saved.containsKey('dav'), isFalse);
      expect(saved.containsKey('davProps'), isFalse);
      expect((saved['appSettingProps'] as Map).containsKey('restoreStrategy'), isFalse);
      expect((saved['appSettingProps'] as Map).containsKey('recoveryStrategy'), isFalse);
      expect((saved['appSettingProps'] as Map)['futureOption'], isEmpty);
      expect((saved['patchClashConfig'] as Map)['future-tunable'], 'keep');
      expect((saved['patchClashConfig'] as Map)['hosts'], isEmpty);
      expect(Config.strictFromJson(saved), next);
      expect(await preferences.saveConfig(next), isTrue);
      expect(await preferences.getConfigMap(), saved);
    });

    test('getConfigMap returns null for malformed JSON', () async {
      await store.setString(configKey, 'not-json');

      expect(await preferences.getConfigMap(), isNull);
    });

    test('getConfigMap returns null when the payload is not a map', () async {
      await store.setString(configKey, '123');

      expect(await preferences.getConfigMap(), isNull);
    });
  });

  group('clash config', () {
    test('getClashConfigMap returns null when nothing is stored', () async {
      expect(await preferences.getClashConfigMap(), isNull);
    });

    test('getClashConfigMap decodes a stored map', () async {
      await store.setString(clashConfigKey, json.encode({'mode': 'rule'}));

      expect(await preferences.getClashConfigMap(), {'mode': 'rule'});
    });

    test('getClashConfigMap returns null for malformed JSON', () async {
      await store.setString(clashConfigKey, '{oops');

      expect(await preferences.getClashConfigMap(), isNull);
    });

    test('clearClashConfig removes only the clash config entry', () async {
      await store.setString(clashConfigKey, json.encode({'mode': 'rule'}));
      await preferences.setVersion(3);

      await preferences.clearClashConfig();

      expect(await preferences.getClashConfigMap(), isNull);
      expect(await preferences.getVersion(), 3);
    });
  });

  test('saveShareState writes the encoded shared state', () async {
    await preferences.saveShareState(_sharedState);

    final raw = store.getString('sharedState');
    expect(raw, isNotNull);
    expect(
      SharedState.fromJson(json.decode(raw!) as Map<String, Object?>),
      _sharedState,
    );
  });

  test('clearPreferences empties every stored key', () async {
    await preferences.setVersion(9);
    await preferences.saveConfig(const Config(themeProps: defaultThemeProps));

    await preferences.clearPreferences();

    expect(await preferences.getVersion(), 0);
    expect(await preferences.getConfigMap(), isNull);
  });

  test('blocked independent backup prevents primary settings reset', () async {
    final folder = await Directory.systemTemp.createTemp('flclashz-reset-');
    final file = File('${folder.path}${Platform.pathSeparator}backup.json');
    preferences.recoveryFileOverride = () async => file;
    try {
      const config = Config(themeProps: defaultThemeProps, currentProfileId: 42);
      expect(await preferences.saveConfig(config), isTrue);
      final saved = await file.rename('${file.path}.saved');
      final obstruction = await Directory(file.path).create();
      await expectLater(preferences.clearPreferences(), throwsA(isA<FileSystemException>()));
      expect(Config.strictFromJson((await preferences.getConfigMap())!), config);
      await obstruction.delete();
      await saved.rename(file.path);
      await preferences.clearPreferences();
      expect(await file.exists(), isFalse);
      expect(await preferences.getConfigMap(), isNull);
    } finally {
      preferences.recoveryFileOverride = () async => null;
      await folder.delete(recursive: true);
    }
  });

  test('isInit resolves true once shared preferences are available', () async {
    expect(await preferences.isInit, isTrue);
  });

  group('boot record', () {
    test('getBootRecord returns null when nothing is stored', () async {
      expect(await preferences.getBootRecord(), isNull);
    });

    test('saveBootRecord then getBootRecord round-trips the record', () async {
      const record = BootRecord(
        stage: BootStage.starting,
        profileId: 5,
        startedAt: 111,
        failureCount: 1,
        lastFailedProfileId: 4,
        handledExitAt: 99,
      );

      await preferences.saveBootRecord(record);

      expect(await preferences.getBootRecord(), record);
    });

    test('getBootRecord survives a corrupt entry', () async {
      await store.setString(bootRecordKey, 'not json');

      expect(await preferences.getBootRecord(), isNull);
    });
  });
}

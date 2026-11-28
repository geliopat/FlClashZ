import 'dart:io';

import 'package:drift/native.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/database/database.dart' as db;
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/providers/core.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/state.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/widgets.dart' show Locale;
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:riverpod/riverpod.dart';

class _MockCoreHandlerInterface extends Mock implements CoreHandlerInterface {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late db.Database testDatabase;
  late ProviderContainer container;
  late Map<String, int> requests;

  setUpAll(() => AppLocalizations.load(const Locale('en')));

  setUp(() {
    testDatabase = db.Database(NativeDatabase.memory());
    db.database = testDatabase;
    requests = {};
    final core = _MockCoreHandlerInterface();
    when(() => core.updateGeoData(any())).thenAnswer((invocation) async {
      final name = invocation.positionalArguments.single as String;
      final count = requests[name] = (requests[name] ?? 0) + 1;
      return count == 1 ? '' : 'geo update already in progress';
    });
    container = ProviderContainer(
      overrides: [
        coreHandlerProvider.overrideWithValue(CoreController.scoped(core)),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await testDatabase.close();
  });

  test('Windows does not credit an older profile with a Geo completion', () async {
    if (!Platform.isWindows) return;
    final core = _MockCoreHandlerInterface();
    final calls = <String, int>{};
    when(core.getExternalProviders).thenAnswer((_) async => []);
    when(() => core.updateGeoData(any())).thenAnswer((invocation) async {
      final name = invocation.positionalArguments.single as String;
      calls[name] = (calls[name] ?? 0) + 1;
      return '';
    });
    final scoped = ProviderContainer(overrides: [
      coreHandlerProvider.overrideWithValue(CoreController.scoped(core)),
      currentProfileIdProvider.overrideWithBuild((_, _) => 1),
      patchClashConfigProvider.overrideWithBuild(
        (_, _) => const PatchClashConfig(geoAutoUpdate: true),
      ),
    ]);
    addTearDown(scoped.dispose);
    scoped.read(coreStatusProvider.notifier).value = CoreStatus.connected;
    final action = scoped.read(resourcesActionProvider.notifier);
    final geo = scoped.read(geoResourceActionProvider.notifier);
    action.profileAdded(1);
    await action.profileApplied(1);
    geo.handleCoreUpdate('MMDB', true, false, null);
    expect(calls['MMDB'], 1);

    await action.profileApplied(null);
    scoped.read(currentProfileIdProvider.notifier).value = 2;
    action.profileAdded(2);
    await action.profileApplied(2);
    geo.handleCoreUpdate('MMDB', false, true, null);
    await action.profileApplied(2);
    expect(calls['MMDB'], 2);

    geo.handleCoreUpdate('MMDB', true, false, null);
    geo.handleCoreUpdate('MMDB', false, true, null);
    await action.profileApplied(2);
    expect(calls['MMDB'], 2);
  });

  test(
    'an update all that overlaps one running skips what that one runs',
    () async {
      final action = container.read(resourcesActionProvider.notifier);

      final failures = await Future.wait([
        action.updateAll(),
        action.updateAll(),
      ]);

      expect(failures.expand((items) => items), isEmpty);
      expect(requests, {
        for (final geoResource in GeoResource.values) geoResource.name: 1,
      });
    },
  );
}

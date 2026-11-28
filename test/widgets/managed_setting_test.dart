import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/context_menu.dart';
import 'package:fl_clash/ui/list.dart' as app_ui;
import 'package:fl_clash/views/config/general.dart';
import 'package:fl_clash/views/proxies/setting.dart';
import 'package:fl_clash/views/theme.dart';
import 'package:fl_clash/widgets/managed_setting.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart' show Override;
import 'package:mocktail/mocktail.dart';

import '../helpers/test_app.dart';
import '../helpers/test_profiles.dart';

/// Off the global Core, whose transport another file in a bundle may leave open.
class _NoProfileBaseCore extends Mock implements CoreHandlerInterface {
  @override
  Future<ProfileBase> getProfileBase(String path) =>
      Future.error(StateError('no Core in this test'));
}

void main() {
  test('source captions distinguish unknown, absent, zero, false and inherited', () {
    const values = <String, Object>{'clash.keep-alive-idle': 0, 'clash.tcp-concurrent': false};
    expect(yamlSourceCaption(values, 'clash.keep-alive-idle', owned: true, russian: true), 'Из подписки: 0');
    expect(yamlSourceCaption(values, 'clash.tcp-concurrent', owned: true, russian: false), 'From subscription: disabled');
    expect(yamlSourceCaption(values, 'clash.keep-alive-idle', owned: false, russian: true), 'Из подписки');
    expect(yamlSourceCaption(values, 'clash.ipv6', owned: false, russian: false), 'Default');
    expect(yamlSourceCaption(null, 'clash.ipv6', owned: false, russian: false), isNull);
  });
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Windows setting shows updated subscription value under its title', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    globalState.container = container;
    final keep = container.listen(appSettingProvider, (_, _) {});
    addTearDown(keep.close);
    container.read(appSettingProvider.notifier).update((s) => s.copyWith(
      ownedSettings: {'clash.keep-alive-idle'},
    ));
    container.read(managedClashKeysProvider.notifier).set({'clash.keep-alive-idle'});
    container.read(yamlSettingReferencesProvider.notifier).set({'clash.keep-alive-idle': 60});
    await tester.pumpWidget(UncontrolledProviderScope(container: container,
      child: TestApp(theme: ThemeData(platform: TargetPlatform.windows),
        locale: const Locale('en'), includeNavigatorKey: false,
        child: const Scaffold(body: ManagedSetting(settingKey: 'clash.keep-alive-idle',
          child: app_ui.ListItem(title: Text('Keep-alive idle'), trailing: Text('15')))))),
    );
    expect(find.text('From subscription: 60'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    container.read(yamlSettingReferencesProvider.notifier).set({'clash.keep-alive-idle': 90});
    await tester.pump();
    expect(find.text('From subscription: 90'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  });

  late ProviderContainer container;
  ProviderContainer? activeContainer;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  void testManagedWidgets(
    String description,
    Future<void> Function(WidgetTester) callback,
  ) {
    testWidgets(description, (tester) async {
      try {
        await callback(tester);
      } finally {
        try {
          await tester.pumpWidget(const SizedBox.shrink());
        } finally {
          activeContainer?.dispose();
          activeContainer = null;
        }
      }
    });
  }

  Override noCore() => coreHandlerProvider.overrideWithValue(
    CoreController.scoped(_NoProfileBaseCore()),
  );

  const profile = Profile(
    id: 1,
    label: 'Plan',
    type: ProfileType.url,
    autoUpdateDuration: Duration.zero,
    providerHeaders: {'flclashx-settings': 'minimize'},
  );

  Future<void> pumpGeneral(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    container = ProviderContainer(
      overrides: [
        profilesProvider.overrideWith(() => TestProfiles([profile])),
        currentProfileIdProvider.overrideWithBuild((_, _) => profile.id),
        noCore(),
      ],
    );
    activeContainer = container;
    globalState.container = container;
    container.listen(appSettingProvider, (_, _) {});
    container.listen(profileHeadersActionProvider, (_, _) {});
    container
        .read(viewSizeProvider.notifier)
        .update((_) => const Size(1000, 3000));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: GeneralView()),
      ),
    );
    await tester.pumpAndSettle();
  }

  AppSettingProps setting() => container.read(appSettingProvider);

  Finder row() => find.widgetWithText(ListTile, 'Minimize on exit');

  testManagedWidgets('a managed row is dimmed and asks before it is taken over', (
    tester,
  ) async {
    await pumpGeneral(tester);
    expect(setting().minimizeOnExit, isTrue);
    expect(
      find.ancestor(of: row(), matching: find.byType(Opacity)),
      findsOneWidget,
    );

    await tester.tap(row());
    await tester.pumpAndSettle();
    expect(find.text('Managed by your provider'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(setting().minimizeOnExit, isTrue);
    expect(setting().ownedSettings, isEmpty);

    await tester.tap(row());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Change'));
    await tester.pumpAndSettle();

    expect(setting().ownedSettings, {'app.minimizeOnExit'});
    expect(setting().minimizeOnExit, isFalse);
    expect(
      find.ancestor(of: row(), matching: find.byType(Opacity)),
      findsNothing,
    );
  });

  testManagedWidgets('Enter on a locked row asks before a takeover', (tester) async {
    await pumpGeneral(tester);
    final detector = find
        .ancestor(of: row(), matching: find.byType(FocusableActionDetector))
        .first;
    final inside = find
        .descendant(of: detector, matching: find.byType(GestureDetector))
        .first;
    Focus.of(tester.element(inside)).requestFocus();
    await tester.pump();

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    expect(find.text('Managed by your provider'), findsOneWidget);
    expect(setting().minimizeOnExit, isTrue);
    expect(setting().ownedSettings, isEmpty);
  });

  testManagedWidgets('a locked row takes focus itself, never its control', (
    tester,
  ) async {
    await pumpGeneral(tester);
    final nodes = <FocusNode>[];
    void collect(Element element) {
      if (element.widget is Focus) {
        element.visitChildren((child) => nodes.add(Focus.of(child)));
      }
      element.visitChildren(collect);
    }

    tester.element(row()).visitChildren(collect);
    expect(nodes, isNotEmpty);
    expect(nodes.where((node) => node.canRequestFocus), isEmpty);

    final detector = find
        .ancestor(of: row(), matching: find.byType(FocusableActionDetector))
        .first;
    final inside = find
        .descendant(of: detector, matching: find.byType(GestureDetector))
        .first;
    expect(Focus.of(tester.element(inside)).canRequestFocus, isTrue);
  });

  testManagedWidgets('a taken-over row is handed back from its context menu', (
    tester,
  ) async {
    await pumpGeneral(tester);
    container
        .read(appSettingProvider.notifier)
        .update(
          (state) => state.copyWith(
            ownedSettings: {'app.minimizeOnExit'},
            minimizeOnExit: false,
          ),
        );
    await tester.pumpAndSettle();

    await tester.tap(row(), buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hand back to provider'));
    await tester.pumpAndSettle();

    expect(setting().ownedSettings, isEmpty);
    expect(setting().minimizeOnExit, isTrue);
  });

  testManagedWidgets('proxy options restore the provider from the row context menu', (
    tester,
  ) async {
    final styled = const Profile(
      id: 5,
      label: 'Provider',
      type: ProfileType.url,
      autoUpdateDuration: Duration.zero,
      providerHeaders: {'flclashz-view': 'proxies.type:list;proxies.layout:tight'},
    );
    container = ProviderContainer(
      overrides: [
        profilesProvider.overrideWith(() => TestProfiles([styled])),
        currentProfileIdProvider.overrideWithBuild((_, _) => styled.id),
        noCore(),
      ],
    );
    activeContainer = container;
    globalState.container = container;
    container.listen(profileHeadersActionProvider, (_, _) {});
    container.read(appSettingProvider.notifier).update((state) =>
        state.copyWith(ownedSettings: {'view.proxies.layout'}));
    container.read(proxiesStyleSettingProvider.notifier).update((state) =>
        state.copyWith(layout: ProxiesLayout.standard));
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const TestApp(child: ProxiesSetting()),
    ));
    await tester.pumpAndSettle();

    final layout = find.widgetWithText(ListTile, 'Layout');
    expect(layout, findsOneWidget);
    expect(container.read(settingReleasableProvider('view.proxies.layout')), isTrue);
    final value = find.descendant(
      of: layout,
      matching: find.text('Standard'),
    );
    expect(value, findsOneWidget);
    await tester.tap(value, buttons: kSecondaryButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hand back to provider'));
    await tester.pumpAndSettle();
    expect(container.read(proxiesStyleSettingProvider).layout, ProxiesLayout.tight);
    expect(container.read(settingLockedProvider('view.proxies.layout')), isTrue);
    expect(setting().ownedSettings, isEmpty);
  });

  testManagedWidgets('one row in diagnostics hands every setting back', (
    tester,
  ) async {
    await pumpGeneral(tester);
    container
        .read(appSettingProvider.notifier)
        .update(
          (state) => state.copyWith(
            ownedSettings: {'app.minimizeOnExit', 'clash.allow-lan'},
            minimizeOnExit: false,
          ),
        );
    await tester.pumpAndSettle();

    final handBack = find.text('Hand settings back to provider');
    // A built list item can still be outside the visible viewport.
    // Scroll until its center actually receives pointer events.
    await tester.scrollUntilVisible(
      handBack.hitTestable(),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
    expect(handBack.hitTestable(), findsOneWidget);
    await tester.tap(handBack.hitTestable());
    await tester.pumpAndSettle();
    await tester.tap(find.text('Confirm'));
    await tester.pumpAndSettle();

    expect(setting().ownedSettings, isEmpty);
    expect(setting().minimizeOnExit, isTrue);
  });

  Future<void> pumpTheme(WidgetTester tester, String view) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final styled = Profile(
      id: 2,
      label: 'Plan',
      type: ProfileType.url,
      autoUpdateDuration: Duration.zero,
      providerHeaders: {'flclashx-view': view},
    );
    container = ProviderContainer(
      overrides: [
        profilesProvider.overrideWith(() => TestProfiles([styled])),
        currentProfileIdProvider.overrideWithBuild((_, _) => styled.id),
        noCore(),
      ],
    );
    activeContainer = container;
    globalState.container = container;
    container
        .read(viewSizeProvider.notifier)
        .update((_) => const Size(1000, 3000));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: ThemeView()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testManagedWidgets('the theme key dims the appearance block', (tester) async {
    await pumpTheme(tester, 'app.theme:dark');

    expect(
      find.ancestor(
        of: find.text('Appearance'),
        matching: find.byType(Opacity),
      ),
      findsOneWidget,
    );
    expect(
      find.ancestor(
        of: find.text('Theme mode'),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });

  testManagedWidgets('the hint shows only on a page with a managed row', (
    tester,
  ) async {
    await pumpGeneral(tester);
    expect(
      find.text(
        'Dimmed settings with a closed lock are set by your subscription. '
        'Tap one to change it yourself.',
      ),
      findsOneWidget,
    );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: ProxiesSetting()),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(ManagedSettingsHint), findsOneWidget);
    expect(find.textContaining('Dimmed settings'), findsNothing);
  });

  Finder lock({required bool locked}) => find.byWidgetPredicate(
    (widget) => widget is SettingLock && widget.locked == locked,
  );

  testManagedWidgets(
    'a provider row shows a closed lock, a taken-over one an open lock',
    (tester) async {
      await pumpGeneral(tester);
      expect(
        find.descendant(of: row(), matching: lock(locked: true)),
        findsOneWidget,
      );
      expect(lock(locked: false), findsNothing);
      expect(find.textContaining('An open lock marks'), findsNothing);

      container
          .read(appSettingProvider.notifier)
          .update(
            (state) => state.copyWith(
              ownedSettings: {'app.minimizeOnExit', 'clash.allow-lan'},
            ),
          );
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: row(), matching: lock(locked: true)),
        findsNothing,
      );
      expect(
        find.descendant(of: row(), matching: lock(locked: false)),
        findsOneWidget,
      );
      expect(lock(locked: false), findsNWidgets(2));
      expect(find.textContaining('An open lock marks'), findsOneWidget);
    },
  );

  testManagedWidgets('a locked theme block shows its lock once, not on nested rows', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1000, 3000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    const colored = Profile(
      id: 3,
      label: 'Plan',
      type: ProfileType.url,
      autoUpdateDuration: Duration.zero,
      providerHeaders: {'flclashx-view': 'app.color:#FF5733'},
    );
    container = ProviderContainer(
      overrides: [
        profilesProvider.overrideWith(() => TestProfiles([colored])),
        currentProfileIdProvider.overrideWithBuild((_, _) => colored.id),
        noCore(),
      ],
    );
    activeContainer = container;
    globalState.container = container;
    container
        .read(viewSizeProvider.notifier)
        .update((_) => const Size(1000, 3000));
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(child: ThemeView()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingLock), findsOneWidget);
  });

  testManagedWidgets('a card that opts out keeps its menu but shows no lock', (
    tester,
  ) async {
    container = ProviderContainer(
      overrides: [
        profilesProvider.overrideWith(() => TestProfiles([profile])),
        currentProfileIdProvider.overrideWithBuild((_, _) => profile.id),
        noCore(),
      ],
    );
    activeContainer = container;
    globalState.container = container;
    container
        .read(appSettingProvider.notifier)
        .update(
          (state) => state.copyWith(ownedSettings: {'app.minimizeOnExit'}),
        );
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const TestApp(
          child: ManagedSetting(
            settingKey: 'app.minimizeOnExit',
            showsLock: false,
            child: Text('Card'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(SettingLock), findsNothing);
    expect(
      find.ancestor(
        of: find.text('Card'),
        matching: find.byType(ContextMenuRegion),
      ),
      findsOneWidget,
    );
  });
}

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/views/proxies/list.dart';
import 'package:fl_clash/views/chain_health.dart';
import 'package:fl_clash/views/engine_diagnostics.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'setting.dart';
import 'tab.dart';

class ProxiesView extends ConsumerStatefulWidget {
  const ProxiesView({super.key, this.picker = false, this.platform});

  /// Leaves the bar only its search and delay test, for picking a proxy from a
  /// sheet.
  final bool picker;

  /// The host's platform when null; Android pulls the page down to test.
  final SupportPlatform? platform;

  @override
  ConsumerState<ProxiesView> createState() => _ProxiesViewState();
}

class _ProxiesViewState extends ConsumerState<ProxiesView> {
  final GlobalKey<ProxiesTabViewState> _proxiesTabKey = GlobalKey();

  // The same instance on every build, so the bar changing with the current
  // group or its delay test leaves the page alone.
  late final _tabView = ProxiesTabView(key: _proxiesTabKey);
  bool _isTab = false;

  List<CommonPopupMenuItem> _buildMenuItems(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final group = ref.watch(proxiesTabControllerStateProvider.select((s) => s.currentGroupName));
    final speedReady = system.isWindows && !ref.watch(speedTestProvider.select((s) => s.busy)) &&
        ref.watch(coreStatusProvider) == CoreStatus.connected;
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final result = system.isWindows && group != null
        ? ref.watch(speedTestProvider.select((s) => s.results[group])) : null;
    String groupSpeed(double? rate, String error) =>
        rate != null ? '${rate.toStringAsFixed(1)} ${appLocalizations.forkSpeedMbps}'
            : error.isNotEmpty ? error : '—';
    return [
      if (system.isWindows && _isTab && group != null && !widget.picker) ...[
        CommonPopupMenuItem(glyph: AppGlyphs.speed,
          label: ru ? 'Скорость текущей группы' : 'Current group speed',
          subtitle: result == null ? null : '↓ ${groupSpeed(result.download, result.downloadError)} · ↑ ${groupSpeed(result.upload, result.uploadError)}',
          onPressed: speedReady ? () => ref.read(speedTestProvider.notifier).testGroup(group) : null),
        CommonPopupMenuItem(glyph: AppGlyphs.speed,
          label: ru ? 'Проверить серверы группы' : 'Test group members',
          onPressed: speedReady ? () => ref.read(speedTestProvider.notifier).testGroupMembers(group) : null),
      ],
      if (system.isWindows && !widget.picker) ...[
        CommonPopupMenuItem(
          glyph: AppGlyphs.latency,
          label: ru ? 'Проверка каскадов (Chain Health)' : 'Chain Health',
          onPressed: () => BaseNavigator.push<void>(
            context, ChainHealthView(groupName: _isTab ? group : null),
          ),
        ),
        CommonPopupMenuItem(
          glyph: AppGlyphs.cpu,
          label: ru ? 'Диагностика цепочек' : 'Chain diagnostics',
          onPressed: () => BaseNavigator.push<void>(
            context,
            const EngineDiagnosticsView(section: EngineDiagnosticsSection.chains),
          ),
        ),
      ],
      if (_isTab && !ref.watch(oneGroupProvider))
        CommonPopupMenuItem(
          glyph: AppGlyphs.locate,
          label: appLocalizations.scrollToSelected,
          onPressed: () => _proxiesTabKey.currentState?.scrollToGroupSelected(),
        ),
      CommonPopupMenuItem(
        glyph: AppGlyphs.sliders,
        label: appLocalizations.settings,
        onPressed: () {
          showSheet(
            context: context,
            builder: (_) {
              return CommonScaffold(
                body: const ProxiesSetting(),
                title: appLocalizations.settings,
              );
            },
          );
        },
      ),
    ];
  }

  IconButtonData? _buildPrimaryAction() {
    if (!_isTab || ref.watch(oneGroupProvider)) {
      return null;
    }
    final isDelayTesting = ref.watch(currentGroupDelayTestingProvider);
    return IconButtonData(
      glyph: AppGlyphs.latency,
      onPressed: () {
        _proxiesTabKey.currentState?.delayTestCurrentGroup();
      },
      tooltip: context.appLocalizations.delayTest,
      isLoading: isDelayTesting,
    );
  }

  IconButtonData _buildFoldAllAction() {
    final allUnfolded = ref.watch(
      proxiesListStateProvider.select(
        (state) =>
            state.groups.isNotEmpty &&
            state.groups.every(
              (group) => state.currentUnfoldSet.contains(group.name),
            ),
      ),
    );
    final appLocalizations = context.appLocalizations;
    return IconButtonData(
      glyph: allUnfolded ? AppGlyphs.foldAll : AppGlyphs.unfoldAll,
      tooltip: allUnfolded
          ? appLocalizations.foldAllGroups
          : appLocalizations.unfoldAllGroups,
      onPressed: () => ref
          .read(proxiesActionProvider.notifier)
          .setShownGroupsUnfolded(!allUnfolded),
    );
  }

  Widget _pullToTest(Widget body) {
    final platform = widget.platform ?? SupportPlatform.currentPlatform;
    if (widget.picker || platform != SupportPlatform.Android) {
      return body;
    }
    final appLocalizations = context.appLocalizations;
    return PullAction(
      labels: (
        pull: appLocalizations.pullToTestDelay,
        release: appLocalizations.releaseToTestDelay,
        running: null,
        done: null,
      ),
      onPull: () async {
        await ref.read(proxiesActionProvider.notifier).delayTestAllGroups();
        return true;
      },
      child: body,
    );
  }

  void _onSearch(String value) {
    ref.read(queryProvider(QueryTag.proxies).notifier).value = value;
  }

  @override
  void initState() {
    super.initState();
    ref.listenManual(
      proxiesStyleSettingProvider.select(
        (state) => state.type == ProxiesType.tab,
      ),
      (prev, next) {
        if (prev != next) {
          setState(() {
            _isTab = next;
          });
        }
      },
      fireImmediately: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final proxiesType = ref.watch(
      proxiesStyleSettingProvider.select((state) => state.type),
    );
    final isLoading = ref.watch(loadingProvider(LoadingTag.proxies));
    final picker = widget.picker;
    final oneGroup = ref.watch(oneGroupProvider);
    final primaryAction = _buildPrimaryAction();
    final mode = ref.watch(
      patchClashConfigProvider.select((state) => state.mode),
    );
    final isTestingAll = ref.watch(
      delayTestingGroupsProvider.select((state) => state.isNotEmpty),
    );
    final appLocalizations = context.appLocalizations;
    final speedBusy = system.isWindows && ref.watch(speedTestProvider.select((state) => state.busy));
    final speedAvailable = system.isWindows && ref.watch(coreStatusProvider) == CoreStatus.connected;
    final barActions = [
      if (!picker) ...[
        if (ref.watch(globalModeAllowedProvider))
          IconButtonData(
            glyph: mode == Mode.global ? AppGlyphs.globe : AppGlyphs.rules,
            tooltip:
                '${appLocalizations.outboundMode}: '
                '${mode == Mode.global ? appLocalizations.global : appLocalizations.rule}',
            onPressed: () => ref
                .read(setupActionProvider.notifier)
                .pickMode(mode == Mode.global ? Mode.rule : Mode.global),
          ),
        IconButtonData(
          glyph: AppGlyphs.latency,
          tooltip: appLocalizations.delayTestAll,
          isLoading: isTestingAll,
          onPressed: isTestingAll
              ? null
              : () => ref
                    .read(proxiesActionProvider.notifier)
                    .delayTestAllGroups(),
        ),
        if (system.isWindows)
          IconButtonData(
            glyph: AppGlyphs.speed,
            tooltip: appLocalizations.forkSpeedTestAll,
            isLoading: speedBusy,
            onPressed: speedBusy || !speedAvailable ? null : () =>
                ref.read(speedTestProvider.notifier).testAll(),
          ),
      ],
    ];
    return CommonScaffold(
      isLoading: isLoading,
      resizeToAvoidBottomInset: false,
      // The picker sheet keeps the bar it had, close last.
      primaryAction: picker ? primaryAction : null,
      groupActions: !picker,
      searchActions: [?primaryAction],
      iconActions: [
        ...barActions,
        if (!_isTab && !picker && !oneGroup) _buildFoldAllAction(),
      ],
      menuItems: picker ? const [] : _buildMenuItems(context),
      title: context.appLocalizations.proxies,
      searchState: AppBarSearchState(onSearch: _onSearch),
      body: _pullToTest(
        oneGroup
            ? const ProxiesOneGroupView()
            : switch (proxiesType) {
                ProxiesType.tab => _tabView,
                ProxiesType.list => const ProxiesListView(),
              },
      ),
    );
  }
}

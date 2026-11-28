import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/method.dart';
import 'package:fl_clash/features/features.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/providers/connection_statistics.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:flutter/foundation.dart' show listEquals;
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ConnectionsView extends ConsumerStatefulWidget {
  final ScrollController? scrollController;
  final List<CommonPopupMenuItem> titleMenuItems;
  final Widget? titleWidget;
  final Future<List<TrackerInfo>> Function()? connectionsReader;

  const ConnectionsView({
    super.key,
    this.scrollController,
    this.titleMenuItems = const [],
    this.titleWidget,
    @visibleForTesting this.connectionsReader,
  });

  @override
  ConsumerState<ConnectionsView> createState() => _ConnectionsViewState();
}

class _ConnectionsViewState extends ConsumerState<ConnectionsView>
    with
        WidgetsBindingObserver,
        ActivePollingMixin<ConnectionsView>,
        RouteMotionHoldMixin<ConnectionsView> {
  CoreController get _core => ref.read(coreHandlerProvider);

  final _listController = TrackerInfoListController();
  final _speedRanker = TrackerSpeedRanker();
  late final ScrollController _scrollController;
  var _loaded = false;
  var _unavailable = false;
  int _sampleEpoch = 0;
  ProviderSubscription<AsyncValue<ConnectionStatisticsSample?>>? _subscription;

  @override
  void initState() {
    super.initState();
    _scrollController =
        widget.scrollController ?? sheetScrollController(context);
  }

  @override
  bool get canPoll => widget.connectionsReader != null && super.canPoll;

  @override
  Duration get pollInterval => const Duration(seconds: 1);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncSharedFeed();
  }

  @override
  void didUpdateWidget(covariant ConnectionsView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.connectionsReader != widget.connectionsReader) {
      _syncSharedFeed();
      restartPolling();
    }
  }

  void _syncSharedFeed() {
    final active = widget.connectionsReader == null &&
        PageActivityScope.isActiveOf(context) &&
        TickerMode.valuesOf(context).enabled;
    if (!active) {
      _sampleEpoch++;
      _subscription?.close();
      _subscription = null;
      return;
    }
    _subscription ??= ref.listenManual(
      connectionStatisticsProvider,
      (_, next) {
        final data = next.asData;
        if (data == null && !next.hasError) return;
        final epoch = ++_sampleEpoch;
        scheduleMicrotask(() {
          if (!mounted || epoch != _sampleEpoch) return;
          final sample = data?.value;
          final connected = ref.read(coreStatusProvider) == CoreStatus.connected;
          final unavailable = sample == null && connected;
          if (_unavailable != unavailable) {
            setState(() => _unavailable = unavailable);
          }
          _showConnections(
            sample?.snapshot.connections ?? const <TrackerInfo>[],
            sampledAt: sample?.sampledAt,
            epoch: epoch,
          );
        });
      },
      fireImmediately: true,
    );
  }

  List<IconButtonData> _buildActions() {
    return [
      IconButtonData(
        glyph: AppGlyphs.clearAll,
        tooltip: context.appLocalizations.closeConnections,
        onPressed: () async {
          await _core.closeConnections();
          await _refreshConnections();
        },
      ),
    ];
  }

  @override
  Future<void> poll(PollGuard isCurrent) async {
    final trackerInfos = await _readConnections();
    if (!isCurrent()) {
      return;
    }
    _showConnections(trackerInfos);
  }

  Future<void> _refreshConnections() async {
    if (!mounted) return;
    if (widget.connectionsReader == null) {
      // Closing a connection invalidates the controller cache; ask the shared
      // feed to refresh so every consumer sees the same new sample.
      ref.invalidate(connectionStatisticsProvider);
      return;
    }
    final trackerInfos = await _readConnections();
    if (mounted) _showConnections(trackerInfos);
  }

  Future<List<TrackerInfo>?> _readConnections() async {
    try {
      return await widget.connectionsReader!();
    } catch (error) {
      commonPrint.log(
        'updateConnections error: $error',
        logLevel: coreFailureLogLevel(error),
      );
      return null;
    }
  }

  void _showConnections(
    List<TrackerInfo>? trackerInfos, {
    DateTime? sampledAt,
    int? epoch,
  }) {
    final readAt = sampledAt ?? DateTime.now();
    void apply() {
      if (!mounted || (epoch != null && epoch != _sampleEpoch)) return;
      _applyConnections(trackerInfos, readAt);
    }

    if (!_loaded) {
      setState(() => _loaded = true);
      apply();
      return;
    }
    updateWhenRouteSettled(apply);
  }

  void _applyConnections(List<TrackerInfo>? trackerInfos, DateTime readAt) {
    if (trackerInfos == null) {
      return;
    }
    final ranked = _speedRanker.rank(trackerInfos, readAt);
    if (!listEquals(_listController.value.trackerInfos, ranked)) {
      _listController.setTrackerInfos(ranked);
    }
  }

  Future<void> _handleBlockConnection(String id) async {
    await _core.closeConnection(id);
    await _refreshConnections();
  }

  @override
  void dispose() {
    _sampleEpoch++;
    _subscription?.close();
    _listController.dispose();
    if (widget.scrollController == null) {
      _scrollController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonScaffold(
      title: appLocalizations.liveConnections,
      titleMenuItems: widget.titleMenuItems,
      titleWidget: widget.titleWidget,
      onKeywordsUpdate: _listController.updateKeywords,
      searchState: AppBarSearchState(onSearch: _listController.search),
      iconActions: _buildActions(),
      body: ValueListenableBuilder<TrackerInfosState>(
        valueListenable: _listController,
        builder: (context, state, _) {
          final connections = state.list;
          Widget buildAction(TrackerInfo trackerInfo) {
            return _BlockConnectionButton(
              onPressed: () {
                _handleBlockConnection(trackerInfo.id);
              },
            );
          }

          return NullStatusSwitcher(
            isLoading: !_loaded,
            isEmpty: connections.isEmpty,
            isSearching: state.isSearching,
            nullStatus: NullStatus(
              label: _unavailable
                  ? appLocalizations.forkUnavailable
                  : appLocalizations.nullTip(appLocalizations.connections),
              illustration: NullStatusIllustration.connections,
            ),
            child: RecordTableFrame<TrackerInfo>(
              tableId: 'connections',
              items: connections,
              columnsOf: (width) => trackerInfoColumns(
                context,
                width: width,
                isLive: true,
                actionBuilder: buildAction,
              ),
              builder: (context, table, connections) => TrackerInfoAnimatedList(
                controller: _scrollController,
                padding: EdgeInsets.only(
                  top: context.contentTopPadding,
                  bottom: 16 + context.bottomInset,
                ),
                trackerInfos: connections,
                table: table,
                detailTitle: appLocalizations.details(
                  appLocalizations.connection,
                ),
                actionBuilder: buildAction,
              ),
            ),
          );
        },
      ),
    );
  }
}

// One per live row: an IconButton would add a theme animation to each.
class _BlockConnectionButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _BlockConnectionButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: context.appLocalizations.blockConnection,
      child: Semantics(
        button: true,
        child: InkWell(
          mouseCursor: clickableCursor,
          onTap: onPressed,
          customBorder: AppShape.circle,
          child: SizedBox.square(
            dimension: 28,
            child: Center(
              child: GlyphIcon(
                AppGlyphs.block,
                size: 16,
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

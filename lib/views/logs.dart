import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:flutter/services.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/title_tabs.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:super_sliver_list/super_sliver_list.dart';

class LogListController extends ValueNotifier<LogsState> {
  LogListController() : super(const LogsState());

  void search(String query) {
    value = value.copyWith(query: query);
  }

  void updateKeywords(List<String> keywords) {
    value = value.copyWith(keywords: keywords);
  }

  void setLogs(List<Log> logs) {
    if (identical(logs, value.logs)) {
      return;
    }
    value = value.copyWith(
      logs: value.autoScrollToEnd
          ? logs
          : retainTrimmedHead(value.logs, logs, pausedMaxLogsLength),
    );
  }

  void setAutoScrollToEnd(bool autoScrollToEnd) {
    value = value.copyWith(autoScrollToEnd: autoScrollToEnd);
  }

  void resumeAutoScrollToEnd(List<Log> logs) {
    value = value.copyWith(autoScrollToEnd: true, logs: logs);
  }
}

class LogsView extends ConsumerStatefulWidget {
  const LogsView({super.key});

  @override
  ConsumerState<LogsView> createState() => _LogsViewState();
}

class _LogsViewState extends ConsumerState<LogsView>
    with RouteMotionHoldMixin<LogsView> {
  final _listController = LogListController();
  bool _pageActive = true;
  bool? _sectionActive;
  LogLevel? _level;
  static const _levels = <LogLevel?>[null, LogLevel.info, LogLevel.warning, LogLevel.error, LogLevel.debug];

  List<Log> _visibleLogs(LogsState state) => _level == null
      ? state.list : state.list.where((log) => log.logLevel == _level).toList(growable: false);
  late final ScrollController _scrollController;
  late final _physics = FollowEndScrollPhysics(
    isFollowing: () => _listController.value.autoScrollToEnd,
  );

  @override
  void initState() {
    super.initState();
    _scrollController = sheetScrollController(
      context,
      initialScrollOffset: double.maxFinite,
    );
    _listController.setLogs(ref.read(logsProvider).list);
    ref.listenManual(logsProvider.select((state) => state.revision), (_, _) {
      if (_pageActive) updateLogsThrottler();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = PageActivityScope.isActiveOf(context);
    final resumed = active && !_pageActive;
    _pageActive = active;
    final section = SectionActivityScope.isActiveOf(context);
    final left = _sectionActive == true && !section;
    _sectionActive = section;
    if (left) _level = null;
    if (left) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _listController.resumeAutoScrollToEnd(ref.read(logsProvider).list);
      });
    }
    if (resumed) updateLogsThrottler();
  }

  List<IconButtonData> _buildActions() {
    if (!system.isWindows) {
      return [
        IconButtonData(
          glyph: AppGlyphs.export,
          tooltip: context.appLocalizations.exportLogs,
          onPressed: _handleExport,
        ),
      ];
    }
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    return [
      IconButtonData(
        glyph: AppGlyphs.openExternal,
        tooltip: context.appLocalizations.openLogsFolder,
        onPressed: () async => system.openDirectory(await fileLogger.directoryPath),
      ),
      IconButtonData(
        glyph: AppGlyphs.clearAll,
        tooltip: ru ? 'Очистить отображаемый журнал' : 'Clear displayed log',
        onPressed: () {
          final logs = ref.read(logsProvider.notifier);
          logs.clearVisible();
          _listController.resumeAutoScrollToEnd(ref.read(logsProvider).list);
        },
      ),
      IconButtonData(
        glyph: AppGlyphs.copy,
        tooltip: ru ? 'Копировать видимые записи' : 'Copy visible entries',
        onPressed: () async => Clipboard.setData(ClipboardData(
          text: _visibleLogs(_listController.value).reversed.map((log) => '[${log.dateTime}] [${log.logLevel.name.toUpperCase()}] ${log.payload}').join('\n'),
        )),
      ),
    ];
  }

  @override
  void dispose() {
    _listController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _handleExport() async {
    final appLocalizations = context.appLocalizations;
    final res = await globalState.safeRun<bool>(() async {
      return ref.read(logsProvider.notifier).exportLogs();
    }, title: appLocalizations.exportLogs);
    if (res != true) return;
    unawaited(
      dialogs.showAlert(
        title: appLocalizations.tip,
        message: TextSpan(text: appLocalizations.exportSuccess),
      ),
    );
  }

  void updateLogsThrottler() {
    throttler.call((FunctionTag.logs, this), () {
      if (!mounted || !_pageActive) {
        return;
      }
      updateWhenRouteSettled(
        () {
          if (mounted && _pageActive) _listController.setLogs(ref.read(logsProvider).list);
        },
      );
    }, duration: renderThrottleDuration);
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return CommonScaffold(
      iconActions: _buildActions(),
      onKeywordsUpdate: _listController.updateKeywords,
      searchState: AppBarSearchState(onSearch: _listController.search),
      title: '${appLocalizations.logs} Mihomo',
      titleWidget: system.isWindows ? PageTitleTabs(
        labels: [appLocalizations.forkAllEvents, appLocalizations.forkInfo,
          Localizations.localeOf(context).languageCode == 'ru' ? 'Предупреждения' : 'Warnings',
          appLocalizations.forkErrors, appLocalizations.forkDebug],
        selectedIndex: _levels.indexOf(_level),
        onSelected: (index) => setState(() => _level = _levels[index]),
      ) : null,
      body: ValueListenableBuilder<LogsState>(
        valueListenable: _listController,
        builder: (context, state, _) {
          final logs = _visibleLogs(state);
          return NullStatusSwitcher(
            isEmpty: logs.isEmpty,
            isSearching: state.isSearching,
            nullStatus: NullStatus(
              illustration: NullStatusIllustration.logs,
              label: appLocalizations.nullTip(appLocalizations.logs),
            ),
            child: Align(
              alignment: Alignment.topCenter,
              child: FloatingScrollbar(
                controller: _scrollController,
                hintBuilder: (fraction) {
                  final index = (fraction * (logs.length - 1)).round();
                  return logs[index].dateTime;
                },
                child: ScrollToEndBox(
                  onCancelToEnd: () {
                    _listController.setAutoScrollToEnd(false);
                  },
                  onResumeToEnd: () {
                    _listController.resumeAutoScrollToEnd(
                      ref.read(logsProvider).list,
                    );
                  },
                  controller: _scrollController,
                  enable: state.autoScrollToEnd,
                  child: SuperListView.separated(
                    physics: _physics,
                    reverse: true,
                    shrinkWrap: false,
                    controller: _scrollController,
                    padding: EdgeInsets.only(
                      top: context.contentTopPadding,
                      bottom: 16 + context.bottomInset,
                    ),
                    itemCount: logs.length,
                    extentEstimation: recordListExtentEstimation,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: recordListGap),
                    itemBuilder: (_, index) {
                      final log = logs[index];
                      return LogItem(
                        log: log,
                        onClick: (value) {
                          context.commonScaffoldState?.addKeyword(value);
                        },
                      );
                    },
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class LogItem extends StatelessWidget {
  final Log log;
  final Function(String)? onClick;

  const LogItem({super.key, required this.log, this.onClick});

  @override
  Widget build(BuildContext context) {
    final tone = switch (log.logLevel) {
      LogLevel.warning => RecordTone.warning,
      LogLevel.error => RecordTone.error,
      LogLevel.info || LogLevel.debug || LogLevel.silent => RecordTone.neutral,
    };
    final payload = LogPayload.parse(log.payload);
    return RecordListItem(
      onTap: () {},
      header: RecordHeader(
        children: [
          RecordTimestamp(log.dateTime),
          RecordLabel(
            label: log.logLevel.name,
            tone: tone,
            onPressed: () => onClick?.call(log.logLevel.name),
          ),
        ],
      ),
      body: _LogBody(payload: payload, errorColor: tone.accentColor(context)),
    );
  }
}

class _LogBody extends StatelessWidget {
  final LogPayload payload;
  final Color? errorColor;

  const _LogBody({required this.payload, this.errorColor});

  String get _sourceText => [
    payload.tag,
    if (payload.route case final route?) ...[route.source, route.sourceDetail],
  ].where((text) => text.isNotEmpty).join('  ·  ');

  @override
  Widget build(BuildContext context) {
    final styles = RecordTextStyles.of(context);
    final route = payload.route;
    if (route == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(payload.message, style: styles.primary),
          if (payload.tag.isNotEmpty)
            Text(payload.tag, style: styles.secondary),
        ],
      );
    }
    return SelectableText.rich(
      TextSpan(
        children: [
          TextSpan(text: route.destination, style: styles.title),
          if (route.error.isNotEmpty)
            TextSpan(
              text: '\n${route.error}',
              style: styles.secondary.copyWith(color: errorColor),
            ),
          const TextSpan(text: '\n'),
          if (route.rule.isNotEmpty) ...[
            TextSpan(text: route.rule, style: styles.secondary),
            TextSpan(text: ' \u2192 ', style: styles.secondary.toJetBrainsMono),
          ],
          TextSpan(
            text: route.proxy,
            style: AppTextStyle.footnote
                .of(context, emphasized: true)
                .copyWith(color: context.colorScheme.primary),
          ),
          TextSpan(text: '\n$_sourceText', style: styles.secondary),
        ],
      ),
    );
  }
}

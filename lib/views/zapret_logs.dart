import 'package:fl_clash/ui/icons/icons.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:collection';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart' show compute;

import 'package:fl_clash/core/desktop/helper_client.dart';
import 'package:fl_clash/common/common.dart';
import 'package:flutter/services.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:fl_clash/ui/title_tabs.dart';
import 'package:material_ui/material_ui.dart';

String _levelLabel(AppLocalizations l, String level) => switch (level) {
  'info' => l.forkInfo,
  'error' => l.error,
  'stderr' => l.forkStderr,
  'debug' => l.forkDebug,
  _ => level,
};

/// The legacy journal has free-text messages, not structured recovery outcomes.
bool isRecoveryJournalMessage(String message) {
  final text = message.toLowerCase();
  return text.contains('watchdog') || text.contains('restart') ||
      text.contains('recover');
}

typedef _JournalEntry = ({HelperZapretLog log, String component});

const journalViewLimit = 10000;

/// Local Mihomo crashes are not in the native Helper archive.
HelperZapretLog? parseLocalMihomoCrash(String line) {
  final match = RegExp(r'^\[([^\]]+)\] \[([^\]]+)\] \[Mihomo\] (.*)$').firstMatch(line);
  if (match == null) return null;
  final time = DateTime.tryParse(match.group(1)!);
  if (time == null) return null;
  return HelperZapretLog(time, match.group(2)!.toLowerCase(), match.group(3)!);
}

Future<List<_JournalEntry>> _localMihomoCrashes() async {
  await crashFileLogger.flush();
  final files = await Directory(await crashFileLogger.directoryPath)
      .list(followLinks: false)
      .where((entry) => entry is File &&
          RegExp(r'^Crashes_\d{4}-\d{2}-\d{2}(?:_\d+)?\.log$').hasMatch(p.basename(entry.path)))
      .cast<File>().toList();
  final dated = await Future.wait(files.map((file) async =>
      (file: file, modified: await file.lastModified())));
  dated.sort((a, b) => b.modified.compareTo(a.modified));
  final result = <_JournalEntry>[];
  for (final entry in dated) {
    final tail = Queue<_JournalEntry>();
    await for (final line in entry.file.openRead()
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())) {
      final log = parseLocalMihomoCrash(line);
      if (log == null) continue;
      tail.addLast((log: log, component: 'Mihomo'));
      if (tail.length > journalViewLimit) tail.removeFirst();
    }
    result.addAll(tail.toList().reversed);
    if (result.length >= journalViewLimit) break;
  }
  result.sort((a, b) => b.log.time.compareTo(a.log.time));
  return result.take(journalViewLimit).toList(growable: false);
}

typedef _ArchiveResult = ({List<_JournalEntry> entries, List<String> unavailable});

bool sameZapretLogs(List<HelperZapretLog> a, List<HelperZapretLog> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i].time != b[i].time || a[i].level != b[i].level ||
        a[i].message != b[i].message) {
      return false;
    }
  }
  return true;
}

List<_JournalEntry> _parseArchive(String archive) {
  final events = Queue<_JournalEntry>();
  for (final line in const LineSplitter().convert(archive)) {
    if (line.isEmpty) continue;
    try {
      final decoded = jsonDecode(line);
      final log = HelperZapretLog.fromJson(decoded);
      final component = decoded is Map
          ? decoded['component']?.toString() ?? 'Zapret'
          : 'Zapret';
      events.addLast((log: log, component: component));
      if (events.length > journalViewLimit) events.removeFirst();
    } catch (_) {
      // Keep complete entries when the last line is torn.
    }
  }
  return events.toList().reversed.toList(growable: false);
}

class ZapretLogsView extends StatefulWidget {
  const ZapretLogsView({super.key, this.journalOnly = false, this.crashOnly = false, this.recoveryOnly = false, this.embedded = false})
      : assert(!(journalOnly && crashOnly) && !(journalOnly && recoveryOnly) && !(crashOnly && recoveryOnly));

  final bool journalOnly;
  final bool crashOnly;
  final bool recoveryOnly;
  final bool embedded;

  @override
  State<ZapretLogsView> createState() => _ZapretLogsViewState();
}

class _ZapretLogsViewState extends State<ZapretLogsView>
    with WidgetsBindingObserver, ActivePollingMixin<ZapretLogsView> {
  late final int _tab = widget.recoveryOnly ? 3 : widget.journalOnly ? 2 : widget.crashOnly ? 1 : 0;
  static const _filters = ['all', 'info', 'error', 'stderr', 'debug'];
  bool _loading = false;
  bool _clearing = false;
  int _logGeneration = 0;
  bool? _sectionActive;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = SectionActivityScope.isActiveOf(context);
    if (_sectionActive == true && !active) {
      _filter = 'all';
      _query = '';
    }
    _sectionActive = active;
  }
  String _query = '';
  String _filter = 'all';
  String? _error;
  List<HelperZapretLog> _logs = const [];
  Future<_ArchiveResult>? _archive;

  @override
  Duration get pollInterval => _tab == 0
      ? const Duration(seconds: 2)
      : const Duration(seconds: 30);

  @override
  Future<void> poll(PollGuard isCurrent) async {
    if (_tab != 0) {
      if (isCurrent()) _reloadArchive();
      return;
    }
    if (_loading || _clearing || !isCurrent()) return;
    final generation = _logGeneration;
    _loading = true;
    try {
      final logs = await helperClient.zapretLogs();
      if (isCurrent() && _tab == 0 && generation == _logGeneration &&
          (_error != null || !sameZapretLogs(_logs, logs))) {
        setState(() { _logs = logs; _error = null; });
      }
    } catch (error) {
      if (isCurrent() && _tab == 0 && generation == _logGeneration && _error != error.toString()) {
        setState(() => _error = error.toString());
      }
    } finally {
      _loading = false;
    }
  }

  bool _readingArchive = false;

  void _reloadArchive() {
    if (!mounted || _readingArchive) return;
    _readingArchive = true;
    final future = _loadArchive();
    setState(() => _archive = future);
    // Observe the original future even if the user leaves the page before
    // FutureBuilder subscribes. Keep its error available for the UI.
    unawaited(future.then<void>((_) {}, onError: (Object _, StackTrace _) {})
        .whenComplete(() => _readingArchive = false));
  }

  Future<_ArchiveResult> _loadArchive() async {
    final entries = <_JournalEntry>[];
    final unavailable = <String>[];
    Future<void> read(String source, Future<List<_JournalEntry>> Function() load) async {
      try {
        entries.addAll(await load());
      } catch (_) {
        unavailable.add(source);
      }
    }
    await Future.wait([
      read('Helper / Zapret', () async =>
          compute(_parseArchive, await helperClient.zapretLogArchive())),
      if (widget.crashOnly) read('Mihomo', _localMihomoCrashes),
    ]);
    final relevant = widget.crashOnly
        ? entries.where(_isCrashEntry).toList()
        : entries;
    relevant.sort((a, b) => b.log.time.compareTo(a.log.time));
    return (entries: relevant.take(journalViewLimit).toList(growable: false),
        unavailable: unavailable);
  }

  bool _isCrashEntry(_JournalEntry entry) =>
      entry.component == 'Mihomo' || entry.log.level == 'error' ||
      entry.log.message.toLowerCase().contains('watchdog') ||
      entry.log.message.toLowerCase().contains('engine exited');

  Future<void> _clearLive() async {
    if (_clearing || _tab != 0) return;
    setState(() => _clearing = true);
    _logGeneration++;
    try {
      // Helper clears only ZAPRET_LOGS (the live ring), not the disk journal.
      await helperClient.clearZapretLogs();
      if (mounted) setState(() { _logs = const []; _error = null; });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _clearing = false);
    }
  }

  bool _matches(_JournalEntry entry) {
    final log = entry.log;
    if (_tab == 1 && !_isCrashEntry(entry)) {
      return false;
    }
    if (_tab == 3 && !isRecoveryJournalMessage(log.message)) return false;
    return (_filter == 'all' || log.level == _filter) &&
        '${entry.component} ${log.level} ${log.message}'
            .toLowerCase().contains(_query.toLowerCase());
  }

  Widget _record(BuildContext context, _JournalEntry entry) {
    final log = entry.log;
    return RecordListItem(
      onTap: () {},
      header: RecordHeader(children: [
        RecordTimestamp(log.time.toLocal().toString().split('.').first),
        RecordLabel(
          label: _levelLabel(AppLocalizations.of(context), log.level),
          tone: switch (log.level) {
            'error' => RecordTone.error,
            'stderr' => RecordTone.warning,
            _ => RecordTone.neutral,
          },
        ),
      ]),
      body: SelectableText(
        _tab == 0 ? log.message : '[${entry.component}] ${log.message}',
        style: RecordTextStyles.of(context).primary,
      ),
    );
  }

  Widget _filterSection(BuildContext context, List<_JournalEntry> filtered, {String? error}) {
    final l = AppLocalizations.of(context);
    return generateSection(
      items: [
        if (_tab == 0)
          ListItem(
            title: Text(l.openLogsFolder),
            leading: const GlyphIcon(AppGlyphs.openExternal),
            onTap: () async => system.openDirectory(await zapretFileLogger.directoryPath),
          ),
        if (_tab == 0)
          ListItem(
            leading: const GlyphIcon(AppGlyphs.clearAll),
            title: Text(Localizations.localeOf(context).languageCode == 'ru' ? 'Очистить отображаемый журнал' : 'Clear displayed log'),
            onTap: _clearing ? null : _clearLive,
          ),
        if (widget.embedded) ...[
          if (widget.crashOnly)
            ListItem(
              title: Text(l.openLogsFolder),
              leading: const GlyphIcon(AppGlyphs.openExternal),
              onTap: () async => system.openDirectory(await crashFileLogger.directoryPath),
            ),
          ListItem<String>.options(
            title: Text(Localizations.localeOf(context).languageCode == 'ru' ? 'Уровень' : 'Level'),
            options: _filters,
            value: _filter,
            textBuilder: (level) => level == 'all' ? l.forkAllEvents : _levelLabel(l, level),
            onChanged: (level) => setState(() => _filter = level),
          ),
        ],
          ListItem(
            title: Text(Localizations.localeOf(context).languageCode == 'ru' ? 'Копировать видимые записи' : 'Copy visible entries'),
            onTap: filtered.isEmpty ? null : () async => Clipboard.setData(ClipboardData(
              text: filtered.map((entry) => '[${entry.log.time.toLocal()}] [${entry.component}] [${entry.log.level}] ${entry.log.message}').join('\n'),
            )),
          ),
        if (_tab != 0)
          ListItem(
            title: Text(l.update),
            trailing: const GlyphIcon(AppGlyphs.refresh),
            onTap: _reloadArchive,
          ),
        if (error != null)
          ListItem(title: Text(l.forkLogReadError), subtitle: Text(error)),
      ],
      footer: _tab == 0 ? l.forkLogFooter :
          (Localizations.localeOf(context).languageCode == 'ru' ? 'До $journalViewLimit последних записей. Архив на диске не изменяется.' : 'Up to $journalViewLimit recent entries. Disk archives are unchanged.'),
    );
  }

  Widget _entriesView(BuildContext context, List<_JournalEntry> entries, {String? error}) {
    final filtered = entries.where(_matches).toList(growable: false);
    final l = AppLocalizations.of(context);
    return ListView.separated(
      key: ValueKey(_tab),
      padding: EdgeInsets.fromLTRB(16, context.sectionsTopPadding + 12, 16, 16 + context.bottomInset),
      itemCount: 1 + (filtered.isEmpty ? 1 : filtered.length),
      separatorBuilder: (_, _) => const SizedBox(height: recordListGap),
      itemBuilder: (context, index) {
        if (index == 0) return _filterSection(context, filtered, error: error);
        if (filtered.isEmpty) return ListItem(title: Text(l.forkNoEvents));
        return _record(context, filtered[index - 1]);
      },
    );
  }

  Widget _journal(BuildContext context) {
    final l = AppLocalizations.of(context);
    return FutureBuilder<_ArchiveResult>(
      future: _archive,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done && !snapshot.hasData) {
          return const Center(child: CommonCircleLoading.page());
        }
        if (snapshot.hasError) {
          return Center(child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l.forkJournalUnavailable),
              TextButton(
                onPressed: _reloadArchive,
                child: Text(l.retry),
              ),
            ],
          ));
        }
        final data = snapshot.data;
        final unavailable = data?.unavailable ?? const <String>[];
        return _entriesView(context, data?.entries ?? const [],
          error: unavailable.isEmpty ? null : '${l.forkJournalUnavailable}: ${unavailable.join(', ')}');
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    if (widget.embedded) return _journal(context);
    return CommonScaffold(
      title: widget.journalOnly ? l.forkServiceJournal
          : widget.crashOnly ? l.forkCrashHistory
          : widget.recoveryOnly ? (Localizations.localeOf(context).languageCode == 'ru' ? 'Восстановления Helper / Zapret' : 'Helper / Zapret recoveries')
          : l.forkZapretLogs,
      titleWidget: PageTitleTabs(
        labels: [
          for (final level in _filters)
            switch (level) {
              'all' => l.forkAllEvents,
              'error' => l.forkErrors,
              _ => _levelLabel(l, level),
            },
        ],
        selectedIndex: _filters.indexOf(_filter),
        onSelected: (index) => setState(() => _filter = _filters[index]),
      ),
      searchState: AppBarSearchState(onSearch: (query) => setState(() => _query = query)),
      body: Builder(
        builder: (context) => _tab == 0
            ? _entriesView(context, [
                for (final log in _logs.reversed)
                  (log: log, component: 'Zapret'),
              ], error: _error)
            : _journal(context),
      ),
    );
  }
}

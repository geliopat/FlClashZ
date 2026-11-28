import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/inherited.dart';
import 'package:fl_clash/views/zapret_logs.dart';
import 'package:fl_clash/views/recovery_history.dart';
import 'package:fl_clash/views/resources.dart';
import 'package:fl_clash/ui/title_tabs.dart';
import 'package:fl_clash/views/config/general.dart' show MihomoWatchdogItem;
import 'package:fl_clash/l10n/l10n.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:fl_clash/common/common.dart';
import 'package:path/path.dart' as p;

import 'package:fl_clash/common/component_integrity.dart';
import 'package:fl_clash/core/desktop/helper_client.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class DiagnosticsView extends ConsumerStatefulWidget {
  const DiagnosticsView({super.key});

  @override
  ConsumerState<DiagnosticsView> createState() => _DiagnosticsViewState();
}

class _DiagnosticsViewState extends ConsumerState<DiagnosticsView> {
  bool _busy = false;
  int _tab = 0;
  bool? _sectionActive;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = SectionActivityScope.isActiveOf(context);
    if (_sectionActive == true && !active) _tab = 0;
    _sectionActive = active;
    // Keep the report and any ongoing diagnostic operation. Only the
    // selected tab is transient navigation state.
  }

  final _results = <String, String>{};
  DateTime? _observedAt;
  String _formatTime(DateTime time) => time.toLocal().toString().split('.').first;
  String get _report => [
    if (_observedAt != null) 'FlClashZ · ${_formatTime(_observedAt!)}',
    ..._results.entries.map((entry) => '${entry.key}: ${entry.value}'),
  ].join('\n');
  Future<String> _windowsStatus(String command) async {
    final root = Platform.environment['SystemRoot'];
    if (root == null) throw StateError('SystemRoot unavailable');
    final exe = p.join(root, 'System32', 'WindowsPowerShell', 'v1.0', 'powershell.exe');
    final process = await Process.start(exe, ['-NoProfile', '-NonInteractive', '-Command', command]);
    // Drain both streams even for a failed or timed-out status check.
    final output = process.stdout.transform(systemEncoding.decoder).join();
    final errors = process.stderr.transform(systemEncoding.decoder).join();
    try {
      final (code, stdout, _) = await (process.exitCode, output, errors).wait
          .timeout(const Duration(seconds: 12));
      if (code != 0) throw StateError('Windows status unavailable');
      return stdout.trim();
    } on TimeoutException {
      process.kill();
      rethrow;
    }
  }

  Future<void> _run() async {
    if (_busy) return;
    final l = AppLocalizations.of(context);
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final profileId = ref.read(currentProfileIdProvider);
    final pushes = ref.read(setupActionProvider.notifier).pushes;
    final coreStatus = ref.read(coreStatusProvider);
    setState(() { _busy = true; _results.clear(); _observedAt = DateTime.now(); });
    Future<void> check(String name, Future<String> Function() task) async {
      if (!mounted) return;
      String result;
      try {
        result = await task();
      } catch (_) {
        result = l.forkCheckFailed;
      }
      if (mounted) setState(() => _results[name] = result);
    }
    final ok = l.forkPassed;
    final unavailable = l.forkUnavailable;
    try {
      await check('Mihomo', () async {
        if (ref.read(coreStatusProvider) != CoreStatus.connected) return unavailable;
        final core = ref.read(coreHandlerProvider);
        await core.getAppliedHosts();
        final version = await core.getCoreVersion();
        return version.trim().isEmpty ? unavailable : '$ok · $version';
      });
      await check(ru ? 'Применённая конфигурация' : 'Applied configuration', () async {
        if (ref.read(coreStatusProvider) != CoreStatus.connected) return unavailable;
        return await ref.read(setupActionProvider.notifier).inputsApplied()
            ? ok : (ru ? 'Применение текущих настроек не подтверждено' : 'Current settings not confirmed applied');
      });
      await check('Core identity', () async {
        if (ref.read(coreStatusProvider) != CoreStatus.connected) return unavailable;
        final identity = await ref.read(coreHandlerProvider).getCoreIdentity();
        if (identity == null) return unavailable;
        final version = identity['version'];
        final engine = identity['engineRevision'];
        final host = identity['hostRevision'];
        if (version is! String || engine is! String || host is! String ||
            version.isEmpty || engine.isEmpty || host.isEmpty) return unavailable;
        return '$version · Engine: $engine · Host: $host';
      });
      await check('Core capabilities', () async {
        if (ref.read(coreStatusProvider) != CoreStatus.connected) return unavailable;
        final capabilities = await ref.read(coreHandlerProvider).getCoreCapabilities();
        return capabilities.isEmpty ? unavailable : (capabilities.toList()..sort()).join(', ');
      });
      await check('Helper / IPC', () async =>
        await helperClient.readiness(timeout: const Duration(seconds: 3), verifyHelperBinary: true) == HelperReadiness.ready ? ok : unavailable);
      await check('Zapret', () async {
        final status = await helperClient.zapretStatus();
        final catalog = await helperClient.zapretStrategies();
        return '${status.running ? l.forkRunning : l.forkStopped} · ${catalog.length} ${l.forkStrategies}';
      });
      await check(l.forkComponentIntegrity, () async {
        final failures = await checkWindowsComponents();
        return failures.isEmpty ? ok : '${l.forkMissingDamaged}: ${failures.length}';
      });
      await check(l.forkSettingsJson, () async {
        final saved = await preferences.getConfigMap();
        if (saved == null) return unavailable;
        Config.strictFromJson(saved);
        final current = ref.read(configProvider);
        Config.strictFromJson(jsonDecode(jsonEncode(current)) as Map<String, Object?>);
        return ok;
      });
      await check('TUN', () async {
        if (!ref.read(patchClashConfigProvider).tun.enable || !ref.read(isStartProvider)) {
          return l.forkTunNotRequested;
        }
        if (ref.read(coreStatusProvider) != CoreStatus.connected) return unavailable;
        return await ref.read(coreHandlerProvider).getTunFailed()
          ? l.forkTunFailure
          : l.forkTunNoFailure;
      });
      await check(l.forkSystemProxy, () async {
        final expected = ref.read(networkSettingProvider).systemProxy && ref.read(isStartProvider);
        // Report only the enable flag; never expose proxy addresses or credentials.
        final actual = await _windowsStatus(
          r"$ErrorActionPreference='Stop'; $v=Get-ItemProperty -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings' -ErrorAction Stop; if ($v.ProxyEnable -eq 1) {'1'} else {'0'}",
        );
        if (actual != '0' && actual != '1') return unavailable;
        final enabled = actual == '1';
        final state = enabled ? l.enabled : l.disabled;
        if (enabled != expected) {
          final expectedState = expected ? l.enabled : l.disabled;
          return '${l.forkCheckFailed} · ${l.forkState}: $expectedState → Windows: $state';
        }
        return '$ok · Windows: $state';
      });
      await check('WinDivert', () async {
        final running = (await helperClient.zapretStatus()).running;
        final drivers = await _windowsStatus(
          r"$ErrorActionPreference='Stop'; Get-CimInstance Win32_SystemDriver | Where-Object { $_.Name -like 'WinDivert*' } | ForEach-Object { $_.State }",
        );
        final active = drivers.split(RegExp(r'\s+')).where((state) => state == 'Running').length;
        if (active > 0) {
          // SCM reports system-wide drivers, not which process owns handles.
          return ru
              ? 'Активных драйверов: $active · принадлежность FlClashZ не подтверждена'
              : 'Active drivers: $active · FlClashZ ownership unconfirmed';
        }
        return running ? l.forkDriverNotFound : l.forkStopped;
      });
      await check(l.forkServiceJournal, () async {
        await helperClient.zapretLogArchive();
        return ok;
      });
      await check(l.forkNetworkChecks, () async {
        final results = ref.read(zapretDiagnosticsProvider);
        if (results.checkedAt == null) {
          return ru ? 'Ещё не измерено' : 'Not measured yet';
        }
        final accepted = ZapretProbeTarget.values.where((target) => results.resultOf(target).accepted).length;
        final confirmed = ZapretProbeTarget.values.where((target) =>
            results.resultOf(target).status != ZapretProbeStatus.checking).length;
        return '$accepted/${ZapretProbeTarget.values.length} HTTPS · ${l.forkLatestDirect}'
            ' · ${ru ? 'Подтверждённых результатов' : 'Confirmed results'}: $confirmed'
            ' · ${_formatTime(results.checkedAt!)}';
      });
    } finally {
      if (mounted) setState(() {
        if (profileId != ref.read(currentProfileIdProvider) ||
            pushes != ref.read(setupActionProvider.notifier).pushes ||
            coreStatus != ref.read(coreStatusProvider)) {
          _results[ru ? 'Актуальность отчёта' : 'Report validity'] = ru
              ? 'Состояние изменилось во время проверки. Повтори диагностику.'
              : 'State changed during checks. Run diagnostics again.';
        }
        _busy = false;
      });
    }
  }

  Widget _watchdog(BuildContext context) {
    final zapret = ref.watch(zapretControllerProvider);
    return ListView(
      padding: EdgeInsets.fromLTRB(16, context.sectionsTopPadding, 16, 16 + context.bottomInset),
      children: [
        generateSection(items: [
          const MihomoWatchdogItem(),
          ListItem(
            title: const Text('Watchdog Zapret'),
            subtitle: Text(AppLocalizations.of(context).forkWatchdogHint),
            trailing: Switch(
              value: zapret.watchdog,
              onChanged: zapret.busy ? null : ref.read(zapretControllerProvider.notifier).setWatchdog,
            ),
          ),
        ]),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    return CommonScaffold(
      title: l.forkDiagnostics,
      titleWidget: PageTitleTabs(
        labels: [l.forkDiagnostics, 'Watchdog', l.forkCrashHistory, ru ? 'Восстановления' : 'Recoveries'],
        selectedIndex: _tab,
        onSelected: (index) => setState(() => _tab = index),
      ),
      body: Builder(builder: (context) => switch (_tab) {
        1 => _watchdog(context),
        2 => const ZapretLogsView(key: ValueKey('crash-archive'), crashOnly: true, embedded: true),
        3 => const RecoveryHistoryView(),
        _ => _diagnostics(context),
      }),
    );
  }

  Widget _diagnostics(BuildContext context) => ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
        top: context.sectionsTopPadding,
        bottom: 16 + context.bottomInset,
      ),
      children: [
        generateSection(items: [
          ListItem.open(
            title: Text(context.appLocalizations.resources),
            leading: const GlyphIcon(AppGlyphs.resources),
            widget: const ResourcesView(),
          ),
          ListItem(
            title: Text(Localizations.localeOf(context).languageCode == 'ru'
                ? 'Журнал приложения' : 'Application journal'),
            leading: const GlyphIcon(AppGlyphs.openExternal),
            onTap: () async => system.openDirectory(await appFileLogger.directoryPath),
          ),
          ListItem(title: Text(AppLocalizations.of(context).forkRunDiagnostics),
            onTap: _busy ? null : _run,
            trailing: _busy ? const CommonCircleLoading() : GlyphIcon(AppGlyphs.playPause(0))),
          ListItem(title: Text(AppLocalizations.of(context).forkCopyReport),
            onTap: _busy || _results.isEmpty ? null : () async {
              await Clipboard.setData(ClipboardData(text: _report));
            }),
          ListItem(
            title: Text(context.appLocalizations.forkSaveDiagnosticReport),
            onTap: _busy || _results.isEmpty ? null : () async {
              try {
                final file = File(p.join(await appPath.downloadDirPath, 'FlClashZ-diagnostics-${DateTime.now().millisecondsSinceEpoch}.txt'));
                await file.writeAsString(_report, flush: true);
                if (context.mounted) dialogs.showNotifier(file.path);
              } catch (_) {
                if (context.mounted) dialogs.showNotifier(context.appLocalizations.forkReportSaveFailed);
              }
            },
          ),
        ]),
        const ListSectionGap(),
        generateSection(title: AppLocalizations.of(context).forkResults, items: [
          if (_observedAt != null)
            ListItem(title: Text(Localizations.localeOf(context).languageCode == 'ru'
                ? 'Начало проверки' : 'Check started'), subtitle: Text(_formatTime(_observedAt!))),
          for (final entry in _results.entries)
            ListItem(title: Text(entry.key), subtitle: Text(entry.value)),
        ]),
      ],
  );
}

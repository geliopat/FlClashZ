import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/log_export.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:convert';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/features/form/form.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/state.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/views/config/on_demand.dart';
import 'package:fl_clash/views/config/smart_hosts.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

part 'general/port_form.dart';

class LogLevelItem extends ConsumerWidget {
  const LogLevelItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return ConfigOptionsItem<LogLevel>(
      title: (l) => l.logLevel,
      managedKey: 'clash.log-level',
      options: LogLevel.values,
      textBuilder: (logLevel) => logLevel.name,
      selector: patchClashConfigProvider.select((state) => state.logLevel),
      onChanged: (ref, value) => ref
          .read(patchClashConfigProvider.notifier)
          .update((state) => state.copyWith(logLevel: value)),
    );
  }
}

class TestUrlItem extends ConsumerWidget {
  const TestUrlItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final url = ref.watch(appSettingProvider.select((state) => state.testUrl));
    final choices = [...delayTestPresets.keys, 'custom'];
    final chosen = delayTestPresets.entries
        .where((entry) => entry.value == url).firstOrNull?.key ?? 'custom';
    return ListItem<String>.options(
      title: Text(l.testUrl),
      subtitle: Text(url),
      options: choices,
      value: chosen,
      textBuilder: (value) => value == 'custom' ? l.custom : value,
      onChanged: (value) {
        ref.read(customDelayUrlProvider.notifier).choose(value);
      },
    );
  }
}

class CustomDelayUrlItem extends ConsumerWidget {
  const CustomDelayUrlItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final url = ref.watch(appSettingProvider.select((state) => state.testUrl));
    return ListItem.input(
      title: Text('${l.testUrl} · ${l.custom}'),
      subtitle: Text(url),
      resetValue: defaultTestUrl,
      dialogTitle: l.testUrl,
      value: url,
      maxLength: TextInputLimits.url,
      validator: (value) => validTestEndpoint(value?.trim() ?? '')
          ? null : l.urlTip(l.testUrl),
      onChanged: (value) {
        if (value != null && validTestEndpoint(value.trim())) {
          ref.read(customDelayUrlProvider.notifier).remember(value.trim());
          ref.read(appSettingProvider.notifier)
              .update((state) => state.copyWith(testUrl: value.trim()));
        }
      },
    );
  }
}

class SpeedTestUrlItem extends ConsumerWidget {
  const SpeedTestUrlItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final settings = ref.watch(speedTestSettingsProvider);
    final action = ref.read(speedTestSettingsProvider.notifier);
    return ListItem<SpeedTestService>.options(
      title: Text(l.forkSpeedTestUrl),
      subtitle: Text(l.forkDirectYandex),
      options: const [SpeedTestService.cloudflare, SpeedTestService.cachefly, SpeedTestService.custom],
      value: vpnSpeedService(settings.service),
      textBuilder: (value) => switch (value) {
        SpeedTestService.cloudflare => 'Cloudflare',
        SpeedTestService.cachefly => 'CacheFly (download)',
        SpeedTestService.yandex => 'Yandex Internetometer',
        SpeedTestService.custom => l.custom,
      },
      onChanged: (value) => action.set(settings.copyWith(service: value)),
    );
  }
}

class CustomSpeedUrlItem extends ConsumerWidget {
  const CustomSpeedUrlItem({super.key, required this.upload});
  final bool upload;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = context.appLocalizations;
    final settings = ref.watch(speedTestSettingsProvider);
    final value = upload ? settings.uploadUrl : settings.downloadUrl;
    final title = upload ? l.forkSpeedUploadUrl : l.forkSpeedDownloadUrl;
    return ListItem.input(
      title: Text(title),
      subtitle: Text(value),
      dialogTitle: title,
      value: value,
      resetValue: upload ? speedTestDefaultUpload : speedTestDefaultDownload,
      maxLength: TextInputLimits.url,
      validator: (text) => validTestEndpoint(text?.trim() ?? '')
          ? null : l.urlTip(title),
      onChanged: (text) {
        if (text == null || !validTestEndpoint(text.trim())) return;
        final controller = ref.read(speedTestSettingsProvider.notifier);
        final latest = ref.read(speedTestSettingsProvider);
        controller.set(upload
            ? latest.copyWith(uploadUrl: text.trim(), service: SpeedTestService.custom)
            : latest.copyWith(downloadUrl: text.trim(), service: SpeedTestService.custom));
      },
    );
  }
}

class DelayTestTimeoutItem extends ConsumerWidget {
  const DelayTestTimeoutItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return ConfigOptionsItem<int>(
      title: (l) => l.delayTestTimeout,
      options: delayTestTimeoutOptions,
      textBuilder: (value) => '$value ms',
      selector: appSettingProvider.select((state) => state.delayTestTimeout),
      onChanged: (ref, value) => ref
          .read(appSettingProvider.notifier)
          .update((state) => state.copyWith(delayTestTimeout: value)),
    );
  }
}

class PortItem extends ConsumerWidget {
  const PortItem({super.key});

  Future<void> handleShowPortForm(BuildContext context) async {
    await showFormSheet<void>(
      context: context,
      builder: (_) => const _PortForm(),
    );
  }

  @override
  Widget build(BuildContext context, ref) {
    final appLocalizations = context.appLocalizations;
    final mixedPort = ref.watch(
      patchClashConfigProvider.select((state) => state.mixedPort),
    );
    return ListItem(
      title: Text(appLocalizations.port),
      subtitle: Text('$mixedPort'),
      onTap: () {
        handleShowPortForm(context);
      },
    );
  }
}

class HostsItem extends ConsumerWidget {
  const HostsItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    final appLocalizations = context.appLocalizations;
    final hosts = ref.watch(
      patchClashConfigProvider.select((state) => state.hosts),
    );
    return ListItem.open(
      title: const Text('Hosts'),
      subtitle: Text(
        hosts.isEmpty
            ? appLocalizations.none
            : appLocalizations.itemsCount(hosts.length),
      ),
      widget: MapEditView(
        title: 'Hosts',
        entries: hosts,
        keyMaxLength: TextInputLimits.domain,
        valueMaxLength: TextInputLimits.hostValue,
        titleBuilder: (item) => Text(item.key),
        subtitleBuilder: (item) => Text(item.value),
      ),
      onChanged: (value) {
        if (value is! Map<String, String>) {
          return;
        }
        ref
            .read(patchClashConfigProvider.notifier)
            .update((state) => state.copyWith(hosts: value));
      },
    );
  }
}

class AuthenticationItem extends ConsumerWidget {
  const AuthenticationItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return ConfigToggleItem(
      title: (l) => l.authentication,
      managedKey: 'clash.authentication',
      selector: networkSettingProvider.select(
        (state) => state.authentication.enable,
      ),
      onChanged: (ref, value) =>
          ref.read(networkSettingProvider.notifier).update((state) {
            var authentication = state.authentication.copyWith(enable: value);
            if (value && authentication.username.isEmpty) {
              authentication = authentication.copyWith(
                username: generateRandomSecret(8),
                password: generateRandomSecret(16),
              );
            }
            return state.copyWith(authentication: authentication);
          }),
    );
  }
}

class AuthenticationAccountItem extends ConsumerWidget {
  const AuthenticationAccountItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return ConfigTextItem(
      title: (l) => l.account,
      maxLength: TextInputLimits.userName,
      managedKey: 'clash.authentication',
      selector: networkSettingProvider.select(
        (state) => state.authentication.username,
      ),
      // mihomo and the Dart proxy string both split user:pass on the first
      // colon, so a colon in the username breaks authentication.
      normalize: (value) => value.trim().replaceAll(':', ''),
      onChanged: (ref, value) => ref
          .read(networkSettingProvider.notifier)
          .update((state) => state.copyWith.authentication(username: value)),
    );
  }
}

class AuthenticationPasswordItem extends ConsumerWidget {
  const AuthenticationPasswordItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return ConfigTextItem(
      title: (l) => l.password,
      maxLength: TextInputLimits.password,
      managedKey: 'clash.authentication',
      selector: networkSettingProvider.select(
        (state) => state.authentication.password,
      ),
      normalize: (value) => value.trim(),
      onChanged: (ref, value) => ref
          .read(networkSettingProvider.notifier)
          .update((state) => state.copyWith.authentication(password: value)),
    );
  }
}

class ExternalControllerSecretItem extends ConsumerWidget {
  const ExternalControllerSecretItem({super.key});

  @override
  Widget build(BuildContext context, ref) {
    return ConfigTextItem(
      title: (l) => l.externalControllerSecret,
      managedKey: 'clash.secret',
      maxLength: TextInputLimits.password,
      selector: patchClashConfigProvider.select((state) => state.secret),
      normalize: (value) => value.trim(),
      allowEmpty: true,
      onChanged: (ref, value) => ref
          .read(patchClashConfigProvider.notifier)
          .update((state) => state.copyWith(secret: value)),
    );
  }
}

class OpenLogsFolderItem extends StatelessWidget {
  const OpenLogsFolderItem({super.key});

  Future<void> _open() async {
    await system.openDirectory(await fileLogger.directoryPath);
  }

  @override
  Widget build(BuildContext context) {
    return ListItem(
      leading: const GlyphIcon(AppGlyphs.openExternal),
      title: Text(context.appLocalizations.openLogsFolder),
      onTap: _open,
    );
  }
}

class ExportAllLogsItem extends ConsumerStatefulWidget {
  const ExportAllLogsItem({super.key});

  @override
  ConsumerState<ExportAllLogsItem> createState() => _ExportAllLogsItemState();
}

class _ExportAllLogsItemState extends ConsumerState<ExportAllLogsItem> {
  bool _busy = false;

  Future<void> _export() async {
    if (_busy) return;
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final dns = jsonEncode([
      for (final query in ref.read(dnsQueriesProvider).list)
        {
          'time': query.time.toString(),
          'domain': query.domain,
          'type': query.type,
          'initiator': query.initiator?.label,
          'resolver': query.resolverName,
          'upstream': query.upstream,
          'cached': query.cached,
          'stages': query.stages,
          'rcode': query.rcode,
          'delay': query.delay,
          'answers': query.answers,
          'error': query.error,
        },
    ]);
    setState(() => _busy = true);
    Directory? temp;
    try {
      temp = await Directory.systemTemp.createTemp('flclashz-logs-');
      final name = 'FlClashZ-logs-${DateTime.now().millisecondsSinceEpoch}.zip';
      final archive = File('${temp.path}${Platform.pathSeparator}$name');
      final incomplete = await exportAllLogs(archive, dnsSnapshot: dns);
      if (!mounted) return;
      // Windows can choose a destination without loading the ZIP into RAM.
      final destination = await FilePicker.saveFile(
        fileName: name, initialDirectory: await appPath.downloadDirPath,
      );
      if (destination == null || !mounted) return;
      if (destination.scheme != 'file') throw StateError('Invalid archive destination');
      await archive.copy(destination.toFilePath());
      if (!mounted) return;
      if (incomplete.isNotEmpty) {
        dialogs.showNotifier(
          ru ? 'Архив сохранён частично: ${incomplete.join(', ')}'
             : 'Partial archive saved: ${incomplete.join(', ')}',
          level: MessageLevel.warning,
        );
      } else {
        dialogs.showNotifier(context.appLocalizations.exportSuccess);
      }
    } catch (_) {
      if (mounted) dialogs.showNotifier(context.appLocalizations.forkReportSaveFailed,
          level: MessageLevel.error);
    } finally {
      if (temp != null) {
        try { await temp.delete(recursive: true); } catch (_) {}
      }
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    return ListItem(
      leading: const GlyphIcon(AppGlyphs.export),
      title: Text(ru ? 'Экспорт всех логов' : 'Export all logs'),
      subtitle: Text(ru
          ? 'ZIP: все сохранённые журналы и текущие DNS-запросы. Может содержать сетевые данные.'
          : 'ZIP: retained logs and current DNS queries. May contain network data.'),
      onTap: _busy ? null : _export,
      trailing: _busy ? const CommonCircleLoading() : null,
    );
  }
}

class ShareLogsItem extends StatefulWidget {
  const ShareLogsItem({super.key});

  @override
  State<ShareLogsItem> createState() => _ShareLogsItemState();
}

class _ShareLogsItemState extends State<ShareLogsItem> {
  var _sharing = false;

  Future<void> _share() async {
    if (_sharing) {
      return;
    }
    _sharing = true;
    final appLocalizations = context.appLocalizations;
    try {
      final shared = await globalState.safeRun(() async {
        final directory = Directory(await appPath.shareDirPath);
        await directory.create(recursive: true);
        final archive = await fileLogger.archiveToday(directory.path);
        if (archive == null) {
          return false;
        }
        await app?.shareFile(archive, mimeType: 'application/zip');
        return true;
      }, title: appLocalizations.shareLogs);
      if (shared == false) {
        dialogs.showNotifier(appLocalizations.noLogsToday);
      }
    } finally {
      _sharing = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListItem(
      leading: const GlyphIcon(AppGlyphs.export),
      title: Text(context.appLocalizations.shareLogs),
      onTap: _share,
    );
  }
}

class ReturnToProviderItem extends ConsumerWidget {
  const ReturnToProviderItem({super.key});

  Future<void> _release(BuildContext context, WidgetRef ref) async {
    final appLocalizations = context.appLocalizations;
    final confirmed = await dialogs.showMessage(
      title: appLocalizations.returnAllToProvider,
      message: TextSpan(text: appLocalizations.returnAllToProviderTip),
      confirmText: appLocalizations.confirm,
    );
    if (confirmed != true) {
      return;
    }
    ref.read(managedSettingsActionProvider.notifier).releaseAll();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListItem(
      leading: const GlyphIcon(AppGlyphs.lock),
      title: Text(context.appLocalizations.returnAllToProvider),
      onTap: () => _release(context, ref),
    );
  }
}

class ResetAppItem extends ConsumerWidget {
  const ResetAppItem({super.key});

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final appLocalizations = context.appLocalizations;
    final confirmed = await dialogs.showMessage(
      title: appLocalizations.resetApp,
      message: TextSpan(text: appLocalizations.resetAppTip),
      confirmText: appLocalizations.resetApp,
      destructive: true,
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(storeActionProvider.notifier).handleClear(everything: true);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final error = context.colorScheme.error;
    return ListItem(
      leading: GlyphIcon(AppGlyphs.delete, color: error),
      title: Text(
        context.appLocalizations.resetApp,
        style: TextStyle(color: error),
      ),
      onTap: () => _reset(context, ref),
    );
  }
}

ConfigToggleItem _clashToggle({
  required ConfigLabel title,
  required bool Function(PatchClashConfig state) select,
  required PatchClashConfig Function(PatchClashConfig state, bool value) update,
  String? managedKey,
}) {
  return ConfigToggleItem(
    title: title,
    managedKey: managedKey,
    selector: patchClashConfigProvider.select(select),
    onChanged: (ref, value) => ref
        .read(patchClashConfigProvider.notifier)
        .update((state) => update(state, value)),
  );
}

ConfigToggleItem _appSettingToggle({
  required ConfigLabel title,
  required bool Function(AppSettingProps state) select,
  required AppSettingProps Function(AppSettingProps state, bool value) update,
  String? managedKey,
}) {
  return ConfigToggleItem(
    title: title,
    managedKey: managedKey,
    selector: appSettingProvider.select(select),
    onChanged: (ref, value) => ref
        .read(appSettingProvider.notifier)
        .update((state) => update(state, value)),
  );
}

class GeneralView extends ConsumerWidget {
  const GeneralView({super.key});

  List<Widget> _startupItems(
    AppLocalizations appLocalizations, {
    required bool simple,
  }) {
    return [
      if (system.isDesktop) ...[
        _appSettingToggle(
          title: (l) => l.autoLaunch,
          managedKey: 'app.autoLaunch',
          select: (state) => state.autoLaunch,
          update: (state, value) => state.copyWith(autoLaunch: value),
        ),
        _appSettingToggle(
          title: (l) => l.silentLaunch,
          managedKey: 'app.silentLaunch',
          select: (state) => state.silentLaunch,
          update: (state, value) => state.copyWith(silentLaunch: value),
        ),
      ],
      if (system.isMacOS)
        _appSettingToggle(
          title: (l) => l.menuBarMode,
          select: (state) => state.menuBarMode,
          update: (state, value) => state.copyWith(menuBarMode: value),
        ),
      _appSettingToggle(
        title: (l) => l.autoRun,
        managedKey: 'app.autoRun',
        select: (state) => state.autoRun,
        update: (state, value) => state.copyWith(autoRun: value),
      ),
      if (!simple)
        ListItem.open(
          title: Text(appLocalizations.onDemand),
          widget: const OnDemandView(),
        ),
      _appSettingToggle(
        title: (l) => l.minimizeOnExit,
        managedKey: 'app.minimizeOnExit',
        select: (state) => state.minimizeOnExit,
        update: (state, value) => state.copyWith(minimizeOnExit: value),
      ),
      if (system.isAndroid) ...[
        _appSettingToggle(
          title: (l) => l.exclude,
          select: (state) => state.hidden,
          update: (state, value) => state.copyWith(hidden: value),
        ),
        _appSettingToggle(
          title: (l) => l.showNotificationStopAction,
          select: (state) => state.showNotificationStopAction,
          update: (state, value) =>
              state.copyWith(showNotificationStopAction: value),
        ),
      ],
    ];
  }

  List<Widget> _inboundItems({
    required bool authentication,
    required bool externalController,
    required bool androidSecure,
  }) {
    return [
      if (!androidSecure) const PortItem(),
      _clashToggle(
        title: (l) => l.allowLan,
        managedKey: 'clash.allow-lan',
        select: (state) => state.allowLan,
        update: (state, value) => state.copyWith(allowLan: value),
      ),
      _clashToggle(
        title: (l) => l.externalController,
        managedKey: 'clash.external-controller',
        select: (state) => state.externalController.isNotEmpty,
        update: (state, value) => state.copyWith(
          externalController: value ? defaultExternalController : '',
        ),
      ),
      if (externalController) const ExternalControllerSecretItem(),
      const AuthenticationItem(),
      if (authentication) ...const [
        AuthenticationAccountItem(),
        AuthenticationPasswordItem(),
      ],
    ];
  }

  List<Widget> _connectionItems() {
    return [
      if (!system.isWindows) ...[
        const TestUrlItem(),
        const CustomDelayUrlItem(),
        const DelayTestTimeoutItem(),
        _clashToggle(
          title: (l) => l.unifiedDelay,
          managedKey: 'clash.unified-delay',
          select: (state) => state.unifiedDelay,
          update: (state, value) => state.copyWith(unifiedDelay: value),
        ),
      ],
      _clashToggle(
        title: (l) => l.tcpConcurrent,
        managedKey: 'clash.tcp-concurrent',
        select: (state) => state.tcpConcurrent,
        update: (state, value) => state.copyWith(tcpConcurrent: value),
      ),
      ConfigOptionsItem<FindProcessMode>(
        title: (l) => l.findProcessMode,
        managedKey: 'clash.find-process-mode',
        options: FindProcessMode.values,
        textBuilder: (mode) => mode.label,
        selector: patchClashConfigProvider.select(
          (state) => state.findProcessMode,
        ),
        onChanged: (ref, value) => ref
            .read(patchClashConfigProvider.notifier)
            .update((state) => state.copyWith(findProcessMode: value)),
      ),
      _appSettingToggle(
        title: (l) => l.autoCloseConnections,
        managedKey: 'app.closeConnections',
        select: (state) => state.closeConnections,
        update: (state, value) => state.copyWith(closeConnections: value),
      ),
      _appSettingToggle(
        title: (l) => l.onlyStatisticsProxy,
        select: (state) => state.onlyStatisticsProxy,
        update: (state, value) => state.copyWith(onlyStatisticsProxy: value),
      ),
    ];
  }

  List<Widget> _requestItems() {
    return [
      _appSettingToggle(
        title: (l) => l.autoCheckUpdate,
        managedKey: 'app.autoCheckUpdate',
        select: (state) => state.autoCheckUpdate,
        update: (state, value) => state.copyWith(autoCheckUpdate: value),
      ),
    ];
  }

  List<Widget> _coreItems(BuildContext context) {
    return [
      _clashToggle(
        title: (l) => 'IPv6',
        managedKey: 'clash.ipv6',
        select: (state) => state.ipv6,
        update: (state, value) => state.copyWith(ipv6: value),
      ),
      if (system.isWindows)
        ListItem.open(
          title: const Text('Hosts'),
          widget: const SmartHostsView(),
        )
      else
        const HostsItem(),
      ConfigToggleItem(
        title: (l) => l.appendSystemDns,
        selector: networkSettingProvider.select(
          (state) => state.appendSystemDns,
        ),
        onChanged: (ref, value) => ref
            .read(networkSettingProvider.notifier)
            .update((state) => state.copyWith(appendSystemDns: value)),
      ),
      _clashToggle(
        title: (l) => l.geodataLoader,
        managedKey: 'clash.geodata-loader',
        select: (state) => state.geodataLoader == GeodataLoader.memconservative,
        update: (state, value) => state.copyWith(
          geodataLoader: value
              ? GeodataLoader.memconservative
              : GeodataLoader.standard,
        ),
      ),
    ];
  }

  List<Widget> _logItems({required bool simple}) {
    return [
      if (!simple) const LogLevelItem(),
      _appSettingToggle(
        title: (l) => l.logcat,
        managedKey: 'app.openLogs',
        select: (state) => state.openLogs,
        update: (state, value) => state.copyWith(openLogs: value),
      ),
      if (system.isDesktop) const OpenLogsFolderItem(),
      if (system.isAndroid) const ShareLogsItem(),
    ];
  }

  @override
  Widget build(BuildContext context, ref) {
    final appLocalizations = context.appLocalizations;
    final authentication = ref.watch(
      networkSettingProvider.select((state) => state.authentication.enable),
    );
    final controllerAddress = ref.watch(
      patchClashConfigProvider.select((state) => state.externalController),
    );
    final externalController = controllerAddress.isNotEmpty;
    final androidSecure = ref.watch(androidSecureProvider);
    final simple = ref.watch(simpleModeProvider);
    return BaseScaffold(
      title: appLocalizations.general,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.sectionsTopPadding,
          bottom: 16 + context.bottomInset,
        ),
        children: [
          const ManagedSettingsHint(keys: generalPageKeys),
          generateSection(
            title: appLocalizations.startupAndBackground,
            items: _startupItems(appLocalizations, simple: simple),
            footer: [
              if (system.isDesktop) appLocalizations.silentLaunchDesc,
              if (system.isMacOS) appLocalizations.menuBarModeDesc,
              appLocalizations.autoRunDesc,
              if (!simple) appLocalizations.onDemandDesc,
            ].join('\n'),
          ),
          generateSection(
            title: appLocalizations.requestsAndUpdates,
            items: _requestItems(),
          ),
          if (!simple) ...[
            generateSection(
              title: appLocalizations.inbound,
              items: _inboundItems(
                authentication: authentication,
                externalController: externalController,
                androidSecure: androidSecure,
              ),
              footer: [
                appLocalizations.externalControllerDesc(
                  externalController
                      ? controllerAddress
                      : defaultExternalController,
                ),
                appLocalizations.authenticationDesc,
              ].join('\n'),
            ),
            generateSection(
              title: appLocalizations.connection,
              items: _connectionItems(),
              footer: appLocalizations.autoCloseConnectionsDesc,
            ),
            generateSection(
              title: appLocalizations.core,
              items: _coreItems(context),
              footer: appLocalizations.ipv6Desc,
            ),
          ],
          generateSection(
            title: '${appLocalizations.logs} Mihomo',
            items: _logItems(simple: simple),
            footer: appLocalizations.logcatDesc,
          ),
          if (system.isWindows)
            generateSection(
              title: '${appLocalizations.logs} Zapret',
              items: [
                ListItem(
                  title: Text(AppLocalizations.of(context).forkVerboseEngine),
                  subtitle: Text(AppLocalizations.of(context).forkNextZapretStart),
                  trailing: Switch(
                    value: ref.watch(
                      zapretControllerProvider.select((state) => state.debugLogs),
                    ),
                    onChanged: ref.read(zapretControllerProvider.notifier).setDebugLogs,
                  ),
                ),
                ListItem(
                  leading: const GlyphIcon(AppGlyphs.openExternal),
                  title: Text(AppLocalizations.of(context).forkOpenZapretLogs),
                  onTap: () async => system.openDirectory(await zapretFileLogger.directoryPath),
                ),
              ],
              footer: AppLocalizations.of(context).forkEngineDebugTip,
            ),
          if (system.isWindows)
            generateSection(
              title: appLocalizations.logs,
              items: const [ExportAllLogsItem()],
            ),
          generateSection(
            title: AppLocalizations.of(context).forkResetSettings,
            items: const [
              ReturnToProviderItem(),
              ResetAppItem(),
            ],
          ),
        ],
      ),
    );
  }
}

class ZapretProbeIntervalItem extends ConsumerWidget {
  const ZapretProbeIntervalItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListItem<int>.options(
      title: Text(AppLocalizations.of(context).forkHttpsInterval),
      options: ZapretProbeInterval.values,
      value: ref.watch(zapretProbeIntervalProvider),
      textBuilder: (value) => value == 0 ? AppLocalizations.of(context).forkDisabled : '$value сек.',
      onChanged: (value) => ref.read(zapretProbeIntervalProvider.notifier).update(value),
    );
  }
}

class MihomoWatchdogItem extends ConsumerWidget {
  const MihomoWatchdogItem({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListItem(
      title: const Text('Watchdog Mihomo'),
      subtitle: Text(AppLocalizations.of(context).forkCoreRecovery),
      trailing: Switch(
        value: ref.watch(mihomoWatchdogProvider),
        onChanged: ref.read(mihomoWatchdogProvider.notifier).setEnabled,
      ),
    );
  }
}

class AutoDelayIntervalItem extends ConsumerWidget {
  const AutoDelayIntervalItem({super.key, required this.active});
  final bool active;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final intervals = ref.watch(autoDelayProvider);
    return ListItem<int>.options(
      title: Text(active ? AppLocalizations.of(context).forkSelectedPingInterval : AppLocalizations.of(context).forkOtherPingInterval),
      options: AutoDelayController.values,
      value: active ? intervals.active : intervals.others,
      textBuilder: (value) => value == 0 ? AppLocalizations.of(context).forkDisabled : '$value сек.',
      onChanged: (value) => ref.read(autoDelayProvider.notifier).set(
        active: active ? value : null, others: active ? null : value),
    );
  }
}

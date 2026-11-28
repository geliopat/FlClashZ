import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/service_probe.dart';
import 'package:fl_clash/providers/network_probe_settings.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/config/general.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// One settings page, reusing the existing live probe controllers.
class NetworkTestsView extends ConsumerWidget {
  const NetworkTestsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final url = ref.watch(appSettingProvider.select((s) => s.testUrl));
    final speed = ref.watch(speedTestSettingsProvider);
    final speedService = speed.service;
    final speedAction = ref.read(speedTestSettingsProvider.notifier);
    // Keep the saved custom value loaded while showing the preset selector.
    ref.watch(customDelayUrlProvider);
    final probes = ref.watch(networkProbeSettingsProvider);
    final probeAction = ref.read(networkProbeSettingsProvider.notifier);
    String seconds(int value) => ru ? '$value сек.' : '$value s';
    return CommonScaffold(
      title: ru ? 'Сетевые тесты' : 'Network tests',
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, context.sectionsTopPadding, 16, 16 + context.bottomInset),
        children: [
          generateSection(
            title: ru ? 'Задержка' : 'Latency',
            items: [
              const TestUrlItem(),
              if (!delayTestPresets.containsValue(url)) const CustomDelayUrlItem(),
              const DelayTestTimeoutItem(),
              const AutoDelayIntervalItem(active: true),
              const AutoDelayIntervalItem(active: false),
              ConfigToggleItem(
                title: (l) => l.unifiedDelay,
                managedKey: 'clash.unified-delay',
                selector: patchClashConfigProvider.select((s) => s.unifiedDelay),
                onChanged: (ref, value) => ref.read(patchClashConfigProvider.notifier)
                    .update((s) => s.copyWith(unifiedDelay: value)),
              ),
            ],
          ),
          generateSection(
            title: ru ? 'Скорость' : 'Speed',
            items: [
              const ListItem(title: Text('DIRECT'),
                subtitle: Text('Yandex Internetometer')),
              const SpeedTestUrlItem(),
              if (speedService == SpeedTestService.custom) ...const [
                CustomSpeedUrlItem(upload: false),
                CustomSpeedUrlItem(upload: true),
              ],
              ListItem<int>.options(title: Text(ru ? 'Параллельные потоки' : 'Parallel streams'),
                options: SpeedTestSettings.streamOptions, value: speed.streams,
                textBuilder: (v) => '$v', onChanged: (v) => speedAction.set(speed.copyWith(streams: v))),
              ListItem<int>.options(title: Text(ru ? 'Тайм-аут направления' : 'Timeout per direction'),
                options: SpeedTestSettings.timeOptions, value: speed.seconds,
                textBuilder: seconds, onChanged: (v) => speedAction.set(speed.copyWith(seconds: v))),
              ListItem<int>.options(title: Text(ru ? 'Лимит данных на направление' : 'Data cap per direction'),
                options: SpeedTestSettings.volumeOptions, value: speed.maxMB,
                textBuilder: (v) => '$v MB', onChanged: (v) => speedAction.set(speed.copyWith(maxMB: v))),
              ListItem<String>.options(title: Text(ru ? 'Направление' : 'Direction'),
                options: const ['both', 'download', 'upload'], value: speed.direction,
                textBuilder: (v) => switch(v) {
                  'download' => ru ? 'Загрузка' : 'Download',
                  'upload' => ru ? 'Отправка' : 'Upload',
                  _ => ru ? 'Оба' : 'Both',
                }, onChanged: (v) => speedAction.set(speed.copyWith(direction: v))),
            ],
            footer: ru ? 'Тест скорости запускается только вручную.' : 'Speed measurements are manual only.',
          ),
          generateSection(
            title: ru ? 'Внешний IP' : 'Outbound IP',
            items: [
              ListItem<String>.options(
                title: Text(ru ? 'Источник IP' : 'IP source'),
                options: ['auto', ...selectableIpSources.keys, 'custom'],
                value: probes.ipSource,
                textBuilder: (value) => switch (value) {
                  'auto' => ru ? 'Автовыбор' : 'Automatic',
                  'custom' => ru ? 'Свой URL' : 'Custom URL',
                  _ => value,
                },
                onChanged: (value) => probeAction.set(probes.copyWith(ipSource: value)),
              ),
              if (probes.ipSource == 'custom')
                ListItem.input(
                  title: Text(ru ? 'Свой URL' : 'Custom URL'),
                  dialogTitle: ru ? 'Свой URL' : 'Custom URL',
                  value: probes.customIpUrl,
                  subtitle: Text(probes.customIpUrl),
                  resetValue: const NetworkProbeSettings().customIpUrl,
                  maxLength: TextInputLimits.url,
                  validator: (value) => validTestEndpoint(value?.trim() ?? '')
                      ? null : (ru ? 'Некорректный URL' : 'Invalid URL'),
                  onChanged: (value) {
                    if (value != null && validTestEndpoint(value.trim())) {
                      probeAction.set(ref.read(networkProbeSettingsProvider).copyWith(customIpUrl: value.trim()));
                    }
                  },
                ),
              if (probes.ipSource != 'auto')
                ListItem(
                  title: Text(ru ? 'Резервные источники' : 'Fallback sources'),
                  trailing: Switch(value: probes.ipFallback,
                    onChanged: (value) => probeAction.set(probes.copyWith(ipFallback: value))),
                ),
              ListItem<int>.options(
                title: Text(ru ? 'Тайм-аут IP' : 'IP timeout'),
                options: NetworkProbeSettings.timeouts,
                value: probes.ipTimeout, textBuilder: seconds,
                onChanged: (value) => probeAction.set(probes.copyWith(ipTimeout: value)),
              ),
            ],
          ),
          generateSection(
            title: ru ? 'Доступность сервисов' : 'Service availability',
            items: [
              const ZapretProbeIntervalItem(),
              ListItem<int>.options(
                title: Text(ru ? 'Тайм-аут проверки' : 'Probe timeout'),
                options: NetworkProbeSettings.timeouts,
                value: probes.serviceTimeout, textBuilder: seconds,
                onChanged: (value) => probeAction.set(probes.copyWith(serviceTimeout: value)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

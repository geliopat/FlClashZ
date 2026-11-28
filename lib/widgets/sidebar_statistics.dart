import 'package:fl_clash/ui/network_palette.dart';
import 'package:fl_clash/ui/hover_glow.dart';
import 'package:fl_clash/ui/surface.dart';
import 'package:fl_clash/ui/shape.dart';
import 'package:fl_clash/ui/typography.dart';
import 'dart:async';
import 'dart:ffi';
import 'dart:io';

import 'package:ffi/ffi.dart';
import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/common/traffic_history.dart';
import 'package:fl_clash/core/desktop/helper_client.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/providers/connection_statistics.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _Sample {
  const _Sample(this.pid, this.created, this.cpu100ns, this.rss);
  final int pid;
  final int? created;
  final int? cpu100ns;
  final int? rss;

  static _Sample? parse(Object? value) {
    if (value is! Map || value['pid'] is! int) return null;
    int? nonnegative(Object? n) => n is int && n >= 0 ? n : null;
    final pid = nonnegative(value['pid']);
    if (pid == null) return null;
    return _Sample(pid, nonnegative(value['created']),
        nonnegative(value['cpu100ns']), nonnegative(value['rss']));
  }

  bool sameProcess(_Sample previous) =>
      pid == previous.pid && created != null && created == previous.created;
}

/// Only query the GUI's own process in Dart. Service-owned processes are
/// sampled through existing managed handles by the authenticated Helper.
_Sample _guiSample() {
  final rss = ProcessInfo.currentRss;
  if (!Platform.isWindows) return _Sample(pid, null, null, rss);
  try {
    final kernel = DynamicLibrary.open('kernel32.dll');
    final current = kernel.lookupFunction<Pointer<Void> Function(),
        Pointer<Void> Function()>('GetCurrentProcess');
    final times = kernel.lookupFunction<
        Int32 Function(Pointer<Void>, Pointer<Uint64>, Pointer<Uint64>,
            Pointer<Uint64>, Pointer<Uint64>),
        int Function(Pointer<Void>, Pointer<Uint64>, Pointer<Uint64>,
            Pointer<Uint64>, Pointer<Uint64>)>('GetProcessTimes');
    final out = calloc<Uint64>(4);
    try {
      if (times(current(), out, out + 1, out + 2,
          out + 3) != 0) {
        return _Sample(pid, out[0], out[2] + out[3], rss);
      }
    } finally {
      calloc.free(out);
    }
  } catch (_) {
    // No invented CPU figure when Windows does not supply the counters.
  }
  return _Sample(pid, null, null, rss);
}

class SidebarStatistics extends ConsumerStatefulWidget {
  const SidebarStatistics({super.key, this.onTraffic, this.onResources,
    this.trafficSelected = false, this.resourcesSelected = false});

  final VoidCallback? onTraffic;
  final VoidCallback? onResources;
  final bool trafficSelected;
  final bool resourcesSelected;

  @override
  ConsumerState<SidebarStatistics> createState() => _SidebarStatisticsState();
}

class _SidebarStatisticsState extends ConsumerState<SidebarStatistics> {
  static const _names = ['Mihomo', 'GUI', 'Zapret2', 'Helper'];
  final _clock = Stopwatch()..start();
  Map<String, _Sample?> _samples = const {};
  int? _lastSample;
  double? _cpu;
  Timer? _timer;
  bool _reading = false;

  @override
  void initState() {
    super.initState();
    unawaited(ref.read(trafficHistoryProvider).load());
    scheduleMicrotask(_refresh);
    _timer = Timer.periodic(const Duration(seconds: 2), (_) => _refresh());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!mounted || _reading || !ref.read(appVisibleProvider)) return;
    _reading = true;
    try {
      final samples = <String, _Sample?>{'GUI': _guiSample()};
      if (!ref.read(safeModeProvider)) {
        try {
          final data = await helperClient.processStats();
          samples['Mihomo'] = _Sample.parse(data['mihomo']);
          samples['Zapret2'] = _Sample.parse(data['zapret']);
          samples['Helper'] = _Sample.parse(data['helper']);
        } catch (_) {
          // An older/unavailable Helper can still leave the GUI usable.
        }
      }
      if (!mounted) return;
      if (samples['Mihomo']?.rss == null &&
          ref.read(coreStatusProvider) == CoreStatus.connected) {
        try {
          final memory = await ref.read(coreHandlerProvider).getMemoryStats();
          if (memory != null) {
            final sample = samples['Mihomo'];
            samples['Mihomo'] = _Sample(sample?.pid ?? -1,
                sample?.created, sample?.cpu100ns, memory.rss);
          }
        } catch (_) {}
      }
      if (!mounted) return;
      if (!mounted || !ref.read(appVisibleProvider)) return;
      final now = _clock.elapsedMicroseconds;
      final elapsed = _lastSample == null ? 0 : now - _lastSample!;
      double? cpu;
      if (elapsed > 0) {
        var ticks = 0;
        var complete = true;
        for (final name in _names) {
          final sample = samples[name];
          final previous = _samples[name];
          if (sample?.pid == 0) continue;
          if (sample == null || previous == null ||
              !sample.sameProcess(previous) ||
              sample.cpu100ns == null || previous.cpu100ns == null ||
              sample.cpu100ns! < previous.cpu100ns!) {
            complete = false;
            break;
          }
          ticks += sample.cpu100ns! - previous.cpu100ns!;
        }
        if (complete) {
          cpu = (ticks / (elapsed * 10 * Platform.numberOfProcessors) * 100)
              .clamp(0.0, 100.0).toDouble();
        }
      }
      setState(() {
        _samples = samples;
        _lastSample = now;
        _cpu = cpu;
      });
    } finally {
      _reading = false;
    }
  }

  String _bytes(num? bytes, {bool rate = false}) {
    if (bytes == null) return '—';
    final size = bytes.traffic;
    return '${size.value} ${size.unit}${rate ? '/s' : ''}';
  }

  Widget _line(String label, String value, TextStyle? style) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 1),
    child: Row(
      children: [
        Expanded(
          child: Text(label, style: style, maxLines: 1,
            overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text(value, maxLines: 1,
              textAlign: TextAlign.end, style: style?.copyWith(
                fontFeatures: const [FontFeature.tabularFigures()],
              )),
          ),
        ),
      ],
    ),
  );

  Widget _trafficRow(String label, Traffic? value, TextStyle? style,
      {bool rate = false}) {
    final theme = Theme.of(context);
    final down = NetworkTone.download.of(context);
    final up = NetworkTone.upload.of(context);
    final l = context.appLocalizations;
    Widget direction(bool download, Color color) => Expanded(
      child: Semantics(
        label: download ? l.download : l.upload,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: download ? AlignmentDirectional.centerStart
              : AlignmentDirectional.centerEnd,
          child: Text(
            '${download ? '↓' : '↑'} ${_bytes(download ? value?.down : value?.up, rate: rate)}',
            style: style?.copyWith(color: (download ? value?.down : value?.up) == 0
                    ? NetworkTone.inactive.of(context) : color,
                fontFeatures: const [FontFeature.tabularFigures()]),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(label, style: style?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          Row(children: [direction(true, down), const SizedBox(width: 6),
              direction(false, up)]),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = context.appLocalizations;
    final history = ref.watch(trafficHistoryProvider);
    final style = AppTextStyle.footnote.of(context);
    final heading = AppTextStyle.footnote.of(context, emphasized: true);
    final connected = ref.watch(coreStatusProvider) == CoreStatus.connected;
    final connections = ref.watch(connectionStatisticsProvider).asData?.value;
    final running = ref.watch(runTimeProvider) != null;
    final sampledSpeed = ref.watch(trafficsProvider.select(
        (state) => state.list.safeLast(const Traffic())));
    final speed = connected && running ? sampledSpeed : const Traffic();
    final session = ref.watch(totalTrafficProvider);
    final onlyProxy = ref.watch(appSettingProvider.select((s) => s.onlyStatisticsProxy));
    final ram = _names.every((name) => _samples[name]?.rss != null)
        ? _names.fold<int>(0, (sum, name) => sum + _samples[name]!.rss!)
        : null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _StatisticsSection(
            key: const ValueKey('sidebar-resources'),
            title: l.resources, heading: heading,
            onTap: widget.onResources, selected: widget.resourcesSelected,
            children: [
              _line('CPU', _cpu == null ? '—' : '${_cpu!.toStringAsFixed(1)}%', style),
              _line('RAM', _bytes(ram), style),
              for (final name in _names) _line(name, _bytes(_samples[name]?.rss), style),
            ],
          ),
          const SizedBox(height: 12),
          _StatisticsSection(
            key: const ValueKey('sidebar-traffic'),
            title: l.traffic, heading: heading,
            onTap: widget.onTraffic, selected: widget.trafficSelected,
            children: [
          Row(children: [
            Expanded(child: Text('TCP ${connected ? connections?.tcp ?? '—' : 0}',
              style: style.copyWith(color: NetworkTone.tcp.of(context)))),
            Expanded(child: Text('UDP ${connected ? connections?.udp ?? '—' : 0}',
              textAlign: TextAlign.end,
              style: style.copyWith(color: NetworkTone.udp.of(context)))),
          ]),
          _trafficRow(l.forkSidebarSpeed, speed, style, rate: true),
          _trafficRow(l.forkSidebarSession, session, style),
          ValueListenableBuilder<int>(
            valueListenable: history.revision,
            builder: (context, _, _) => _trafficRow(
              l.forkSidebar24Hours,
              history.loaded
                  ? history.window.total(DateTime.now(), onlyProxy: onlyProxy)
                  : null,
              style,
            ),
          ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatisticsSection extends StatefulWidget {
  const _StatisticsSection({super.key, required this.title, required this.heading,
    required this.children, this.onTap, required this.selected});
  final String title;
  final TextStyle? heading;
  final List<Widget> children;
  final VoidCallback? onTap;
  final bool selected;

  @override
  State<_StatisticsSection> createState() => _StatisticsSectionState();
}

class _StatisticsSectionState extends State<_StatisticsSection> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    final shadows = HoverGlowTheme.of(context).shadows(accent, hovered: _hovered);
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(widget.title, style: widget.heading?.copyWith(
          color: widget.selected ? accent : null, shadows: shadows)),
        ...widget.children,
      ],
    );
    if (widget.onTap == null) return content;
    return Semantics(
      button: true, selected: widget.selected, label: widget.title,
      child: FocusRing(
        shape: AppShape.sm,
        child: Material(
          type: MaterialType.transparency,
          child: InkWell(
            onTap: widget.onTap,
            onHover: (hovered) => setState(() => _hovered = hovered),
            mouseCursor: SystemMouseCursors.click,
            splashFactory: NoSplash.splashFactory,
            overlayColor: const WidgetStatePropertyAll(Colors.transparent),
            child: content,
          ),
        ),
      ),
    );
  }
}

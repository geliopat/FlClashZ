import 'package:fl_clash/l10n/l10n.dart';
import 'dart:async';
import 'dart:io';

import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/core.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/network_probe_settings.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/zapret.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final zapretProbeIntervalProvider = NotifierProvider<ZapretProbeInterval, int>(ZapretProbeInterval.new);

class ZapretProbeInterval extends Notifier<int> {
  static const values = [0, 5, 10, 15, 30, 60, 120];
  static const _key = 'zapret.httpsInterval';
  int _revision = 0;
  Future<void> _writes = Future.value();

  @override
  int build() {
    final revision = _revision;
    scheduleMicrotask(() async {
      try {
        final prefs = await SharedPreferences.getInstance();
        final saved = prefs.getInt(_key);
        if (ref.mounted && revision == _revision && values.contains(saved)) {
          state = saved!;
        }
      } catch (_) {
        // Unavailable preferences must not disable the current probes.
      }
    });
    return 15;
  }

  Future<void> update(int value) async {
    if (!values.contains(value)) return;
    _revision++;
    state = value;
    final write = _writes.catchError((Object _) {}).then((_) async {
      final prefs = await SharedPreferences.getInstance();
      if (!await prefs.setInt(_key, value)) {
        throw StateError('Unable to save Zapret probe interval');
      }
    });
    _writes = write;
    await write;
  }
}

final zapretDiagnosticsProvider =
    NotifierProvider<ZapretDiagnosticsController, ZapretDiagnosticsState>(
      ZapretDiagnosticsController.new,
    );

enum ZapretProbeStatus { checking, operational, degraded, blocked }

enum ZapretProbeTarget {
  youtube(
    'YouTube',
    'www.youtube.com',
    'https://www.youtube.com/generate_204',
  ),
  googleVideo(
    'GoogleVideo',
    'redirector.googlevideo.com',
    'https://redirector.googlevideo.com/report_mapping',
  ),
  discordGateway(
    'Discord Gateway',
    'gateway.discord.gg',
    'https://discord.com/api/v10/gateway',
  ),
  discordVoice(
    'Discord Voice API',
    'discord.media',
    'https://discord.com/api/v10/voice/regions',
  );

  const ZapretProbeTarget(this.label, this.host, this.url);

  final String label;
  final String host;
  final String url;
}

class ZapretProbeResult {
  const ZapretProbeResult({
    this.status = ZapretProbeStatus.checking,
    this.latencyMs,
    this.httpStatus,
    this.message,
    this.accepted = false,
  });

  final ZapretProbeStatus status;
  final int? latencyMs;
  final int? httpStatus;
  final String? message;
  // Endpoint-specific reachability, independent of the display label.
  final bool accepted;

  /// Original zapret2-gui ranking: actual HTTP response is degraded or
  /// operational; missing/unconfirmed routes never earn points.
  int get score => switch (status) {
    ZapretProbeStatus.operational => 2,
    ZapretProbeStatus.degraded => 1,
    _ => 0,
  };

  String localizedStatusLabel(AppLocalizations l) => switch (status) {
    ZapretProbeStatus.operational => l.forkRunning,
    ZapretProbeStatus.degraded => l.forkDegraded,
    ZapretProbeStatus.blocked => l.forkNoConnection,
    ZapretProbeStatus.checking => l.forkUnconfirmed,
  };

  String get statusLabel => localizedStatusLabel(AppLocalizations());
}

/// Uses the same 450 ms threshold and HTTP success handling as zapret2-gui.
ZapretProbeResult classifyZapretProbe({
  required int? statusCode,
  required int latencyMs,
}) {
  if (statusCode == null) {
    return ZapretProbeResult(
      status: ZapretProbeStatus.blocked,
      message: AppLocalizations().forkNoResponse,
    );
  }
  final accepted = statusCode >= 200 && statusCode < 300;
  final status = !accepted || latencyMs > 450
      ? ZapretProbeStatus.degraded
      : ZapretProbeStatus.operational;
  final message = !accepted
      ? 'HTTP $statusCode'
      : latencyMs > 450
          ? AppLocalizations().forkHighLatency
          : AppLocalizations().forkReachable;
  return ZapretProbeResult(
    status: status,
    latencyMs: latencyMs,
    httpStatus: statusCode,
    message: message,
    accepted: accepted,
  );
}

class ZapretDiagnosticsState {
  const ZapretDiagnosticsState(this.results);

  final Map<ZapretProbeTarget, ZapretProbeResult> results;

  ZapretProbeResult resultOf(ZapretProbeTarget target) =>
      results[target] ?? const ZapretProbeResult();
}

/// Never use the Windows resolver or system HTTP proxy for these tests:
/// the existing service-check RPC explicitly dials the Mihomo DIRECT adapter.
Future<Map<ZapretProbeTarget, ZapretProbeResult>> measureZapretTargets(
  Ref ref, Iterable<ZapretProbeTarget> targets, {
  int timeoutMs = 3500,
}) async {
  final wanted = targets.toList();
  if (ref.read(coreStatusProvider) != CoreStatus.connected) {
    return {for (final target in wanted) target: ZapretProbeResult(message: AppLocalizations().forkCoreUnavailable)};
  }
  try {
    final items = await ref.read(coreHandlerProvider).serviceCheck(ServiceCheckParams(
      proxyName: 'DIRECT',
      names: wanted.map((target) => 'zapret-${target.name}').toList(),
      timeout: timeoutMs,
    ));
    return {
      for (final target in wanted)
        target: classifyZapretService(target, items.where((item) => item.name == 'zapret-${target.name}').firstOrNull),
    };
  } catch (error) {
    return {for (final target in wanted) target: ZapretProbeResult(message: 'DIRECT · ${AppLocalizations().forkCheckFailed}: $error')};
  }
}

ZapretProbeResult classifyZapretService(ZapretProbeTarget target, ServiceCheckItem? item) {
  if (item == null) return ZapretProbeResult(message: AppLocalizations().forkNoCoreResponse);
  if (item.delay > 0) {
    if (item.chains.isEmpty || item.chains.any((chain) => chain != 'DIRECT')) {
      return ZapretProbeResult(
        latencyMs: item.delay,
        message: '${AppLocalizations().forkDirectUnconfirmed} · ${AppLocalizations().proxyChain}: ${item.chains.isEmpty ? AppLocalizations().forkUnavailable : item.chains.join(' → ')}',
      );
    }
    if (item.status == 'available') {
      return ZapretProbeResult(
        status: item.delay <= 450 ? ZapretProbeStatus.operational : ZapretProbeStatus.degraded,
        latencyMs: item.delay,
        message: 'DIRECT · HTTP 2xx',
        accepted: true,
      );
    }
    // Voice regions is an authenticated API. The existing core collapses
    // HTTP 401/403/429/451 into "restricted"; it does not expose the code.
    // Accept this only as HTTPS reachability for this particular endpoint,
    // not authentication, actual voice transport or unrestricted access.
    if (target == ZapretProbeTarget.discordVoice && item.status == 'restricted') {
      return ZapretProbeResult(
        status: ZapretProbeStatus.degraded,
        latencyMs: item.delay,
        accepted: true,
        message: 'DIRECT · restricted · HTTPS: ${AppLocalizations().forkReachable} · API: ${AppLocalizations().forkDegraded}',
      );
    }
    return ZapretProbeResult(
      status: item.status == 'restricted' || item.status == 'unavailable'
          ? ZapretProbeStatus.degraded : ZapretProbeStatus.checking,
      latencyMs: item.delay,
      message: 'DIRECT · ${AppLocalizations().status}: ${item.status}',
    );
  }
  if (item.status == 'timeout' || item.status == 'failed') {
    return ZapretProbeResult(status: ZapretProbeStatus.blocked, message: 'DIRECT · ${item.status}');
  }
  return ZapretProbeResult(message: AppLocalizations().forkNoVerifiedResult);
}

class ZapretDiagnosticsController extends Notifier<ZapretDiagnosticsState> {
  Timer? _poller;
  var _refreshing = false;
  var _refreshPending = false;
  int _generation = 0;

  void _invalidate() {
    _generation++;
    state = const ZapretDiagnosticsState({});
    if (ref.read(coreStatusProvider) == CoreStatus.connected &&
        !ref.read(zapretControllerProvider).busy) {
      if (_refreshing) {
        _refreshPending = true;
      } else {
        scheduleMicrotask(() {
          if (ref.mounted) unawaited(refresh());
        });
      }
    } else {
      _refreshPending = false;
    }
  }

  @override
  ZapretDiagnosticsState build() {
    ref.onDispose(() => _poller?.cancel());
    if (Platform.isWindows) {
      void configure(int seconds) {
        _poller?.cancel();
        if (seconds > 0) {
          _poller = Timer.periodic(Duration(seconds: seconds), (_) {
            if (ref.mounted) unawaited(refresh());
          });
        }
      }
      configure(ref.read(zapretProbeIntervalProvider));
      ref.listen(zapretProbeIntervalProvider, (_, value) {
        configure(value);
        if (value > 0) unawaited(refresh());
      });
      ref.listen(coreStatusProvider, (before, after) {
        if (before != after) _invalidate();
      });
      ref.listen(currentProfileIdProvider, (before, after) {
        if (before != after) _invalidate();
      });
      ref.listen(networkProbeSettingsProvider.select((s) => s.serviceTimeout),
          (before, after) {
        if (before != after) _invalidate();
      });
      ref.listen(zapretControllerProvider.select((s) => (
        s.running, s.pid, s.activeMode, s.activeStrategyId, s.busy,
      )), (before, after) {
        if (before != after) _invalidate();
      });
      scheduleMicrotask(() {
        if (ref.mounted) unawaited(refresh());
      });
    }
    return ZapretDiagnosticsState({
      for (final target in ZapretProbeTarget.values)
        target: const ZapretProbeResult(),
    });
  }

  Future<void> refresh() async {
    if (!Platform.isWindows || !ref.mounted || _refreshing ||
        ref.read(coreStatusProvider) != CoreStatus.connected ||
        ref.read(zapretControllerProvider).busy) return;
    _refreshing = true;
    final generation = _generation;
    try {
      final timeout = ref.read(networkProbeSettingsProvider).serviceTimeout * 1000;
      final results = await measureZapretTargets(
        ref, ZapretProbeTarget.values, timeoutMs: timeout,
      );
      if (!ref.mounted || generation != _generation ||
          ref.read(coreStatusProvider) != CoreStatus.connected ||
          ref.read(zapretControllerProvider).busy) return;
      state = ZapretDiagnosticsState(results);
      unawaited(ref.read(zapretControllerProvider.notifier).checkFallback(results));
    } finally {
      _refreshing = false;
      if (_refreshPending) {
        _refreshPending = false;
        if (ref.mounted) unawaited(refresh());
      }
    }
  }
}

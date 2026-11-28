import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/core.dart';
import 'package:fl_clash/providers/zapret_diagnostics.dart';
import 'package:fl_clash/providers/zapret.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('late interval load cannot override a newer explicit value', () async {
    SharedPreferences.setMockInitialValues({'zapret.httpsInterval': 120});
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final controller = container.read(zapretProbeIntervalProvider.notifier);
    final first = controller.update(30);
    final last = controller.update(0);
    await Future.wait([first, last]);
    expect(container.read(zapretProbeIntervalProvider), 0);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getInt('zapret.httpsInterval'), 0);
  });

  test('cleared diagnostic state never presents a previous success', () {
    const state = ZapretDiagnosticsState({});
    for (final target in ZapretProbeTarget.values) {
      expect(state.resultOf(target).accepted, isFalse);
      expect(state.resultOf(target).status, ZapretProbeStatus.checking);
    }
  });

  test('restricted Voice API counts as DIRECT HTTPS reachability only', () {
    const item = ServiceCheckItem(status: 'restricted', delay: 348, chains: ['DIRECT']);
    final voice = classifyZapretService(ZapretProbeTarget.discordVoice, item);
    expect(voice.accepted, isTrue);
    expect(voice.status, ZapretProbeStatus.degraded);
    expect(voice.latencyMs, 348);
    expect(classifyZapretService(ZapretProbeTarget.discordGateway, item).accepted, isFalse);
    expect(classifyZapretService(ZapretProbeTarget.youtube, item).accepted, isFalse);
    expect(classifyZapretService(ZapretProbeTarget.discordVoice,
        const ServiceCheckItem(status: 'restricted', delay: 348, chains: ['PROXY'])).accepted, isFalse);
    expect(classifyZapretService(ZapretProbeTarget.discordVoice,
        const ServiceCheckItem(status: 'restricted', delay: 348)).accepted, isFalse);
    expect(classifyZapretService(ZapretProbeTarget.discordVoice,
        const ServiceCheckItem(status: 'timeout', chains: ['DIRECT'])).accepted, isFalse);
  });

  test('full results rank by score then latency, separately from screening', () {
    const mode = ZapretMode.fullBypass;
    final trials = [
      const ZapretTrial('partial-fast', mode, 4, 40),
      const ZapretTrial('full-slow', mode, 3, 600, confirmed: true),
      const ZapretTrial('full-fast', mode, 6, 100, confirmed: true),
      for (var i = 0; i < 12; i++) ZapretTrial('failed-$i', mode, 0, 0),
    ];
    final selected = shortlistZapretTrials(trials);
    expect(selected, hasLength(10));
    expect(selected.take(3).map((item) => item.id),
        ['full-fast', 'partial-fast', 'full-slow']);
    expect(shortlistZapretTrials(trials, limit: 2).map((item) => item.id),
        ['full-fast', 'partial-fast']);
  });

  test('screen finalists are reachable YouTube results only, at most five', () {
    const mode = ZapretMode.fullBypass;
    final trials = [
      const ZapretTrial('blocked', mode, 0, 0, screenedOnly: true),
      const ZapretTrial('error', mode, 2, 1, screenedOnly: true, error: 'failed'),
      const ZapretTrial('full', mode, 6, 1, confirmed: true),
      const ZapretTrial('slow', mode, 1, 500, screenedOnly: true),
      for (var i = 0; i < 7; i++) ZapretTrial('ok-$i', mode, 2, 100 + i, screenedOnly: true),
    ];
    expect(selectZapretFinalists(trials).map((trial) => trial.id),
        ['ok-0', 'ok-1', 'ok-2', 'ok-3', 'ok-4']);
  });

  test('only very fast stops at a real full 6/6', () {
    const mode = ZapretMode.fullBypass;
    const perfect = ZapretTrial('a', mode, 6, 100, confirmed: true);
    const restricted = ZapretTrial('a', mode, 5, 100, confirmed: true);
    const screen = ZapretTrial('a', mode, 2, 100, screenedOnly: true);
    expect(ZapretAutoTuneMode.veryFast.shouldStop(perfect), isTrue);
    expect(ZapretAutoTuneMode.veryFast.shouldStop(restricted), isFalse);
    expect(ZapretAutoTuneMode.veryFast.shouldStop(screen), isFalse);
    expect(ZapretAutoTuneMode.fast.shouldStop(perfect), isFalse);
    expect(ZapretAutoTuneMode.full.shouldStop(perfect), isFalse);
    expect(ZapretAutoTuneMode.full.screenFirst, isFalse);
    expect(ZapretAutoTuneMode.fast.controlRuns, 2);
    expect(ZapretAutoTuneMode.veryFast.controlRuns, 1);
  });

  test('two control runs retain the lower score and require both to pass', () {
    const mode = ZapretMode.fullBypass;
    const first = ZapretTrial('a', mode, 6, 100, confirmed: true, passedTargets: 3);
    const second = ZapretTrial('a', mode, 4, 200, passedTargets: 2);
    final result = combineZapretControlRuns(first, second);
    expect(result.score, 4);
    expect(result.delay, 150);
    expect(result.confirmed, isFalse);
    expect(result.passedTargets, 2);
  });

  test('control run labels do not change scores or discard measurements', () {
    const mode = ZapretMode.fullBypass;
    const first = ZapretTrial('a', mode, 6, 100, confirmed: true,
        passedTargets: 3, details: ['YouTube: 100 ms']);
    const second = ZapretTrial('a', mode, 4, 200, passedTargets: 2,
        details: ['YouTube: 200 ms']);
    final result = combineZapretControlRuns(first, second,
        runLabel: 'Verification');
    expect(result.details, [
      'Verification 1:', 'YouTube: 100 ms',
      'Verification 2:', 'YouTube: 200 ms',
    ]);
    expect(result.score, 4);
    expect(result.delay, 150);
    expect(result.confirmed, isFalse);
  });

  test('original score awards degraded HTTP one point, not two', () {
    const direct = ['DIRECT'];
    const restricted = ServiceCheckItem(status: 'restricted', delay: 348, chains: direct);
    expect(classifyZapretService(ZapretProbeTarget.discordVoice, restricted).score, 1);
    expect(classifyZapretService(ZapretProbeTarget.youtube, restricted).score, 1);
    expect(classifyZapretService(ZapretProbeTarget.youtube,
      const ServiceCheckItem(status: 'available', delay: 450, chains: direct)).score, 2);
    expect(classifyZapretService(ZapretProbeTarget.youtube,
      const ServiceCheckItem(status: 'available', delay: 451, chains: direct)).score, 1);
    expect(classifyZapretService(ZapretProbeTarget.youtube,
      const ServiceCheckItem(status: 'available', delay: 100, chains: ['PROXY'])).score, 0);
    expect(classifyZapretService(ZapretProbeTarget.youtube,
      const ServiceCheckItem(status: 'failed', chains: direct)).score, 0);
  });

  test('trial labels distinguish complete, partial, failed, screening and errors', () {
    const mode = ZapretMode.fullBypass;
    expect(const ZapretTrial('a', mode, 6, 100, confirmed: true, passedTargets: 3).resultLabel, AppLocalizations().forkSuccess);
    expect(const ZapretTrial('b', mode, 2, 100, passedTargets: 1).resultLabel, AppLocalizations().forkPartialSuccess);
    expect(const ZapretTrial('c', mode, 0, 0).resultLabel, AppLocalizations().forkTestFailed);
    expect(const ZapretTrial('d', mode, 6, 100, screenedOnly: true, passedTargets: 3).resultLabel, AppLocalizations().forkScreenOnly);
    expect(const ZapretTrial('e', mode, 0, 0, error: 'process exited').resultLabel, AppLocalizations().forkTrialError);
    expect(const ZapretTrial('f', mode, 0, 0, screenedOnly: true).resultLabel, AppLocalizations().forkScreenFailed);
  });

  test('classifies a fast successful probe as operational', () {
    expect(
      classifyZapretProbe(statusCode: 204, latencyMs: 120).status,
      ZapretProbeStatus.operational,
    );
  });

  test('uses the zapret2-gui 450 ms degraded threshold', () {
    expect(
      classifyZapretProbe(statusCode: 200, latencyMs: 451).status,
      ZapretProbeStatus.degraded,
    );
  });

  test('keeps an HTTP error visible as a degraded reachable endpoint', () {
    final result = classifyZapretProbe(statusCode: 403, latencyMs: 80);
    expect(result.status, ZapretProbeStatus.degraded);
    expect(result.httpStatus, 403);
    expect(result.latencyMs, 80);
  });

  test('does not treat an HTTP redirect as a successful probe', () {
    expect(
      classifyZapretProbe(statusCode: 302, latencyMs: 120).status,
      ZapretProbeStatus.degraded,
    );
  });

  test('marks a missing HTTP response as blocked', () {
    expect(
      classifyZapretProbe(statusCode: null, latencyMs: 3500).status,
      ZapretProbeStatus.blocked,
    );
  });
}

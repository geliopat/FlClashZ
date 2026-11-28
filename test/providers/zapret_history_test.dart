import 'dart:convert';

import 'package:fl_clash/providers/zapret.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const trial = ZapretTrial('flowseal-alt', ZapretMode.fullBypass, 6, 42,
    confirmed: true, passedTargets: 3, details: ['YouTube: OK']);
  ZapretTuneRun run(int index) => ZapretTuneRun(
    at: DateTime.utc(2026, 11, 26).add(Duration(minutes: index)),
    tuneMode: ZapretAutoTuneMode.fast,
    trials: const [trial],
    duration: const Duration(seconds: 15),
    totalStrategies: 10,
  );

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('linked Zapret startup defaults to enabled without overriding user choice', () async {
    final preferences = await SharedPreferences.getInstance();
    expect(const ZapretState().startWithMihomo, isTrue);
    expect(ZapretController.readStartWithMihomo(preferences), isTrue);
    await preferences.setBool('zapret.startWithMihomo', false);
    expect(ZapretController.readStartWithMihomo(preferences), isFalse);
    await preferences.setBool('zapret.startWithMihomo', true);
    expect(ZapretController.readStartWithMihomo(preferences), isTrue);
  });

  test('history persists independent runs and caps retention', () async {
    for (var i = 0; i < 32; i++) {
      await saveZapretTuneRun(run(i));
    }
    final history = await loadZapretTuneHistory();
    expect(history, hasLength(zapretHistoryLimit));
    expect(history.first.at, run(31).at);
    expect(history.last.at, run(2).at);
    expect(history.first.trials.single.details, trial.details);
    expect(history.first.tuneMode, ZapretAutoTuneMode.fast);
    expect(history.first.duration, const Duration(seconds: 15));
  });

  test('legacy result remains visible and damaged runs are ignored', () {
    final legacy = jsonEncode({'at': run(0).at.toIso8601String(), 'trials': [trial.toHistoryJson()]});
    expect(decodeZapretHistory(null, legacy).single.trials.single.id, trial.id);
    expect(decodeZapretHistory(jsonEncode([run(1).toJson(), {'bad': true}]), legacy).single.at, run(1).at);
  });
}

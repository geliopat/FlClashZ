import 'dart:async';

import 'package:fl_clash/common/print.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/app.dart';
import 'package:fl_clash/providers/connection_statistics.dart';
import 'package:fl_clash/providers/core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockCore extends Mock implements CoreHandlerInterface {}

TrackerInfo _connection(String id, String protocol) => TrackerInfo(
  id: id,
  start: DateTime.utc(2026),
  metadata: Metadata(network: protocol),
  chains: const [],
  rule: 'MATCH',
  rulePayload: '',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('one polling loop serves multiple listeners and pauses hidden UI',
      (tester) async {
    final core = _MockCore();
    when(core.getConnections).thenAnswer((_) async =>
        [_connection('a', 'tcp'), _connection('b', 'udp')]);
    final container = ProviderContainer(overrides: [
      coreHandlerProvider.overrideWithValue(
          CoreController.scoped(core, snapshotMaxAge: Duration.zero)),
      coreStatusProvider.overrideWithBuild((_, _) => CoreStatus.connected),
    ]);
    try {
      final first = container.listen(connectionStatisticsProvider, (_, _) {});
      final second = container.listen(connectionStatisticsProvider, (_, _) {});
      await tester.pump();
      await tester.pump();
      verify(core.getConnections).called(1);
      expect(first.read().asData?.value?.snapshot.tcp, 1);
      expect(second.read().asData?.value?.snapshot.udp, 1);

      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      verify(core.getConnections).called(1);

      container.read(appVisibleProvider.notifier).value = false;
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      verifyNever(core.getConnections);
      expect(first.read().asData?.value, isNull);

      container.read(appVisibleProvider.notifier).value = true;
      await tester.pump();
      await tester.pump();
      verify(core.getConnections).called(1);

      first.close();
      second.close();
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      verifyNever(core.getConnections);
    } finally {
      container.dispose();
    }
  });

  testWidgets('a slow request does not overlap and an error recovers on next tick',
      (tester) async {
    final core = _MockCore();
    final pending = Completer<List<TrackerInfo>>();
    when(core.getConnections).thenAnswer((_) => pending.future);
    final container = ProviderContainer(overrides: [
      coreHandlerProvider.overrideWithValue(
          CoreController.scoped(core, snapshotMaxAge: Duration.zero)),
      coreStatusProvider.overrideWithBuild((_, _) => CoreStatus.connected),
    ]);
    commonPrint.applicationLogSinkForTesting = (_) {};
    try {
      final sub = container.listen(connectionStatisticsProvider, (_, _) {});
      await tester.pump();
      await tester.pump(const Duration(seconds: 3));
      verify(core.getConnections).called(1);
      pending.completeError(StateError('unavailable'));
      await tester.pump();
      await tester.pump();
      expect(sub.read().asData?.value, isNull);
      when(core.getConnections).thenAnswer((_) async => [_connection('new', 'udp')]);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      verify(core.getConnections).called(1);
      expect(sub.read().asData?.value?.snapshot.udp, 1);
      sub.close();
    } finally {
      commonPrint.applicationLogSinkForTesting = null;
      container.dispose();
    }
  });
}

import 'package:fl_clash/views/zapret_logs.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local crash history reads Mihomo without duplicating native Zapret logs', () {
    final log = parseLocalMihomoCrash('[2026-11-29T12:34:56.000] [ERROR] [Mihomo] core exited');
    expect(log?.level, 'error');
    expect(log?.message, 'core exited');
    expect(log?.time.year, 2026);
    expect(parseLocalMihomoCrash('[2026-11-29T12:34:56.000] [ERROR] [Zapret] engine exited'), isNull);
    expect(parseLocalMihomoCrash('[invalid] [ERROR] [Mihomo] core exited'), isNull);
    expect(parseLocalMihomoCrash('torn line'), isNull);
  });

  test('legacy recovery filter includes attempts and failures, not only successes', () {
    for (final message in [
      'Watchdog: engine exited',
      'Restart requested',
      'RECOVERY failed',
    ]) {
      expect(isRecoveryJournalMessage(message), isTrue);
    }
    for (final message in [
      'Engine started',
      'List download complete',
      'HTTP probe failed',
    ]) {
      expect(isRecoveryJournalMessage(message), isFalse);
    }
  });
}

import 'dart:io';

import 'package:fl_clash/common/windows_startup.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('startup registration is interactive and limited, never SYSTEM', () {
    const script = WindowsStartupTask.script;
    expect(script, contains('-LogonType Interactive -RunLevel Limited'));
    expect(script, contains('PT10S'));
    expect(script, contains('-RestartCount 3'));
    expect(script, contains('-MultipleInstances IgnoreNew'));
    expect(script, contains('Task ownership mismatch'));
    expect(script, isNot(contains('-RunLevel Highest')));
  });

  test('Windows scheduler creates, reconciles and removes an isolated task', () async {
    final task = WindowsStartupTask(
      name: 'FlClashZ-CI-$pid-${DateTime.now().millisecondsSinceEpoch}',
      executable: Platform.resolvedExecutable,
    );
    try {
      expect(await task.isEnabled(), isFalse);
      expect(await task.enable(), isTrue);
      expect(await task.isEnabled(), isTrue);
      expect(await task.enable(), isTrue);
      expect(await task.disable(), isTrue);
      expect(await task.isEnabled(), isFalse);
    } finally {
      await task.disable();
    }
  }, skip: !Platform.isWindows || Platform.environment['FLCLASHZ_TEST_STARTUP_TASK'] != '1');
}

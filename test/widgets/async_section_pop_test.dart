import 'dart:async';

import 'package:fl_clash/ui/pop_scope.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final accepted in [true, false]) {
    testWidgets('section close waits for confirmation ($accepted)', (tester) async {
      final key = GlobalKey<NavigatorState>();
      final gate = Completer<bool>();
      var asks = 0;
      await tester.pumpWidget(MaterialApp(
        navigatorKey: key,
        home: const Scaffold(body: Text('Root')),
      ));
      final route = MaterialPageRoute<void>(builder: (_) => CommonPopScope(
        onPop: (_) {
          asks++;
          return gate.future;
        },
        child: const Scaffold(body: Text('Editor')),
      ));
      unawaited(key.currentState!.push(route));
      await tester.pumpAndSettle();
      bool? first;
      bool? second;
      unawaited(maybePopAndWait(key.currentState!, route).then<void>((v) => first = v));
      await tester.pump();
      unawaited(maybePopAndWait(key.currentState!, route).then<void>((v) => second = v));
      await tester.pump();
      expect(asks, 1);
      expect(first, isNull);
      expect(second, isNull);
      gate.complete(accepted);
      await tester.pumpAndSettle();
      expect(first, accepted);
      expect(second, accepted);
      expect(find.text('Editor'), accepted ? findsNothing : findsOneWidget);
    });
  }
}

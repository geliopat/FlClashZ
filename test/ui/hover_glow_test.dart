import 'dart:ui' show PointerDeviceKind;
import 'package:fl_clash/ui/hover_glow.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('disabled glow and non-hover state produce no shadows', () {
    const color = Color(0xFF123456);
    expect(const HoverGlowTheme(0).shadows(color, hovered: true), isEmpty);
    expect(const HoverGlowTheme(1).shadows(color, hovered: false), isEmpty);
    final full = const HoverGlowTheme(1).shadows(color, hovered: true).single;
    final half = const HoverGlowTheme(.5).shadows(color, hovered: true).single;
    expect(half.blurRadius, full.blurRadius / 2);
    expect(half.color.a, closeTo(full.color.a / 2, .0001));
  });

  testWidgets('shared hover follows pointer, setting and enabled state', (tester) async {
    Widget scene(double intensity, bool enabled) => MaterialApp(
      theme: ThemeData(extensions: [HoverGlowTheme(intensity)]),
      home: Scaffold(body: Center(child: HoverGlowRegion(
        enabled: enabled,
        child: const SizedBox(width: 100, height: 60,
          child: Center(child: Text('Hover target'))),
      ))),
    );
    List<Shadow> shadows() => DefaultTextStyle.of(
      tester.element(find.text('Hover target')),
    ).style.shadows ?? const [];
    await tester.pumpWidget(scene(1, true));
    expect(shadows(), isEmpty);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Hover target')));
    addTearDown(mouse.removePointer);
    await tester.pump();
    expect(shadows(), isNotEmpty);
    await tester.pumpWidget(scene(0, true));
    expect(shadows(), isEmpty);
    await tester.pumpWidget(scene(1, false));
    expect(shadows(), isEmpty);
    await tester.pumpWidget(scene(1, true));
    expect(shadows(), isNotEmpty);
    await mouse.moveTo(Offset.zero);
    await tester.pump();
    expect(shadows(), isEmpty);
  });

  test('invalid intensity values cannot escape the supported range', () {
    expect(normalizeGlowIntensity(double.nan), defaultGlowIntensity);
    expect(normalizeGlowIntensity(null), defaultGlowIntensity);
    expect(normalizeGlowIntensity(-1), 0);
    expect(normalizeGlowIntensity(2), 1);
  });
}

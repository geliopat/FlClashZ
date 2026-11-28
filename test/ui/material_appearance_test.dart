import 'package:fl_clash/ui/button.dart';
import 'package:fl_clash/ui/material_appearance.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

void main() {
  test('legacy defaults preserve the original window overlay', () {
    expect(windowOverlayOpacity(MaterialEffect.mica, defaultMaterialAppearance), .2);
    expect(windowOverlayOpacity(MaterialEffect.acrylic, defaultMaterialAppearance), .32);
    expect(windowOverlayOpacity(MaterialEffect.none, defaultMaterialAppearance), 1);
    expect(defaultMaterialAppearance.card, isNull);
  });
  test('separate panes persist independently and invalid input is bounded', () {
    final value = decodeMaterialAppearance({
      'windowOpacity': 0, 'windowTint': 2,
      'card': {'effect': 'micaAlt', 'opacity': .4},
      'button': {'effect': 'acrylic', 'blur': 99, 'tint': -2},
    });
    expect(value.windowOpacity, 0);
    expect(value.windowTint, 1);
    expect(value.card!.effect, MaterialEffect.mica);
    expect(value.card!.opacity, .4);
    expect(selectableMaterialEffects, [
      MaterialEffect.none, MaterialEffect.mica, MaterialEffect.acrylic,
    ]);
    expect(value.button!.effect, MaterialEffect.acrylic);
    expect(value.button!.blur, 24);
    expect(value.button!.tint, 0);
    expect(decodeMaterialAppearance(encodeMaterialAppearance(value)), value);
  });
  testWidgets('local pane supplies a composited estimate to labels', (tester) async {
    Color? estimate;
    await tester.pumpWidget(MaterialApp(
      home: LocalMaterialPane(
        appearance: decodePane({'effect': 'mica', 'opacity': .5, 'tint': 0})!,
        color: const Color(0xFFFFFFFF),
        shape: const RoundedRectangleBorder(),
        child: Builder(builder: (context) {
          estimate = PaneBackdropEstimate.maybeOf(context);
          return const SizedBox(width: 20, height: 20);
        }),
      ),
    ));
    expect(estimate, isNotNull);
    expect(estimate!.a, 1);
  });
  testWidgets('button material applies to a group and a labelled action',
      (tester) async {
    final appearance = decodeMaterialAppearance({
      'button': {'effect': 'mica', 'opacity': .45},
    });
    var taps = 0;
    Widget build(MaterialAppearance settings) => MaterialApp(
      theme: ThemeData(extensions: [MaterialAppearanceTheme(settings)]),
      home: Scaffold(
        body: Column(
          children: [
            TonalButtonGroup(
              children: [
                IconButton(onPressed: () => taps++, icon: const Icon(Icons.add)),
                IconButton(onPressed: () {}, icon: const Icon(Icons.remove)),
              ],
            ),
            TonalButton(label: 'Action', onPressed: () => taps++),
          ],
        ),
      ),
    );
    await tester.pumpWidget(build(appearance));
    expect(find.byType(LocalMaterialPane), findsNWidgets(2));
    for (final pane in tester.widgetList<LocalMaterialPane>(
      find.byType(LocalMaterialPane),
    )) {
      expect(pane.appearance, appearance.button);
    }
    await tester.tap(find.byIcon(Icons.add));
    await tester.tap(find.text('Action'));
    expect(taps, 2);

    await tester.pumpWidget(build(defaultMaterialAppearance));
    expect(find.byType(LocalMaterialPane), findsNothing);
  });

  test('opaque stays opaque and acrylic respects local opacity', () {
    final scheme = ColorScheme.fromSeed(seedColor: Colors.blue);
    final opaque = paneColor(scheme.surface, scheme, defaultPaneAppearance);
    expect(opaque.a, 1);
    final pane = decodePane({'effect': 'acrylic', 'opacity': .4})!;
    expect(paneColor(scheme.surface, scheme, pane).a, closeTo(.4, .0001));
  });
}

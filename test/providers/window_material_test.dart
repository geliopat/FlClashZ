import 'package:fl_clash/providers/window_material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window/window.dart';

void main() {
  test('Windows exposes exactly opaque, Mica and Acrylic', () {
    expect(windowMaterials, [
      WindowEffect.none,
      WindowEffect.mica,
      WindowEffect.acrylic,
    ]);
    for (final effect in windowMaterials) {
      expect(parseWindowMaterial(effect.name), effect);
    }
    expect(parseWindowMaterial(null), WindowEffect.none);
    expect(parseWindowMaterial('micaAlt'), WindowEffect.mica);
    expect(parseWindowMaterial('blur'), WindowEffect.none);
  });
}

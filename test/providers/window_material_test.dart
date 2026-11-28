import 'package:fl_clash/providers/window_material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:window/window.dart';

void main() {
  test('Windows exposes exactly opaque, Mica, Mica Alt and Acrylic', () {
    expect(windowMaterials, [
      WindowEffect.none,
      WindowEffect.mica,
      WindowEffect.micaAlt,
      WindowEffect.acrylic,
    ]);
    for (final effect in windowMaterials) {
      expect(parseWindowMaterial(effect.name), effect);
    }
    expect(parseWindowMaterial(null), WindowEffect.none);
    expect(parseWindowMaterial('micaAlt'), WindowEffect.micaAlt);
    expect(parseWindowMaterial('blur'), WindowEffect.none);
  });
}

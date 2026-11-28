import 'dart:ui' show ImageFilter;

import 'package:material_ui/material_ui.dart';

/// Visual material requested by the Flutter scene, independent of native DWM.
enum MaterialEffect { none, mica, micaAlt, acrylic }

enum AppearanceSurface { window, card, button }

typedef PaneAppearance = ({
  MaterialEffect effect,
  double opacity,
  double blur,
  double tint,
});

typedef MaterialAppearance = ({
  double? windowOpacity,
  double windowTint,
  PaneAppearance? card,
  PaneAppearance? button,
});

const MaterialAppearance defaultMaterialAppearance = (
  windowOpacity: null,
  windowTint: 0.0,
  card: null,
  button: null,
);

const PaneAppearance defaultPaneAppearance = (
  effect: MaterialEffect.none,
  opacity: .85,
  blur: 12.0,
  tint: .12,
);

double appearanceNumber(Object? raw, double fallback, double max) =>
    raw is num && raw.isFinite ? raw.toDouble().clamp(0.0, max).toDouble() : fallback;

MaterialEffect paneEffect(Object? raw) => switch (raw) {
  'mica' => MaterialEffect.mica,
  'micaAlt' => MaterialEffect.micaAlt,
  'acrylic' => MaterialEffect.acrylic,
  _ => MaterialEffect.none,
};

PaneAppearance? decodePane(Object? raw) {
  if (raw is! Map) return null;
  return (
    effect: paneEffect(raw['effect']),
    opacity: appearanceNumber(raw['opacity'], .85, 1),
    blur: appearanceNumber(raw['blur'], 12, 24),
    tint: appearanceNumber(raw['tint'], .12, 1),
  );
}

MaterialAppearance decodeMaterialAppearance(Map<String, Object?> raw) => (
  windowOpacity: raw['windowOpacity'] is num
      ? appearanceNumber(raw['windowOpacity'], .2, 1)
      : null,
  windowTint: appearanceNumber(raw['windowTint'], 0, 1),
  card: decodePane(raw['card']),
  button: decodePane(raw['button']),
);

Map<String, Object?> encodeMaterialAppearance(MaterialAppearance value) {
  Object? pane(PaneAppearance? p) => p == null ? null : {
    'effect': p.effect.name, 'opacity': p.opacity, 'blur': p.blur, 'tint': p.tint,
  };
  return {
    'windowOpacity': value.windowOpacity,
    'windowTint': value.windowTint,
    'card': pane(value.card), 'button': pane(value.button),
  };
}

double windowOverlayOpacity(MaterialEffect effect, MaterialAppearance settings) =>
    effect == MaterialEffect.none ? 1 : settings.windowOpacity ??
        (effect == MaterialEffect.acrylic ? .32 : .20);

/// Local panes emulate the selected material within the Flutter scene. They
/// are not separate DWM backdrops and cannot sample the desktop independently.
Color paneColor(Color base, ColorScheme scheme, PaneAppearance appearance) {
  if (appearance.effect == MaterialEffect.none) return base.withValues(alpha: 1);
  final tintStrength = appearance.tint *
      (appearance.effect == MaterialEffect.micaAlt ? .30 : .15);
  return Color.lerp(base.withValues(alpha: 1), scheme.primary, tintStrength)!
      .withValues(alpha: appearance.opacity);
}

class MaterialAppearanceTheme extends ThemeExtension<MaterialAppearanceTheme> {
  const MaterialAppearanceTheme(this.settings);
  final MaterialAppearance settings;

  static MaterialAppearanceTheme? of(BuildContext context) =>
      Theme.of(context).extension<MaterialAppearanceTheme>();

  PaneAppearance? pane(AppearanceSurface surface) => switch (surface) {
    AppearanceSurface.window => null,
    AppearanceSurface.card => settings.card,
    AppearanceSurface.button => settings.button,
  };

  @override
  MaterialAppearanceTheme copyWith({MaterialAppearance? settings}) =>
      MaterialAppearanceTheme(settings ?? this.settings);

  @override
  MaterialAppearanceTheme lerp(MaterialAppearanceTheme? other, double t) =>
      other == null || t < .5 ? this : other;

  @override
  bool operator ==(Object other) =>
      other is MaterialAppearanceTheme && settings == other.settings;

  @override
  int get hashCode => settings.hashCode;
}

/// Use the same contrast calculation for semantic text and local material
/// estimates. Native DWM pixels are not available to Flutter.
double foregroundContrast(Color foreground, Color background) {
  final a = Color.alphaBlend(foreground, background).computeLuminance();
  final b = background.computeLuminance();
  return a > b ? (a + .05) / (b + .05) : (b + .05) / (a + .05);
}

/// Preserve the preferred hue when possible, moving only toward the
/// higher-contrast neutral endpoint. Intended for enabled text, not disabled
/// controls whose dimming is a separate semantic state.
Color readableForeground(Color preferred, Color background) {
  if (foregroundContrast(preferred, background) >= 4.5) return preferred;
  final target = foregroundContrast(Colors.white, background) >=
      foregroundContrast(Colors.black, background) ? Colors.white : Colors.black;
  var lo = 0.0;
  var hi = 1.0;
  for (var i = 0; i < 16; i++) {
    final mid = (lo + hi) / 2;
    if (foregroundContrast(Color.lerp(preferred, target, mid)!, background) >= 4.5) {
      hi = mid;
    } else {
      lo = mid;
    }
  }
  final result = Color.lerp(preferred, target, hi)!;
  return foregroundContrast(result, background) >= 4.5 ? result : target;
}

Color estimatedBackdrop(ColorScheme scheme, Color surface) =>
    Color.alphaBlend(surface, scheme.brightness == Brightness.dark
        ? const Color(0xFF181818) : const Color(0xFFF5F5F5));

/// Estimated effective pane color for semantic labels. DWM pixels are
/// deliberately not represented as measured values.
class PaneBackdropEstimate extends InheritedWidget {
  const PaneBackdropEstimate({super.key, required this.color, required super.child});
  final Color color;

  static Color? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PaneBackdropEstimate>()?.color;

  @override
  bool updateShouldNotify(PaneBackdropEstimate oldWidget) => oldWidget.color != color;
}

/// Use a single implementation for settings samples and real controls.
class LocalMaterialPane extends StatelessWidget {
  const LocalMaterialPane({
    super.key, required this.appearance, required this.color,
    required this.shape, required this.child,
  });

  final PaneAppearance appearance;
  final Color color;
  final OutlinedBorder shape;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fill = paneColor(color, scheme, appearance);
    final behind = PaneBackdropEstimate.maybeOf(context) ??
        estimatedBackdrop(scheme, scheme.surface);
    final content = DecoratedBox(
      decoration: ShapeDecoration(color: fill, shape: shape),
      child: PaneBackdropEstimate(
        color: Color.alphaBlend(fill, behind),
        child: child,
      ),
    );
    // Avoid a backdrop filter for Mica-like layers, fully opaque panes or
    // zero blur. BackdropFilter is clipped to the pane, not the whole window.
    if (appearance.effect != MaterialEffect.acrylic ||
        appearance.blur == 0 || fill.a == 1) {
      return content;
    }
    return ClipPath(
      clipper: ShapeBorderClipper(shape: shape, textDirection: Directionality.of(context)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: appearance.blur, sigmaY: appearance.blur),
        child: content,
      ),
    );
  }
}

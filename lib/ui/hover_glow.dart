import 'package:material_ui/material_ui.dart';

const defaultGlowIntensity = 1.0;

double normalizeGlowIntensity(double? value) =>
    value == null || !value.isFinite
        ? defaultGlowIntensity
        : value.clamp(0.0, 1.0).toDouble();

/// The same hover treatment for all consumers, with independent keyboard focus.
class HoverGlowTheme extends ThemeExtension<HoverGlowTheme> {
  const HoverGlowTheme(this.intensity);

  final double intensity;

  static HoverGlowTheme of(BuildContext context) =>
      Theme.of(context).extension<HoverGlowTheme>() ??
      const HoverGlowTheme(defaultGlowIntensity);

  List<Shadow> shadows(Color color, {required bool hovered}) {
    final strength = normalizeGlowIntensity(intensity);
    if (!hovered || strength == 0) return const [];
    return [
      Shadow(
        color: color.withValues(alpha: color.a * .75 * strength),
        blurRadius: 6 * strength,
      ),
    ];
  }

  @override
  HoverGlowTheme copyWith({double? intensity}) =>
      HoverGlowTheme(intensity ?? this.intensity);

  @override
  HoverGlowTheme lerp(HoverGlowTheme? other, double t) =>
      other == null ? this : HoverGlowTheme(intensity + (other.intensity - intensity) * t);

  @override
  bool operator ==(Object other) =>
      other is HoverGlowTheme && other.intensity == intensity;

  @override
  int get hashCode => intensity.hashCode;
}


/// Shared text/icon treatment, independent of focus rings and surface fill.
Widget hoverGlowForeground(BuildContext context, Widget child, {
  required bool hovered,
}) {
  final shadows = HoverGlowTheme.of(context).shadows(
    Theme.of(context).colorScheme.primary, hovered: hovered,
  );
  return IconTheme.merge(
    data: IconThemeData(shadows: shadows),
    child: DefaultTextStyle.merge(
      style: TextStyle(shadows: shadows), child: child,
    ),
  );
}

/// For interactive surfaces without a ButtonStyle state builder.
class HoverGlowRegion extends StatefulWidget {
  const HoverGlowRegion({super.key, required this.child, this.enabled = true});
  final Widget child;
  final bool enabled;

  @override
  State<HoverGlowRegion> createState() => _HoverGlowRegionState();
}

class _HoverGlowRegionState extends State<HoverGlowRegion> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    opaque: false,
    onEnter: (_) => setState(() => _hovered = true),
    onExit: (_) => setState(() => _hovered = false),
    child: hoverGlowForeground(context, widget.child,
      hovered: widget.enabled && _hovered),
  );
}

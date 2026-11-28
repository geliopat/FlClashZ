import 'package:fl_clash/ui/color.dart';
import 'package:material_ui/material_ui.dart';

/// Windows modal panels separate themselves by dimming the uncovered area,
/// rather than drawing a border, elevation shadow or contrasting chrome.
const windowsPanelDim = .15;

Color panelScrimOf(BuildContext context) {
  final theme = Theme.of(context);
  return theme.platform == TargetPlatform.windows
      ? const Color(0xFF000000).withValues(alpha: windowsPanelDim)
      : theme.colorScheme.modalScrim;
}

/// Use the same theme RGB as the workspace. A modal layer must conceal the
/// controls behind it; native DWM cannot be sampled independently per pane.
Color panelSurfaceOf(ColorScheme scheme) =>
    SurfaceLevel.page.colorOf(scheme).withValues(alpha: 1);

/// Floating menus use an opaque, slightly raised theme surface on Windows.
/// Unlike a modal panel, a menu does not need to dim the entire workspace.
Color popupSurfaceOf(BuildContext context) {
  final theme = Theme.of(context);
  final fill = SurfaceLevel.floatingOf(theme.colorScheme).colorOf(theme.colorScheme);
  return theme.platform == TargetPlatform.windows ? fill.withValues(alpha: 1) : fill;
}

/// `.agents/surfaces.md` explains the levels and why dark mode never steps
/// back down.
enum SurfaceLevel {
  page,
  card,
  block,
  inset;

  static SurfaceLevel floatingOf(ColorScheme colorScheme) =>
      colorScheme.brightness == Brightness.dark ? block : card;

  SurfaceLevel get next => switch (this) {
    page => card,
    card => block,
    block || inset => inset,
  };

  Color colorOf(ColorScheme colorScheme) {
    final dark = colorScheme.brightness == Brightness.dark;
    return switch (this) {
      page => dark ? colorScheme.surface : colorScheme.surfaceContainer,
      card => dark ? colorScheme.surfaceContainer : colorScheme.surfaceBright,
      block =>
        dark ? colorScheme.surfaceContainerHigh : colorScheme.surfaceContainer,
      inset => colorScheme.surfaceContainerHighest,
    };
  }
}

class SurfaceScope extends StatelessWidget {
  const SurfaceScope({super.key, required this.level, required this.child});

  final SurfaceLevel level;
  final Widget child;

  static SurfaceLevel of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_SurfaceLevelScope>()?.level ??
      SurfaceLevel.page;

  @override
  Widget build(BuildContext context) {
    return _SurfaceLevelScope(level: level, child: child);
  }
}

class _SurfaceLevelScope extends InheritedWidget {
  const _SurfaceLevelScope({required this.level, required super.child});

  final SurfaceLevel level;

  @override
  bool updateShouldNotify(_SurfaceLevelScope oldWidget) =>
      level != oldWidget.level;
}

extension SurfaceContext on BuildContext {
  SurfaceLevel get surfaceLevel => SurfaceScope.of(this);

  SurfaceLevel get raisedSurfaceLevel => surfaceLevel.next;
}

extension ChromeSurfaceExt on ColorScheme {
  Color get chromeSurface => surface.a < 1
      ? SurfaceLevel.page.colorOf(this)
      : brightness == Brightness.dark
      ? surfaceContainerLow
      : surfaceContainerHighest;
}

extension ElevatedSurfaceExt on ColorScheme {
  ColorScheme get elevated {
    if (brightness != Brightness.dark) {
      return this;
    }
    final lift = surfaceContainer.tone - surface.tone;
    Color raise(Color color) => color.shiftTone(lift);
    return copyWith(
      surface: surfaceContainer,
      surfaceDim: raise(surfaceDim),
      surfaceBright: raise(surfaceBright),
      surfaceContainerLowest: raise(surfaceContainerLowest),
      surfaceContainerLow: raise(surfaceContainerLow),
      surfaceContainer: surfaceContainerHigh,
      surfaceContainerHigh: surfaceContainerHighest,
      surfaceContainerHighest: surfaceContainerHighest.shiftTone(
        surfaceContainerHighest.tone - surfaceContainerHigh.tone,
      ),
    );
  }
}

/// The scheme sheets present with; `.agents/surfaces.md` has the reason.
class ElevatedColorScheme extends ThemeExtension<ElevatedColorScheme> {
  const ElevatedColorScheme(this.colorScheme);

  final ColorScheme colorScheme;

  @override
  ElevatedColorScheme copyWith({ColorScheme? colorScheme}) =>
      ElevatedColorScheme(colorScheme ?? this.colorScheme);

  @override
  ElevatedColorScheme lerp(ElevatedColorScheme? other, double t) =>
      other == null
      ? this
      : ElevatedColorScheme(
          ColorScheme.lerp(colorScheme, other.colorScheme, t),
        );
}

class ElevatedSurfaceTheme extends StatelessWidget {
  const ElevatedSurfaceTheme({super.key, required this.child});

  final Widget child;

  static bool isIn(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_ElevatedSurfaceScope>() != null;

  @override
  Widget build(BuildContext context) {
    return _ElevatedSurfaceScope(
      child: Theme(data: Theme.of(context).elevated, child: child),
    );
  }
}

class _ElevatedSurfaceScope extends InheritedWidget {
  const _ElevatedSurfaceScope({required super.child});

  @override
  bool updateShouldNotify(_ElevatedSurfaceScope oldWidget) => false;
}

extension AppSurfaceThemeExt on ThemeData {
  ThemeData get elevated {
    final scheme = extension<ElevatedColorScheme>()?.colorScheme;
    if (scheme == null) {
      return this;
    }
    return copyWith(
      colorScheme: scheme,
      canvasColor: scheme.surface,
    ).withAppSurfaces;
  }

  ThemeData get withAppSurfaces {
    final page = SurfaceLevel.page.colorOf(colorScheme);
    final card = SurfaceLevel.card.colorOf(colorScheme);
    final floatingLevel = SurfaceLevel.floatingOf(colorScheme);
    final floating = floatingLevel.colorOf(colorScheme);
    final ring = focusRingStyle(colorScheme);
    final standingRing = focusRingStyle(colorScheme, standsOff: true);
    return copyWith(
      dividerTheme: dividerTheme.copyWith(
        color: colorScheme.onSurface.withValues(alpha: 0.14),
      ),
      scaffoldBackgroundColor: page,
      cardTheme: cardTheme.copyWith(color: card, elevation: 0),
      dialogTheme: dialogTheme.copyWith(
        backgroundColor: platform == TargetPlatform.windows
            ? panelSurfaceOf(colorScheme) : floating,
        elevation: platform == TargetPlatform.windows ? 0 : null,
        shadowColor: platform == TargetPlatform.windows ? Colors.transparent : null,
        surfaceTintColor: platform == TargetPlatform.windows ? Colors.transparent : null,
      ),
      popupMenuTheme: popupMenuTheme.copyWith(
        color: platform == TargetPlatform.windows ? floating.withValues(alpha: 1) : floating,
        elevation: platform == TargetPlatform.windows ? 0 : null,
        shadowColor: platform == TargetPlatform.windows ? Colors.transparent : null,
        surfaceTintColor: platform == TargetPlatform.windows ? Colors.transparent : null,
      ),
      menuTheme: MenuThemeData(
        style: (menuTheme.style ?? const MenuStyle()).copyWith(
          backgroundColor: WidgetStatePropertyAll(floating),
        ),
      ),
      navigationBarTheme: navigationBarTheme.copyWith(
        backgroundColor: floating,
        indicatorColor: floatingLevel.next.colorOf(colorScheme),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color: states.contains(WidgetState.selected)
                ? colorScheme.primary
                : colorScheme.onSurfaceVariant,
          ),
        ),
      ),
      bottomSheetTheme: bottomSheetTheme.copyWith(
        backgroundColor: page,
        modalBackgroundColor: page,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: standingRing.merge(filledButtonTheme.style),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ring.merge(textButtonTheme.style),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ring.merge(outlinedButtonTheme.style),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: ring.merge(iconButtonTheme.style),
      ),
    );
  }
}

const _focusRingWidth = 2.0;
const _focusRingGap = 1.0;

/// The focus ring of `.agents/surfaces.md`; one that [standsOff] clears the
/// edge, which a primary fill or a button's own glass would hide it on.
BorderSide focusRingSide(ColorScheme colorScheme, {bool standsOff = false}) =>
    BorderSide(
      color: colorScheme.primary,
      width: _focusRingWidth,
      strokeAlign: standsOff
          ? 1 + 2 * _focusRingGap / _focusRingWidth
          : BorderSide.strokeAlignInside,
    );

ButtonStyle focusRingStyle(ColorScheme colorScheme, {bool standsOff = false}) =>
    ButtonStyle(
      side: WidgetStateProperty<BorderSide?>.fromMap({
        WidgetState.focused: focusRingSide(colorScheme, standsOff: standsOff),
      }),
    );

/// [focusRingSide] on [shape] while focus is in [child], for ink not a button.
class FocusRing extends StatefulWidget {
  const FocusRing({
    super.key,
    required this.shape,
    this.standsOff = false,
    required this.child,
  });

  final OutlinedBorder shape;
  final bool standsOff;
  final Widget child;

  @override
  State<FocusRing> createState() => _FocusRingState();
}

class _FocusRingState extends State<FocusRing> {
  var _focused = false;

  void _handleFocusChange(bool focused) {
    if (focused != _focused) {
      setState(() => _focused = focused);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Focus(
      canRequestFocus: false,
      skipTraversal: true,
      includeSemantics: false,
      onFocusChange: _handleFocusChange,
      child: DecoratedBox(
        position: DecorationPosition.foreground,
        decoration: ShapeDecoration(
          shape: widget.shape.copyWith(
            side: _focused
                ? focusRingSide(
                    Theme.of(context).colorScheme,
                    standsOff: widget.standsOff,
                  )
                : BorderSide.none,
          ),
        ),
        child: widget.child,
      ),
    );
  }
}

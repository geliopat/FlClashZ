import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/material_appearance.dart';
import 'package:fl_clash/ui/hover_glow.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:material_ui/material_ui.dart';

const engineControlHeight = 53.0;
const engineControlWidthFraction = .28;
const vpnControlCenterFraction = .3083333333333333;
const zapretControlCenterFraction = 1 - vpnControlCenterFraction;

/// Coordinates refer to the workspace, not the screen or a grid column.
class EngineControlsLayout extends StatelessWidget {
  const EngineControlsLayout({super.key, required this.vpn, this.zapret});
  final Widget vpn;
  final Widget? zapret;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: engineControlHeight,
    child: LayoutBuilder(builder: (context, constraints) {
      final width = constraints.maxWidth;
      final buttonWidth = width * engineControlWidthFraction;
      Widget at(Widget child, double center, String key) => Positioned(
        key: ValueKey(key),
        left: width * center - buttonWidth / 2,
        top: 0, width: buttonWidth, height: engineControlHeight,
        child: child,
      );
      return Stack(children: [
        at(vpn, zapret == null ? .5 : vpnControlCenterFraction, 'vpn-control-slot'),
        if (zapret != null) at(zapret!, zapretControlCenterFraction, 'zapret-control-slot'),
      ]);
    }),
  );
}

String engineUptime(bool running, int? milliseconds) =>
    getTimeText(running && milliseconds != null && milliseconds >= 0 ? milliseconds : null);

/// Always paint a material, whether the engine is stopped or running.
/// Hover changes foreground only; keyboard focus stays visible.
class EngineControlButton extends StatefulWidget {
  const EngineControlButton({
    super.key, required this.name, required this.actionLabel,
    required this.running, required this.elapsedMilliseconds,
    required this.onPressed, this.busy = false, this.suspended = false,
    this.error,
  });
  final String name;
  final String actionLabel;
  final bool running;
  final int? elapsedMilliseconds;
  final VoidCallback? onPressed;
  final bool busy;
  final bool suspended;
  final String? error;

  @override
  State<EngineControlButton> createState() => _EngineControlButtonState();
}

class _EngineControlButtonState extends State<EngineControlButton> {
  bool _hovered = false;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final appearance = MaterialAppearanceTheme.of(context)?.pane(AppearanceSurface.button)
        ?? defaultPaneAppearance;
    final background = SurfaceLevel.card.colorOf(scheme);
    final enabled = widget.onPressed != null && !widget.busy;
    final ink = enabled ? (widget.running ? scheme.primary : scheme.onSurface)
        : scheme.onSurfaceVariant;
    final shadows = HoverGlowTheme.of(context).shadows(ink, hovered: enabled && _hovered);
    final uptime = engineUptime(widget.running, widget.elapsedMilliseconds);
    return SizedBox(
      height: engineControlHeight,
      width: double.infinity,
      child: Tooltip(
        message: widget.error ?? widget.actionLabel,
        child: Semantics(
          button: true, enabled: enabled,
          label: '${widget.name} · ${widget.actionLabel}', value: uptime,
          child: LocalMaterialPane(
            appearance: appearance,
            color: background,
            shape: AppShape.full,
            child: Material(
              type: MaterialType.transparency,
              child: InkWell(
                key: ValueKey('engine-toggle-${widget.name}'),
                customBorder: AppShape.full,
                onTap: enabled ? widget.onPressed : null,
                onHover: (value) => setState(() => _hovered = value),
                onFocusChange: (value) => setState(() => _focused = value),
                overlayColor: const WidgetStatePropertyAll(Colors.transparent),
                splashFactory: NoSplash.splashFactory,
                mouseCursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.basic,
                child: DecoratedBox(
                  decoration: ShapeDecoration(
                    shape: _focused ? AppShape.full.copyWith(side: BorderSide(color: scheme.primary, width: 2))
                        : AppShape.full,
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          spacing: 8,
                          children: [
                            IconTheme.merge(
                              data: IconThemeData(color: ink, shadows: shadows),
                              child: widget.busy
                                  ? SizedBox.square(dimension: 18, child: CommonCircleLoading(size: 18, color: ink))
                                  : GlyphIcon(widget.suspended ? AppGlyphs.wifiOff
                                      : widget.running ? AppGlyphs.engineStop : AppGlyphs.enginePlay,
                                      size: 24, fill: 0),
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(widget.name, style: AppTextStyle.caption1.of(context, emphasized: true)
                                  .copyWith(color: ink, shadows: shadows)),
                                Text(uptime, style: AppTextStyle.callout.of(context)
                                  .copyWith(color: ink, fontFeatures: const [FontFeature.tabularFigures()],
                                  shadows: shadows)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

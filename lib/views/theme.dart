import 'package:fl_clash/ui/material_appearance.dart';
import 'dart:async';
import 'dart:math';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/config.dart';
import 'package:fl_clash/providers/action.dart';
import 'package:fl_clash/providers/state.dart';
import 'package:fl_clash/providers/window_material.dart';
import 'package:fl_clash/providers/appearance.dart';
import 'package:fl_clash/providers/material_appearance.dart';
import 'package:fl_clash/ui/hover_glow.dart';
import 'package:fl_clash/ui/network_palette.dart';
import 'package:window/window.dart' show WindowEffect;
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/views/font_family.dart';
import 'package:fl_clash/views/theme_preview.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ThemeView extends StatelessWidget {
  const ThemeView({super.key});

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    return BaseScaffold(
      title: appLocalizations.theme,
      body: ListView(
        padding: EdgeInsets.only(
          top: context.appBarInset,
          bottom: 32 + context.bottomInset,
        ),
        children: [
          const ThemeLivePreview(),
          const SizedBox(height: 16),
          const ManagedSettingsHint(keys: themePageKeys),
          if (system.isWindows && !safeModeBuild) ...const [
            _WindowMaterialItem(),
            _SurfaceAppearanceItem(AppearanceSurface.window),
            _SurfaceAppearanceItem(AppearanceSurface.card),
            _SurfaceAppearanceItem(AppearanceSurface.button),
            SizedBox(height: 8),
            _WindowMaterialPreview(),
            SizedBox(height: 16),
            _GlowIntensityItem(),
            SizedBox(height: 16),
          ],
          const ManagedSetting(
            settingKey: 'view.app.theme',
            child: _ThemeModeItem(),
          ),
          const SizedBox(height: 16),
          const ManagedSetting(
            settingKey: 'view.app.black',
            child: _PureBlackItem(),
          ),
          const SizedBox(height: 16),
          const ManagedSetting(
            settingKey: 'view.app.color',
            child: _PrimaryColorItem(key: ValueKey('theme-primary-color')),
          ),
          const SizedBox(height: 16),
          const ManagedSetting(
            settingKey: 'view.app.navbar',
            child: _NavigationBarItem(),
          ),
          const SizedBox(height: 16),
          const ManagedSetting(
            settingKey: 'view.app.tabs',
            child: _TabAnimationItem(),
          ),
          const SizedBox(height: 16),
          const ManagedSetting(
            settingKey: 'view.app.glass',
            child: _LiquidGlassItem(),
          ),
          const SizedBox(height: 16),
          if (system.isAndroid) ...const [
            ManagedSetting(
              settingKey: vibrationSetting,
              child: _VibrationItem(),
            ),
            SizedBox(height: 16),
          ],
          const ManagedSetting(settingKey: hideIpSetting, child: _HideIpItem()),
          const SizedBox(height: 16),
          const _FontFamilyItem(key: ValueKey('theme-font-family')),
          const SizedBox(height: 16),
          const _TextScaleFactorItem(key: ValueKey('theme-text-scale')),
        ],
      ),
    );
  }
}

class _WindowMaterialItem extends ConsumerWidget {
  const _WindowMaterialItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference = ref.watch(windowMaterialPreferenceProvider);
    final actual = ref.watch(windowMaterialProvider);
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final selected = preference.value ?? WindowEffect.none;
    String label(WindowEffect effect) => switch (effect) {
      WindowEffect.mica => 'Mica',
      WindowEffect.micaAlt => 'Mica Alt',
      WindowEffect.acrylic => 'Acrylic',
      _ => ru ? 'Без прозрачности' : 'Opaque',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ListItem<WindowEffect>.options(
        leading: const GlyphIcon(AppGlyphs.liquidGlass),
        title: Text(ru ? 'Материал окна' : 'Window material'),
        subtitle: actual.hasValue && actual.value != selected
            ? Text(ru ? 'Эффект недоступен: непрозрачный фон' :
                'Effect unavailable: opaque fallback')
            : null,
        options: windowMaterials,
        value: selected,
        textBuilder: label,
        onChanged: (value) async {
          try {
            await saveWindowMaterial(ref, value);
          } catch (error) {
            if (context.mounted) {
              dialogs.showNotifier(error.toString(), level: MessageLevel.error);
            }
          }
        },
      ),
    );
  }
}

class _SurfaceAppearanceItem extends ConsumerWidget {
  const _SurfaceAppearanceItem(this.surface);
  final AppearanceSurface surface;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(materialAppearanceProvider);
    final controller = ref.read(materialAppearanceProvider.notifier);
    final window = surface == AppearanceSurface.window;
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final stored = surface == AppearanceSurface.card ? settings.card : settings.button;
    final pane = stored ?? defaultPaneAppearance;
    final native = window
        ? paneEffect(ref.watch(windowMaterialPreferenceProvider).value?.name)
        : pane.effect;
    String label(MaterialEffect e) => switch (e) {
      MaterialEffect.mica => 'Mica',
      MaterialEffect.micaAlt => 'Mica Alt',
      MaterialEffect.acrylic => 'Acrylic',
      _ => ru ? 'Без прозрачности' : 'Opaque',
    };
    MaterialAppearance updatePane(PaneAppearance? value) => (
      windowOpacity: settings.windowOpacity,
      windowTint: settings.windowTint,
      card: surface == AppearanceSurface.card ? value : settings.card,
      button: surface == AppearanceSurface.button ? value : settings.button,
    );
    MaterialAppearance updateWindow({double? opacity, double? tint, bool reset = false}) => (
      windowOpacity: reset ? null : opacity ?? settings.windowOpacity,
      windowTint: reset ? 0.0 : tint ?? settings.windowTint,
      card: settings.card, button: settings.button,
    );
    Future<void> save(MaterialAppearance value) async {
      try {
        await controller.save(value);
      } catch (error) {
        if (context.mounted) dialogs.showNotifier(error.toString(), level: MessageLevel.error);
      }
    }
    Widget control(String name, double value, double max, MaterialAppearance Function(double) change) =>
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('$name: ${max == 1 ? '${(value * 100).round()}%' : value.round()}'),
        SliderTheme(
          data: SliderDefaultsM3(context),
          child: Slider(
            value: value, max: max, divisions: max == 1 ? 20 : 24,
            onChanged: (value) => controller.preview(change(value)),
            onChangeEnd: (value) => unawaited(save(change(value))),
          ),
        ),
      ]);
    final heading = switch (surface) {
      AppearanceSurface.window => ru ? 'Параметры окна' : 'Window parameters',
      AppearanceSurface.card => ru ? 'Материал карточек' : 'Card material',
      AppearanceSurface.button => ru ? 'Материал кнопок' : 'Button material',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Row(children: [
          Expanded(child: Text(heading)),
          _ResetButton(onPressed: () => unawaited(save(
            window ? updateWindow(reset: true) : updatePane(null),
          ))),
        ]),
        if (!window)
          ListItem<MaterialEffect>.options(
            title: Text(ru ? 'Материал' : 'Material'),
            subtitle: stored == null ? Text(ru ? 'Исходное оформление' : 'Original appearance') : null,
            options: MaterialEffect.values, value: pane.effect, textBuilder: label,
            onChanged: (effect) => unawaited(save(updatePane((
              effect: effect, opacity: pane.opacity, blur: pane.blur, tint: pane.tint,
            )))),
          ),
        if (native != MaterialEffect.none) ...[
          control(ru ? 'Непрозрачность' : 'Opacity',
            window ? windowOverlayOpacity(native, settings) : pane.opacity, 1,
            (v) => window ? updateWindow(opacity: v) : updatePane((
              effect: pane.effect, opacity: v, blur: pane.blur, tint: pane.tint,
            ))),
          control(ru ? 'Оттенок' : 'Tint',
            window ? settings.windowTint : pane.tint, 1,
            (v) => window ? updateWindow(tint: v) : updatePane((
              effect: pane.effect, opacity: pane.opacity, blur: pane.blur, tint: v,
            ))),
          if (!window && native == MaterialEffect.acrylic)
            control(ru ? 'Размытие' : 'Blur', pane.blur, 24,
              (v) => updatePane((
                effect: pane.effect, opacity: pane.opacity, blur: v, tint: pane.tint,
              ))),
        ],
        if (window)
          Text(ru ? 'Размытие системного материала задаёт Windows.'
              : 'Windows controls the native material blur.', style: context.listCaptionStyle),
      ]),
    );
  }
}

class _WindowMaterialPreview extends ConsumerWidget {
  const _WindowMaterialPreview();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actual = ref.watch(windowMaterialProvider);
    final effect = actual.value ?? WindowEffect.none;
    final scheme = context.colorScheme;
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final label = switch (effect) {
      WindowEffect.mica => 'Mica',
      WindowEffect.micaAlt => 'Mica Alt',
      WindowEffect.acrylic => 'Acrylic',
      _ => ru ? 'Без прозрачности' : 'Opaque',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        spacing: 8,
        children: [
          Text('${ru ? 'Предпросмотр' : 'Preview'} · $label',
            style: context.listCaptionStyle),
          // The selected native effect is applied to the real window. This
          // example uses its actual Flutter theme, not a simulated DWM panel.
          SurfaceScope(
            level: SurfaceLevel.card,
            child: Builder(builder: (context) => LocalMaterialPane(
              appearance: MaterialAppearanceTheme.of(context)?.pane(AppearanceSurface.card)
                  ?? defaultPaneAppearance,
              color: SurfaceLevel.card.colorOf(scheme),
              shape: AppShape.xl,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: 12,
                  children: [
                    Text(ru ? 'Соединения' : 'Connections',
                        style: AppTextStyle.headline.of(context)),
                    Wrap(
                      spacing: 16, runSpacing: 8,
                      children: [
                        for (final (label, tone) in [
                          ('TCP', NetworkTone.tcp), ('UDP', NetworkTone.udp),
                          ('DIRECT', NetworkTone.direct), ('REJECT', NetworkTone.reject),
                          ('PROXY', NetworkTone.proxy), ('↓ 12 MB/s', NetworkTone.download),
                          ('↑ 2 MB/s', NetworkTone.upload), ('0 B/s', NetworkTone.inactive),
                        ]) Text(label, style: TextStyle(color: tone.of(context))),
                      ],
                    ),
                    TonalButtonTheme(
                      child: Row(
                        spacing: 8,
                        children: [
                          IconButton(
                            onPressed: () {},
                            tooltip: ru ? 'Пример кнопки' : 'Example button',
                            icon: const GlyphIcon(AppGlyphs.refresh),
                          ),
                          Expanded(child: Text(ru ? 'Наведите курсор для проверки свечения'
                              : 'Hover over the button to check the glow')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
          ),
          Text(ru ? 'Окно использует DWM; карточки и кнопки воспроизводят эффект внутри Flutter.'
              : 'The window uses DWM; cards and buttons reproduce the effect within Flutter.',
              style: context.listCaptionStyle),
        ],
      ),
    );
  }
}

class _GlowIntensityItem extends ConsumerWidget {
  const _GlowIntensityItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final value = ref.watch(glowIntensityProvider);
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    Future<void> save(double value) async {
      try {
        await ref.read(glowIntensityProvider.notifier).save(value);
      } catch (error) {
        if (context.mounted) {
          dialogs.showNotifier(error.toString(), level: MessageLevel.error);
        }
      }
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(children: [
            Expanded(child: Text(ru ? 'Интенсивность свечения' : 'Glow intensity')),
            Text('${(value * 100).round()}%'),
            _ResetButton(onPressed: () => unawaited(save(defaultGlowIntensity))),
          ]),
          SliderTheme(
            data: SliderDefaultsM3(context),
            child: Slider(
              value: value,
              divisions: 20,
              label: '${(value * 100).round()}%',
              onChanged: ref.read(glowIntensityProvider.notifier).preview,
              onChangeEnd: (value) => unawaited(save(value)),
            ),
          ),
          Text(ru ? '0% — без свечения. Клавиатурный фокус сохраняется.'
              : '0% disables glow. Keyboard focus remains visible.',
              style: context.listCaptionStyle),
        ],
      ),
    );
  }
}

class _ThemeModeItem extends ConsumerWidget {
  const _ThemeModeItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final themeMode = ref.watch(
      themeSettingProvider.select((state) => state.themeMode),
    );
    final floatingBar = ref.watch(_floatingBarProvider);
    final liquidGlass = ref.watch(_liquidGlassProvider);
    final light = MiniScreen(
      colorScheme: ref.watch(genColorSchemeProvider(Brightness.light)),
      floatingBar: floatingBar,
      liquidGlass: liquidGlass,
    );
    final dark = MiniScreen(
      colorScheme: ref.watch(genColorSchemeProvider(Brightness.dark)),
      floatingBar: floatingBar,
      liquidGlass: liquidGlass,
    );
    return PreviewChoiceGroup<ThemeMode>(
      info: Info(label: appLocalizations.themeMode, glyph: AppGlyphs.sun),
      value: themeMode,
      choices: [
        PreviewChoice(
          value: ThemeMode.system,
          label: appLocalizations.auto,
          pictogram: MiniScreenThumb(
            screen: MiniSplitScreen(light: light, dark: dark),
          ),
        ),
        PreviewChoice(
          value: ThemeMode.light,
          label: appLocalizations.light,
          pictogram: MiniScreenThumb(screen: light),
        ),
        PreviewChoice(
          value: ThemeMode.dark,
          label: appLocalizations.dark,
          pictogram: MiniScreenThumb(screen: dark),
        ),
      ],
      onChanged: (value) {
        ref
            .read(themeSettingProvider.notifier)
            .update((state) => state.copyWith(themeMode: value));
      },
    );
  }
}

class _PrimaryColorItem extends ConsumerWidget {
  const _PrimaryColorItem({super.key});

  Future<void> _handleReset(BuildContext context, WidgetRef ref) async {
    final res = await dialogs.showMessage(
      message: TextSpan(text: context.appLocalizations.resetTip),
      destructive: true,
      confirmText: context.appLocalizations.reset,
    );
    if (res != true || !context.mounted) {
      return;
    }
    ref.read(themeSettingProvider.notifier).update((state) {
      return state.copyWith(
        primaryColors: defaultPrimaryColors,
        primaryColor: defaultPrimaryColor,
        colorStyle: ColorStyle.vivid,
      );
    });
  }

  Future<void> _handleDelete(
    BuildContext context,
    WidgetRef ref,
    int color,
  ) async {
    final appLocalizations = context.appLocalizations;
    final res = await dialogs.showMessage(
      message: TextSpan(
        text: appLocalizations.deleteTip(appLocalizations.color),
      ),
      destructive: true,
      confirmText: appLocalizations.delete,
    );
    if (res != true || !context.mounted) {
      return;
    }
    ref.read(themeSettingProvider.notifier).update((state) {
      final primaryColors = List<int>.from(state.primaryColors)..remove(color);
      var primaryColor = state.primaryColor;
      if (primaryColor == color) {
        primaryColor = primaryColors.contains(defaultPrimaryColor)
            ? defaultPrimaryColor
            : null;
      }
      return state.copyWith(
        primaryColors: primaryColors,
        primaryColor: primaryColor,
      );
    });
  }

  void _showColorSheet(
    BuildContext context,
    Color initialColor,
    ValueChanged<int> onConfirmed,
  ) {
    showSheet<void>(
      context: context,
      props: const SheetProps(detents: [0.9]),
      builder: (_) => _CustomColorSheet(
        initialColor: initialColor,
        onConfirmed: (color) {
          if (context.mounted) {
            onConfirmed(color);
          }
        },
      ),
    );
  }

  void _handleAdd(BuildContext context, WidgetRef ref) {
    final primaryColor = ref.read(themeSettingProvider).primaryColor;
    _showColorSheet(
      context,
      primaryColor != null
          ? Color(primaryColor)
          : ref.read(dynamicColorProvider).accentColor,
      (color) => _update(
        ref,
        (state) => state.copyWith(
          primaryColors: state.primaryColors.contains(color)
              ? state.primaryColors
              : [...state.primaryColors, color],
          primaryColor: color,
        ),
      ),
    );
  }

  void _handleEdit(BuildContext context, WidgetRef ref, int color) {
    _showColorSheet(
      context,
      Color(color),
      (edited) => _update(ref, (state) {
        final index = state.primaryColors.indexOf(color);
        if (edited == color || index == -1) {
          return state;
        }
        final primaryColors = List<int>.from(state.primaryColors);
        if (primaryColors.contains(edited)) {
          primaryColors.removeAt(index);
        } else {
          primaryColors[index] = edited;
        }
        return state.copyWith(
          primaryColors: primaryColors,
          primaryColor: state.primaryColor == color
              ? edited
              : state.primaryColor,
        );
      }),
    );
  }

  void _update(WidgetRef ref, ThemeProps Function(ThemeProps state) update) {
    ref.read(themeSettingProvider.notifier).update(update);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final themeColors = ref.watch(
      themeSettingProvider.select(
        (state) => ThemeColorsSelectorState(
          primaryColor: state.primaryColor,
          primaryColors: state.primaryColors,
          colorStyle: state.colorStyle,
          isDefault:
              state.primaryColor == defaultPrimaryColor &&
              intListEquality.equals(
                state.primaryColors,
                defaultPrimaryColors,
              ) &&
              state.colorStyle == ColorStyle.vivid,
        ),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoHeader(
          info: Info(
            label: appLocalizations.themeColor,
            glyph: AppGlyphs.palette,
          ),
          actions: [
            if (!themeColors.isDefault)
              _ResetButton(onPressed: () => _handleReset(context, ref)),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: 8,
            children: [
              _ColorSwatches(
                colors: [null, ...themeColors.primaryColors],
                selected: themeColors.primaryColor,
                onSelect: (color) => _update(
                  ref,
                  (state) => state.copyWith(primaryColor: color),
                ),
                onEdit: (color) => _handleEdit(context, ref, color),
                onDelete: (color) => _handleDelete(context, ref, color),
                onAdd: () => _handleAdd(context, ref),
              ),
              TitleBadge(
                badge: null,
                child: generateSection(
                  items: [
                    ListItem<ColorStyle>.options(
                      title: Text(appLocalizations.colorStyle),
                      options: ColorStyle.values,
                      value: themeColors.colorStyle,
                      textBuilder: (style) => style.label,
                      onChanged: (style) => _update(
                        ref,
                        (state) => state.copyWith(colorStyle: style),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ColorSwatches extends ConsumerWidget {
  const _ColorSwatches({
    required this.colors,
    required this.selected,
    required this.onSelect,
    required this.onEdit,
    required this.onDelete,
    required this.onAdd,
  });

  static const double _minGap = 6;

  // Lines the dots, not their selection rings, up with the rows' text.
  static const double _inset = 16 - (_ColorSwatch.size - _ColorSwatch.dot) / 2;

  final List<int?> colors;
  final int? selected;
  final ValueChanged<int?> onSelect;
  final ValueChanged<int> onEdit;
  final ValueChanged<int> onDelete;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final level = context.raisedSurfaceLevel;
    final releasable = ref.watch(settingReleasableProvider('view.app.color'));
    final systemColor = ref
        .watch(dynamicColorProvider)
        .seedOf(Theme.of(context).brightness);
    return Container(
      padding: const EdgeInsets.all(_inset),
      decoration: ShapeDecoration(
        color: level.colorOf(colorScheme),
        shape: AppShape.xl,
      ),
      child: SurfaceScope(
        level: level,
        child: LayoutBuilder(
          builder: (_, constraints) {
            const cell = _ColorSwatch.size;
            final width = constraints.maxWidth;
            final columns = max(
              1,
              ((width + _minGap) / (cell + _minGap)).floor(),
            );
            final gap = columns > 1
                ? ((width - columns * cell) / (columns - 1)).floorToDouble()
                : 0.0;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                for (final color in colors)
                  _ColorSwatch(
                    color: color == null ? null : Color(color),
                    systemColor: systemColor,
                    isSelected: color == selected,
                    label: color == null
                        ? appLocalizations.followSystem
                        : Color(color).hex,
                    onPressed: () => onSelect(color),
                    menuItems: [
                      if (color != null) ...[
                            CommonPopupMenuItem(
                              glyph: AppGlyphs.edit,
                              label: appLocalizations.edit,
                              onPressed: () => onEdit(color),
                            ),
                            CommonPopupMenuItem(
                              danger: true,
                              glyph: AppGlyphs.delete,
                              label: appLocalizations.delete,
                              onPressed: () => onDelete(color),
                            ),
                      ],
                      if (releasable)
                        CommonPopupMenuItem(
                          glyph: AppGlyphs.lock,
                          label: appLocalizations.returnToProvider,
                          onPressed: () => ref
                              .read(managedSettingsActionProvider.notifier)
                              .release('view.app.color'),
                        ),
                    ],
                  ),
                _AddColorButton(onPressed: onAdd),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _ColorSwatch extends StatefulWidget {
  const _ColorSwatch({
    required this.color,
    required this.systemColor,
    required this.isSelected,
    required this.label,
    required this.onPressed,
    this.menuItems,
  });

  static const double size = 44;
  static const double dot = 32;
  static const double _ring = 2.5;
  static const _duration = Duration(milliseconds: 200);

  static const double _badge = 20;

  /// Null follows the system's accent color, [systemColor].
  final Color? color;
  final Color systemColor;
  final bool isSelected;
  final String label;
  final VoidCallback onPressed;
  final List<CommonPopupMenuItem>? menuItems;

  @override
  State<_ColorSwatch> createState() => _ColorSwatchState();
}

class _ColorSwatchState extends State<_ColorSwatch> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final color = widget.color;
    final fill = color ?? widget.systemColor;
    final selected = widget.isSelected;
    final check = ThemeData.estimateBrightnessForColor(fill) == Brightness.dark
        ? Colors.white
        : Colors.black;
    final swatch = Semantics(
      button: true,
      selected: selected,
      label: widget.label,
      child: SizedBox.square(
        dimension: _ColorSwatch.size,
        child: Material(
          type: MaterialType.transparency,
          shape: AppShape.circle,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            mouseCursor: clickableCursor,
            customBorder: AppShape.circle,
            onTap: widget.onPressed,
            onFocusChange: (value) => setState(() => _focused = value),
            child: Stack(
              alignment: Alignment.center,
              children: [
                AnimatedOpacity(
                  opacity: selected || _focused ? 1 : 0,
                  duration: _ColorSwatch._duration,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      shape: AppShape.circle.copyWith(
                        side: BorderSide(
                          color: selected ? fill : context.colorScheme.primary,
                          width: _ColorSwatch._ring,
                        ),
                      ),
                    ),
                    child: const SizedBox.expand(),
                  ),
                ),
                SizedBox.square(
                  dimension: _ColorSwatch.dot,
                  child: DecoratedBox(
                    decoration: ShapeDecoration(
                      color: fill,
                      shape: AppShape.circle,
                    ),
                  ),
                ),
                if (color == null)
                  const Positioned(
                    right: 0,
                    bottom: 0,
                    child: _EyedropperBadge(size: _ColorSwatch._badge),
                  ),
                AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: _ColorSwatch._duration,
                  curve: Curves.easeOutBack,
                  child: GlyphIcon(
                    AppGlyphs.check,
                    size: 18,
                    fill: 1,
                    color: check,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    final menuItems = widget.menuItems;
    if (menuItems == null) {
      return swatch;
    }
    return ContextMenuRegion(menuItems: menuItems, child: swatch);
  }
}

class _EyedropperBadge extends StatelessWidget {
  const _EyedropperBadge({required this.size});

  static const double _gap = 2;

  final double size;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(_gap),
      decoration: ShapeDecoration(
        color: context.surfaceLevel.colorOf(colorScheme),
        shape: AppShape.circle,
      ),
      child: DecoratedBox(
        decoration: ShapeDecoration(
          color: context.raisedSurfaceLevel.colorOf(colorScheme),
          shape: AppShape.circle,
        ),
        child: Center(
          child: GlyphIcon(
            AppGlyphs.eyedropper,
            size: size - _gap * 2 - 4,
            color: colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}

class _AddColorButton extends StatelessWidget {
  const _AddColorButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    return Tooltip(
      message: context.appLocalizations.add,
      child: Semantics(
        button: true,
        child: SizedBox.square(
          dimension: _ColorSwatch.size,
          child: Material(
            type: MaterialType.transparency,
            shape: AppShape.circle,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              mouseCursor: clickableCursor,
              customBorder: AppShape.circle,
              onTap: onPressed,
              child: Center(
                child: Container(
                  width: _ColorSwatch.dot,
                  height: _ColorSwatch.dot,
                  decoration: ShapeDecoration(
                    color: context.raisedSurfaceLevel.colorOf(colorScheme),
                    shape: AppShape.circle,
                  ),
                  child: GlyphIcon(
                    AppGlyphs.add,
                    size: 20,
                    color: colorScheme.onSurfaceVariant,
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

final _floatingBarProvider = appSettingProvider.select(
  (state) => state.floatingNavigationBar,
);

final _liquidGlassProvider = themeSettingProvider.select(
  (state) => state.liquidGlass != LiquidGlassMode.none,
);

class _PureBlackItem extends ConsumerWidget {
  const _PureBlackItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final pureBlack = ref.watch(
      themeSettingProvider.select((state) => state.pureBlack),
    );
    final floatingBar = ref.watch(_floatingBarProvider);
    final liquidGlass = ref.watch(_liquidGlassProvider);
    Widget preview(bool pureBlack) => MiniScreenThumb(
      screen: MiniScreen(
        colorScheme: ref.watch(
          genColorSchemeProvider(Brightness.dark, pureBlack: pureBlack),
        ),
        floatingBar: floatingBar,
        liquidGlass: liquidGlass,
      ),
    );
    return PreviewChoiceGroup<bool>(
      info: Info(
        label: appLocalizations.pureBlackMode,
        glyph: AppGlyphs.pureBlack,
      ),
      value: pureBlack,
      choices: [
        PreviewChoice(
          value: false,
          label: appLocalizations.standard,
          pictogram: preview(false),
        ),
        PreviewChoice(
          value: true,
          label: appLocalizations.pureBlack,
          pictogram: preview(true),
        ),
      ],
      onChanged: (value) {
        ref
            .read(themeSettingProvider.notifier)
            .update((state) => state.copyWith(pureBlack: value));
      },
    );
  }
}

class _NavigationBarItem extends ConsumerWidget {
  const _NavigationBarItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final floatingBar = ref.watch(_floatingBarProvider);
    final liquidGlass = ref.watch(_liquidGlassProvider);
    final colorScheme = context.colorScheme;
    return PreviewChoiceGroup<bool>(
      info: Info(
        label: appLocalizations.navigationBarStyle,
        glyph: AppGlyphs.layers,
      ),
      value: floatingBar,
      choices: [
        PreviewChoice(
          value: true,
          label: appLocalizations.floating,
          pictogram: MiniScreenThumb(
            screen: MiniScreen(
              colorScheme: colorScheme,
              floatingBar: true,
              liquidGlass: liquidGlass,
            ),
          ),
        ),
        PreviewChoice(
          value: false,
          label: appLocalizations.docked,
          pictogram: MiniScreenThumb(
            screen: MiniScreen(colorScheme: colorScheme, floatingBar: false),
          ),
        ),
      ],
      onChanged: (value) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(floatingNavigationBar: value));
      },
    );
  }
}

class _TabAnimationItem extends ConsumerWidget {
  const _TabAnimationItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final tabAnimation = ref.watch(
      appSettingProvider.select((state) => state.tabAnimation),
    );
    final floatingBar = ref.watch(_floatingBarProvider);
    final liquidGlass = ref.watch(_liquidGlassProvider);
    final colorScheme = context.colorScheme;
    Widget switching(TabAnimation tabAnimation) => MiniScreenThumb(
      screen: MiniScreen(
        colorScheme: colorScheme,
        floatingBar: floatingBar,
        liquidGlass: liquidGlass,
        selected: 1,
        previous: 0,
        progress: 0.55,
        tabAnimation: tabAnimation,
      ),
    );
    return PreviewChoiceGroup<TabAnimation>(
      info: Info(label: appLocalizations.tabAnimation, glyph: AppGlyphs.motion),
      value: tabAnimation,
      choices: [
        PreviewChoice(
          value: TabAnimation.slide,
          label: appLocalizations.slide,
          pictogram: switching(TabAnimation.slide),
        ),
        PreviewChoice(
          value: TabAnimation.fade,
          label: appLocalizations.fade,
          pictogram: switching(TabAnimation.fade),
        ),
      ],
      onChanged: (value) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(tabAnimation: value));
      },
    );
  }
}

class _LiquidGlassItem extends ConsumerWidget {
  const _LiquidGlassItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final mode = ref.watch(
      themeSettingProvider.select((state) => state.liquidGlass),
    );
    final colorScheme = context.colorScheme;
    // Floating either way, as a docked bar stays a fill, over the list page,
    // whose rows run on under the bar where glass shows them.
    Widget preview(bool liquidGlass) => MiniScreenThumb(
      screen: MiniScreen(
        colorScheme: colorScheme,
        floatingBar: true,
        liquidGlass: liquidGlass,
        selected: 1,
      ),
    );
    return PreviewChoiceGroup<LiquidGlassMode>(
      info: Info(
        label: appLocalizations.liquidGlass,
        glyph: AppGlyphs.liquidGlass,
      ),
      value: mode,
      choices: [
        PreviewChoice(
          value: LiquidGlassMode.none,
          label: appLocalizations.none,
          pictogram: preview(false),
        ),
        PreviewChoice(
          value: LiquidGlassMode.standard,
          label: appLocalizations.standard,
          pictogram: preview(true),
        ),
        PreviewChoice(
          value: LiquidGlassMode.ultra,
          label: appLocalizations.ultra,
          pictogram: preview(true),
        ),
      ],
      onChanged: (value) {
        ref
            .read(themeSettingProvider.notifier)
            .update((state) => state.copyWith(liquidGlass: value));
      },
    );
  }
}

class _VibrationItem extends ConsumerWidget {
  const _VibrationItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final vibration = ref.watch(
      appSettingProvider.select((state) => state.vibration),
    );
    return ListItem.toggle(
      leading: const GlyphIcon(AppGlyphs.vibration),
      horizontalTitleGap: 12,
      title: Text(
        appLocalizations.vibration,
        style: AppTextStyle.subheadline
            .of(context, emphasized: true)
            .copyWith(color: context.colorScheme.onSurfaceVariant),
      ),
      subtitle: Text(appLocalizations.vibrationDesc),
      value: vibration,
      onChanged: (value) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(vibration: value));
      },
    );
  }
}

class _HideIpItem extends ConsumerWidget {
  const _HideIpItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final hideIp = ref.watch(
      appSettingProvider.select((state) => state.hideIp),
    );
    return ListItem.toggle(
      leading: const GlyphIcon(AppGlyphs.eyeOff),
      horizontalTitleGap: 12,
      title: Text(
        appLocalizations.hideIp,
        style: AppTextStyle.subheadline
            .of(context, emphasized: true)
            .copyWith(color: context.colorScheme.onSurfaceVariant),
      ),
      subtitle: Text(appLocalizations.hideIpDesc),
      value: hideIp,
      onChanged: (value) {
        ref
            .read(appSettingProvider.notifier)
            .update((state) => state.copyWith(hideIp: value));
      },
    );
  }
}

class _FontFamilyItem extends ConsumerWidget {
  const _FontFamilyItem({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final fontFamily = ref.watch(
      themeSettingProvider.select((state) => state.fontFamily),
    );
    final preview = Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
      child: Row(
        spacing: 12,
        children: [
          Text(
            'Aa',
            style: AppTextStyle.headline
                .of(context)
                .copyWith(fontFamily: fontFamily),
          ),
          Expanded(
            child: Text(
              fontFamily ?? appLocalizations.defaultText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyle.subheadline
                  .of(context)
                  .copyWith(
                    fontFamily: fontFamily,
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          GlyphIcon(
            AppGlyphs.chevronForward,
            size: 20,
            color: colorScheme.onSurfaceVariant,
          ),
        ],
      ),
    );
    final cardColor = context.raisedSurfaceLevel.colorOf(colorScheme);
    Widget card(VoidCallback onTap) => Material(
      color: cardColor,
      shape: AppShape.lg,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        mouseCursor: clickableCursor,
        customBorder: AppShape.lg,
        onTap: onTap,
        child: preview,
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoHeader(
          info: Info(label: appLocalizations.fontFamily, glyph: AppGlyphs.font),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: context.isMobileView
              ? OpenContainer<void>(
                  closedShape: AppShape.lg,
                  closedColor: cardColor,
                  closedBuilder: (_, open) => card(open),
                  openBuilder: (_, _) => const FontFamilyView(),
                )
              : card(
                  () => showSheet<void>(
                    context: context,
                    builder: (_) => const FontFamilyView(),
                  ),
                ),
        ),
      ],
    );
  }
}

class _TextScaleFactorItem extends ConsumerStatefulWidget {
  const _TextScaleFactorItem({super.key});

  static const _step = 0.05;

  @override
  ConsumerState<_TextScaleFactorItem> createState() =>
      _TextScaleFactorItemState();
}

class _TextScaleFactorItemState extends ConsumerState<_TextScaleFactorItem> {
  double? _draft;

  void _update(TextScale Function(TextScale textScale) update) {
    setState(() => _draft = null);
    ref
        .read(themeSettingProvider.notifier)
        .update((state) => state.copyWith(textScale: update(state.textScale)));
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    final colorScheme = context.colorScheme;
    final textScale = ref.watch(
      themeSettingProvider.select((state) => state.textScale),
    );
    final systemScale = systemTextScaleOf(
      context,
    ).clamp(minTextScale, maxTextScale).toDouble();
    final scale = _draft ?? (textScale.enable ? textScale.scale : systemScale);
    final percent = '${(scale * 100).round()}%';
    final level = context.raisedSurfaceLevel;
    final divisions =
        ((maxTextScale - minTextScale) / _TextScaleFactorItem._step).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoHeader(
          info: Info(
            label: appLocalizations.textScale,
            glyph: AppGlyphs.textSize,
          ),
          actions: [
            if (textScale.enable && textScale.scale != 1)
              _ResetButton(
                onPressed: () => _update((state) => state.copyWith(scale: 1)),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: Column(
            spacing: 8,
            children: [
              SegmentedControl<bool>(
                segments: [
                  (false, appLocalizations.followSystem),
                  (true, appLocalizations.custom),
                ],
                value: textScale.enable,
                onChanged: (value) =>
                    _update((state) => state.copyWith(enable: value)),
              ),
              Container(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                decoration: ShapeDecoration(
                  color: level.colorOf(colorScheme),
                  shape: AppShape.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 12,
                      children: [
                        Expanded(
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeOutCubic,
                            alignment: Alignment.topLeft,
                            child: MediaQuery(
                              data: MediaQuery.of(
                                context,
                              ).copyWith(textScaler: TextScaler.linear(scale)),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                spacing: 4,
                                children: [
                                  Text(
                                    'Aa',
                                    style: AppTextStyle.title3.of(context),
                                  ),
                                  Text(
                                    appLocalizations.textScalePreview,
                                    style: AppTextStyle.subheadline
                                        .of(context)
                                        .copyWith(
                                          color: colorScheme.onSurfaceVariant,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: ShapeDecoration(
                            color: level.next.colorOf(colorScheme),
                            shape: AppShape.full,
                          ),
                          child: Text(
                            percent,
                            style: AppTextStyle.subheadline
                                .of(context, emphasized: true)
                                .copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                  fontFeatures: const [
                                    FontFeature.tabularFigures(),
                                  ],
                                ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    MediaQuery.withNoTextScaling(
                      child: Row(
                        spacing: 12,
                        children: [
                          ExcludeSemantics(
                            child: Text(
                              'A',
                              style: AppTextStyle.footnote
                                  .of(context)
                                  .copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                          Expanded(
                            child: SliderTheme(
                              data: SliderDefaultsM3(context),
                              child: Slider(
                                padding: EdgeInsets.zero,
                                min: minTextScale,
                                max: maxTextScale,
                                divisions: divisions,
                                value: scale,
                                label: percent,
                                onChanged: textScale.enable
                                    ? (value) => setState(() => _draft = value)
                                    : null,
                                onChangeEnd: (value) => _update(
                                  (state) => state.copyWith(scale: value),
                                ),
                              ),
                            ),
                          ),
                          ExcludeSemantics(
                            child: Text(
                              'A',
                              style: AppTextStyle.title2
                                  .of(context)
                                  .copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResetButton extends StatelessWidget {
  const _ResetButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return TonalButtonTheme(
      size: TonalButtonSize.section,
      child: ElasticPress(
        child: IconButton(
          tooltip: context.appLocalizations.reset,
          onPressed: onPressed,
          icon: const GlyphIcon(AppGlyphs.reset),
        ),
      ),
    );
  }
}

class _CustomColorSheet extends StatefulWidget {
  const _CustomColorSheet({
    required this.initialColor,
    required this.onConfirmed,
  });

  final Color initialColor;

  /// Runs once the sheet has closed, so retheming every page cannot stall it.
  final ValueChanged<int> onConfirmed;

  @override
  State<_CustomColorSheet> createState() => _CustomColorSheetState();
}

class _CustomColorSheetState extends State<_CustomColorSheet> {
  late final _controller = ValueNotifier<Color>(widget.initialColor);

  void _confirm() {
    final color = _controller.value.toARGB32();
    final onConfirmed = widget.onConfirmed;
    unawaited(
      ModalRoute.of(context)!.completed.whenComplete(() => onConfirmed(color)),
    );
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLocalizations = context.appLocalizations;
    // Clears Android's edge back-swipe zone; exclusion rects stop at 200 dp.
    final gestureInsets = MediaQuery.systemGestureInsetsOf(context);
    return CommonScaffold(
      title: appLocalizations.customColor,
      confirmationAction: IconButtonData(
        glyph: AppGlyphs.check,
        tooltip: appLocalizations.confirm,
        onPressed: _confirm,
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          max(16, gestureInsets.left),
          context.contentTopPadding,
          max(16, gestureInsets.right),
          20 + context.bottomInset,
        ),
        children: [
          ValueListenableBuilder(
            valueListenable: _controller,
            builder: (_, color, _) => _CustomColorPreview(
              color: color,
              onChanged: (color) => _controller.value = color,
            ),
          ),
          const SizedBox(height: 16),
          Palette(controller: _controller),
        ],
      ),
    );
  }
}

class _CustomColorPreview extends ConsumerWidget {
  const _CustomColorPreview({required this.color, required this.onChanged});

  static const Size _screenSize = Size(96, 128);
  static const double _scale = 0.75;

  final Color color;
  final ValueChanged<Color> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final floatingBar = ref.watch(_floatingBarProvider);
    final liquidGlass = ref.watch(_liquidGlassProvider);
    final level = context.raisedSurfaceLevel;
    Widget screen(Brightness brightness) => ExcludeSemantics(
      child: SizedBox.fromSize(
        size: _screenSize * _scale,
        child: ClipRSuperellipse(
          borderRadius: AppRadius.md,
          child: FittedBox(
            child: SizedBox.fromSize(
              size: _screenSize,
              child: MiniScreen(
                colorScheme: ref.watch(
                  genColorSchemeProvider(brightness, color: color),
                ),
                floatingBar: floatingBar,
                liquidGlass: liquidGlass,
              ),
            ),
          ),
        ),
      ),
    );
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: ShapeDecoration(
        color: level.colorOf(context.colorScheme),
        shape: AppShape.xl,
      ),
      child: SurfaceScope(
        level: level,
        child: Row(
          spacing: 12,
          children: [
            screen(Brightness.light),
            screen(Brightness.dark),
            Expanded(
              child: HexColorField(color: color, onChanged: onChanged),
            ),
          ],
        ),
      ),
    );
  }
}

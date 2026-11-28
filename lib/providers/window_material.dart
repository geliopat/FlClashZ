import 'dart:io';
import 'dart:ui' show Brightness, Color;

import 'package:fl_clash/providers/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window/window.dart';

const windowMaterials = [
  WindowEffect.none,
  WindowEffect.mica,
  WindowEffect.acrylic,
];

WindowEffect parseWindowMaterial(String? name) =>
    switch (name) {
      'mica' => WindowEffect.mica,
      'micaAlt' => WindowEffect.mica,
      'acrylic' => WindowEffect.acrylic,
      _ => WindowEffect.none,
    };

const _key = 'theme.windowMaterial';

final windowMaterialPreferenceProvider = FutureProvider<WindowEffect>((ref) async {
  if (!Platform.isWindows) return WindowEffect.none;
  try {
    final prefs = await SharedPreferences.getInstance();
    return parseWindowMaterial(prefs.getString(_key));
  } catch (_) {
    return WindowEffect.none;
  }
});

Future<void> saveWindowMaterial(WidgetRef ref, WindowEffect effect) async {
  if (!Platform.isWindows || !windowMaterials.contains(effect)) return;
  final prefs = await SharedPreferences.getInstance();
  if (!await prefs.setString(_key, effect.name)) {
    throw StateError('Unable to save window material');
  }
  if (ref.context.mounted) ref.invalidate(windowMaterialPreferenceProvider);
}

/// Only expose a translucent Flutter surface after the native plugin accepts
/// the requested effect. A missing plugin or an unsupported OS stays opaque.
final windowMaterialProvider = FutureProvider<WindowEffect>((ref) async {
  if (!Platform.isWindows) return WindowEffect.none;
  final brightness = ref.watch(currentBrightnessProvider);
  final requested = await ref.watch(windowMaterialPreferenceProvider.future);
  if (!ref.mounted) return WindowEffect.none;
  try {
    await desktopWindow.ensureInitialized();
    final supported = await desktopWindow.isEffectSupported(requested);
    if (!ref.mounted) return WindowEffect.none;
    final effect = supported ? requested : WindowEffect.none;
    await desktopWindow.setEffect(
      effect,
      brightness: brightness,
      tint: effect == WindowEffect.acrylic
          ? brightness == Brightness.dark
              ? const Color(0x99202020)
              : const Color(0x99F0F0F0)
          : null,
    );
    return effect;
  } catch (_) {
    if (ref.mounted) {
      try {
        await desktopWindow.setEffect(WindowEffect.none, brightness: brightness);
      } catch (_) {}
    }
    return WindowEffect.none;
  }
});

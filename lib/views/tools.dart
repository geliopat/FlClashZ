import 'dart:async';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/views/about.dart';
import 'package:fl_clash/views/access.dart';
import 'package:fl_clash/views/config/general.dart';
import 'package:fl_clash/views/hotkey.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'config/advanced.dart';
import 'config/network_tests.dart';
import 'config/custom_resources.dart';
import 'developer.dart';
import 'diagnostics.dart';
import 'disclaimer.dart';
import 'theme.dart';
import 'zapret_settings.dart';

class ToolsView extends ConsumerStatefulWidget {
  const ToolsView({super.key});

  @override
  ConsumerState<ToolsView> createState() => _ToolViewState();
}

class _ToolViewState extends ConsumerState<ToolsView> {
  Widget _buildNavigationMenuItem(NavigationItem navigationItem) {
    return ListItem.open(
      leading: GlyphIcon(navigationItem.glyph),
      title: Text(navigationItem.label.label),
      widget: navigationItem.builder(context),
      forceFull: navigationItem.modes.contains(NavigationItemMode.moreFull),
    );
  }

  Widget _getOtherList(bool enableDeveloperMode, {required bool simple}) {
    return generateSection(
      title: context.appLocalizations.other,
      items: [
        if (!simple) const _DisclaimerItem(),
        if (enableDeveloperMode && !simple) const _DeveloperItem(),
        const _InfoItem(),
      ],
    );
  }

  Widget _getSettingList({required bool simple}) {
    final appLocalizations = context.appLocalizations;
    if (simple) {
      return generateSection(
        title: appLocalizations.settings,
        items: [
          const _LocaleItem(),
          const _ThemeItem(),
          if (Platform.isWindows) const _ZapretItem(),
          if (Platform.isWindows) const _DiagnosticsItem(),
          const _GeneralItem(),
          if (Platform.isWindows) const _NetworkTestsItem(),
        ],
      );
    }
    return generateSection(
      title: appLocalizations.settings,
      items: [
        const _LocaleItem(),
        const _ThemeItem(),
        if (system.isDesktop) const _HotkeyItem(),
        if (system.isAndroid) const _AccessItem(),
        const _AdvancedConfigItem(),
        const _CustomResourcesItem(),
        if (Platform.isWindows) const _ZapretItem(),
          if (Platform.isWindows) const _DiagnosticsItem(),
        const _GeneralItem(),
        if (Platform.isWindows) const _NetworkTestsItem(),
      ],
      footer: [
        if (system.isAndroid) appLocalizations.accessControlDesc,
        appLocalizations.advancedConfigDesc,
        appLocalizations.customProfileResourcesDesc,
      ].join('\n'),
    );
  }

  @override
  Widget build(BuildContext context) {
    final developerMode = ref.watch(
      appSettingProvider.select((state) => state.developerMode),
    );
    final simple = ref.watch(simpleModeProvider);
    final items = [
      Consumer(
        builder: (_, ref, _) {
          final state = ref.watch(moreToolsSelectorStateProvider);
          final controller = ref.watch(
            patchClashConfigProvider.select(
              (state) => state.externalController,
            ),
          );
          if (state.navigationItems.isEmpty) {
            return Container();
          }
          return generateSection(
            items: [
              for (final item in state.navigationItems) ...[
                _buildNavigationMenuItem(item),
                if (item.label == PageLabel.resources && controller.isNotEmpty)
                  const _DashboardItem(),
              ],
            ],
          );
        },
      ),
      _getSettingList(simple: simple),
      _getOtherList(developerMode, simple: simple),
    ];
    return CommonScaffold(
      title: context.appLocalizations.tools,
      body: Builder(
        builder: (context) => ListView.builder(
          key: toolsStoreKey,
          itemCount: items.length,
          itemBuilder: (_, index) => items[index],
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: context.sectionsTopPadding,
            bottom: 20 + context.bottomInset,
          ),
        ),
      ),
    );
  }
}

class _DashboardItem extends ConsumerWidget {
  const _DashboardItem();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (controller, secret) = ref.watch(
      patchClashConfigProvider.select(
        (state) => (state.externalController, state.secret),
      ),
    );
    final url = zashboardUrl(controller, secret: secret);
    return ListItem(
      leading: const GlyphIcon(AppGlyphs.zashboard),
      title: const Text('Zashboard'),
      subtitle: Text(controller),
      trailing: const GlyphIcon(AppGlyphs.link),
      onTap: () => unawaited(launchUrl(Uri.parse(url))),
    );
  }
}

class _LocaleItem extends ConsumerWidget {
  const _LocaleItem();

  String _getLocaleString(BuildContext context, Locale? locale) {
    if (locale == null) return context.appLocalizations.defaultText;
    return locale.label;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(
      appSettingProvider.select((state) => state.locale),
    );
    final currentLocale = getLocaleForString(locale);
    // The pick lands once the menu has flown back, when this row may be gone.
    final settings = ref.read(appSettingProvider.notifier);
    return ListItem<Locale?>.options(
      leading: const GlyphIcon(AppGlyphs.language),
      title: Text(context.appLocalizations.language),
      options: [null, ...AppLocalizations.delegate.supportedLocales],
      onChanged: (Locale? locale) {
        settings.update((state) => state.copyWith(locale: locale?.toString()));
      },
      textBuilder: (locale) => _getLocaleString(context, locale),
      value: currentLocale,
    );
  }
}

class _ThemeItem extends StatelessWidget {
  const _ThemeItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const GlyphIcon(AppGlyphs.paintbrush),
      title: Text(context.appLocalizations.theme),
      widget: const ThemeView(),
    );
  }
}

class _HotkeyItem extends StatelessWidget {
  const _HotkeyItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const GlyphIcon(AppGlyphs.keyboard),
      title: Text(context.appLocalizations.hotkeyManagement),
      widget: const HotKeyView(),
    );
  }
}

class _AccessItem extends StatelessWidget {
  const _AccessItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const GlyphIcon(AppGlyphs.appsList),
      title: Text(context.appLocalizations.accessControl),
      widget: const AccessView(),
    );
  }
}

class _ZapretItem extends StatelessWidget {
  const _ZapretItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const GlyphIcon(AppGlyphs.wrench),
      title: const Text('Zapret'),
      subtitle: const Text('Диагностика, списки и обновления'),
      widget: const ZapretSettingsView(),
    );
  }
}

class _DiagnosticsItem extends StatelessWidget {
  const _DiagnosticsItem();

  @override
  Widget build(BuildContext context) => ListItem.open(
    leading: const GlyphIcon(AppGlyphs.status),
    title: Text(AppLocalizations.of(context).forkDiagnostics),
    widget: const DiagnosticsView(),
  );
}

class _GeneralItem extends StatelessWidget {
  const _GeneralItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const GlyphIcon(AppGlyphs.settings),
      title: Text(context.appLocalizations.general),
      widget: const GeneralView(),
    );
  }
}

class _AdvancedConfigItem extends StatelessWidget {
  const _AdvancedConfigItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const GlyphIcon(AppGlyphs.wrench),
      title: Text(context.appLocalizations.advancedConfig),
      widget: const AdvancedConfigView(),
    );
  }
}

class _CustomResourcesItem extends StatelessWidget {
  const _CustomResourcesItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const GlyphIcon(AppGlyphs.customize),
      title: Text(context.appLocalizations.customProfileResources),
      widget: const CustomResourcesView(),
    );
  }
}

class _DisclaimerItem extends StatelessWidget {
  const _DisclaimerItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const GlyphIcon(AppGlyphs.gavel),
      title: Text(context.appLocalizations.disclaimer),
      widget: const DisclaimerView(),
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const GlyphIcon(AppGlyphs.info),
      title: Text(context.appLocalizations.about),
      widget: const AboutView(),
    );
  }
}

class _DeveloperItem extends StatelessWidget {
  const _DeveloperItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const GlyphIcon(AppGlyphs.cpu),
      title: Text(context.appLocalizations.developerMode),
      widget: const DeveloperView(),
    );
  }
}


class _NetworkTestsItem extends StatelessWidget {
  const _NetworkTestsItem();

  @override
  Widget build(BuildContext context) => ListItem.open(
    leading: const GlyphIcon(AppGlyphs.heartPulse),
    title: Text(Localizations.localeOf(context).languageCode == 'ru'
        ? 'Сетевые тесты' : 'Network tests'),
    widget: const NetworkTestsView(),
  );
}

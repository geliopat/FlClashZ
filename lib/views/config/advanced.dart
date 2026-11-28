import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/views/config/dns.dart';
import 'package:fl_clash/views/config/sniffer.dart';
import 'package:fl_clash/views/config/ntp.dart';
import 'package:fl_clash/views/config/additional_mihomo_settings.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_clash/views/config/network.dart';
import 'package:fl_clash/views/config/scripts.dart';
import 'package:material_ui/material_ui.dart';

import 'rules.dart';

class AdvancedConfigView extends ConsumerWidget {
  const AdvancedConfigView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appLocalizations = context.appLocalizations;
    final activeId = ref.watch(currentProfileIdProvider);
    final items = [
      ListItem.open(
        title: Text(appLocalizations.network),
        leading: const GlyphIcon(AppGlyphs.key),
        widget: BaseScaffold(
          title: appLocalizations.network,
          body: const NetworkListView(),
        ),
      ),
      ListItem.open(
        title: const Text('DNS'),
        leading: const GlyphIcon(AppGlyphs.dns),
        widget: const DnsView(),
      ),
      if (system.isWindows && activeId != null)
        ListItem.open(
          title: Text(appLocalizations.sniffer),
          widget: SnifferView(activeId, preserveEmpty: true),
        ),
      if (system.isWindows && activeId != null) ...[
        ListItem.open(title: const Text('NTP'), widget: NtpView(activeId, preserveEmpty: true)),
        ListItem.open(title: Text(Localizations.localeOf(context).languageCode == 'ru'
            ? 'Дополнительные параметры Mihomo' : 'Additional Mihomo settings'),
          widget: AdditionalMihomoSettingsView(profileId: activeId)),
      ],
      ListItem.open(
        title: Text(appLocalizations.addedRules),
        leading: const GlyphIcon(AppGlyphs.rules),
        widget: const AddedRulesView(),
      ),
      ListItem.open(
        title: Text(appLocalizations.script),
        leading: const GlyphIcon(AppGlyphs.code),
        widget: const ScriptsView(),
      ),
    ];
    return BaseScaffold(
      title: appLocalizations.advancedConfig,
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.sectionsTopPadding,
          bottom: 16 + context.bottomInset,
        ),
        children: [generateSection(items: items)],
      ),
    );
  }
}

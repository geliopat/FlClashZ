import 'package:fl_clash/common/constant.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// Uses the same action as the automatic application update check.
class CoreReleaseSection extends ConsumerStatefulWidget {
  const CoreReleaseSection({super.key});

  @override
  ConsumerState<CoreReleaseSection> createState() => _CoreReleaseSectionState();
}

class _CoreReleaseSectionState extends ConsumerState<CoreReleaseSection> {
  bool _checking = false;

  Future<void> _check() async {
    if (_checking) return;
    setState(() => _checking = true);
    try {
      await ref.read(commonActionProvider.notifier).checkCoreUpdate(isUser: true);
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final disabled = _checking || safeModeBuild || ref.watch(safeModeProvider) ||
        !ref.watch(initProvider) || ref.watch(coreStatusProvider) != CoreStatus.connected ||
        ref.watch(loadingProvider(LoadingTag.checkUpdate));
    return generateSection(
      title: ru ? 'Независимое ядро FlClashZ' : 'Independent FlClashZ core',
      items: [
        ListItem(
          leading: const GlyphIcon(AppGlyphs.cpu),
          title: Text(ru ? 'Проверить обновление ядра' : 'Check core updates'),
          onTap: disabled ? null : _check,
        ),
      ],
    );
  }
}

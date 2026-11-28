import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/pages/editor.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/views/config/override.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

/// The existing editors retain ownership of their modeled fields. This page
/// lists only remaining fields from the pinned core, using the same profile
/// storage/refresh pipeline and YAML editor rather than a second DNS/TUN UI.
class AdditionalMihomoSettingsView extends ConsumerWidget {
  const AdditionalMihomoSettingsView({super.key, required this.profileId});
  final int profileId;

  void _save(WidgetRef ref, String path, Object? value, {bool remove = false}) {
    ref.read(profilesProvider.notifier).updateProfile(profileId, (profile) {
      final next = decodeAdditionalSettings(profile.overrides.additionalSettingsYaml);
      if (remove) {
        next.remove(path);
      } else {
        next[path] = validateAdditionalValue(path, value);
      }
      return profile.copyWith(overrides: profile.overrides.copyWith(
        additionalSettingsYaml: next.isEmpty ? '' : yaml.encode(next),
      ));
    });
  }

  Future<void> _edit(BuildContext context, WidgetRef ref, String path, Object? value) async {
    final initial = yaml.encode({path: value});
    await BaseNavigator.push<void>(context, EditorPage(
      title: path, content: initial, readOnly: false,
      allowUnchangedSave: true,
      onSave: (editorContext, _, content) async {
        try {
          final decoded = decodeAdditionalSettings(await content.readText());
          if (!ref.context.mounted) return;
          if (decoded.length != 1 || !decoded.containsKey(path)) {
            throw const FormatException('Only the selected setting may be edited');
          }
          _save(ref, path, decoded[path]);
        } catch (_) {
          if (!editorContext.mounted) return;
          final ru = Localizations.localeOf(editorContext).languageCode == 'ru';
          dialogs.showNotifier(
            ru ? 'Недопустимое значение параметра. Изменения не сохранены.'
                : 'Invalid setting value. Changes were not saved.',
            level: MessageLevel.error,
          );
        }
      },
      onPop: (editorContext, _, content) async {
        try {
          final decoded = decodeAdditionalSettings(await content.readText());
          if (!ref.context.mounted || decoded.length != 1 || !decoded.containsKey(path)) {
            throw const FormatException('Only the selected setting may be edited');
          }
          _save(ref, path, decoded[path]);
          return true;
        } catch (_) {
          if (!editorContext.mounted) return false;
          final ru = Localizations.localeOf(editorContext).languageCode == 'ru';
          return await dialogs.showMessage(
            message: TextSpan(text: ru
              ? 'Недопустимое значение. Закрыть без сохранения?'
              : 'Invalid value. Close without saving?'),
            destructive: true,
          ) == true;
        }
      },
    ));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ru = Localizations.localeOf(context).languageCode == 'ru';
    final profile = ref.watch(profileProvider(profileId));
    final sources = ref.watch(yamlSectionSourcesProvider);
    final sameSource = sources?.profileId == profileId;
    final sourcePending = profile != null && profile.type != ProfileType.custom &&
        profile.extendType != ExtendType.script && !sameSource;
    final explicit = sameSource ? sources!.explicit : const <String, dynamic>{};
    final defaults = sameSource ? sources!.defaults : const <String, dynamic>{};
    Map<String, Object> local;
    try {
      local = decodeAdditionalSettings(profile?.overrides.additionalSettingsYaml ?? '');
    } catch (_) {
      return BaseScaffold(title: 'Mihomo', body: Center(child: Text(ru
          ? 'Сохранённые переопределения не прочитаны. Данные сохранены.'
          : 'Saved overrides could not be read. Data has been retained.')));
    }
    final listed = additionalMihomoKeys.keys.where((path) =>
      local.containsKey(path) || additionalSourceOf(explicit, path).present).toList();
    final absent = additionalMihomoKeys.keys.where((path) => !listed.contains(path)).toList();
    String label(Object? value) => inheritedOverrideValueLabel(value, russian: ru);
    return BaseScaffold(
      title: ru ? 'Дополнительные параметры Mihomo' : 'Additional Mihomo settings',
      body: ListView(
        padding: EdgeInsets.fromLTRB(16, context.sectionsTopPadding, 16, 16 + context.bottomInset),
        children: [
          generateSection(items: [
            for (final path in listed)
              Builder(builder: (context) {
                final source = additionalSourceOf(explicit, path);
                final owned = local.containsKey(path);
                final value = owned ? local[path] : source.value;
                final caption = source.present
                  ? '${ru ? 'Из подписки' : 'From subscription'}: ${label(source.value)}'
                  : (ru ? 'Локальная настройка' : 'Local setting');
                return ManagedSettingRegion(
                  locked: false, releasable: owned,
                  onTakeOver: () {}, onRelease: () => _save(ref, path, null, remove: true),
                  caption: caption,
                  child: ListItem(title: Text(path), subtitle: Text(label(value)),
                    onTap: () async {
                      if (!owned) {
                        final agreed = await dialogs.showMessage(
                          title: context.appLocalizations.managedByProvider,
                          message: TextSpan(text: context.appLocalizations.managedByProviderTip),
                          confirmText: context.appLocalizations.takeOver,
                        );
                        if (agreed != true || !context.mounted) return;
                        // Opening or cancelling the editor must not replace
                        // subscription ownership. Only a valid save does so.
                      }
                      if (context.mounted) await _edit(context, ref, path, value);
                    }),
                );
              }),
            if (sourcePending)
              ListItem(title: Text(ru ? 'Параметры подписки пока недоступны' : 'Subscription settings are not available yet')),
            if (!sourcePending && absent.isNotEmpty)
              ListItem(title: Text(ru ? 'Добавить параметр' : 'Add parameter'),
                onTap: () async {
                  final selected = await showDialog<String>(context: context, builder: (ctx) => SimpleDialog(
                    title: Text(ru ? 'Добавить параметр' : 'Add parameter'),
                    children: [for (final path in absent)
                      SimpleDialogOption(onPressed: () => Navigator.of(ctx).pop(path), child: Text(path))],
                  ));
                  if (selected == null || !context.mounted) return;
                  final latest = ref.read(yamlSectionSourcesProvider);
                  if (latest?.profileId == profileId && additionalSourceOf(latest!.explicit, selected).present) return;
                  final current = ref.read(profileProvider(profileId));
                  if (current == null || decodeAdditionalSettings(current.overrides.additionalSettingsYaml).containsKey(selected)) return;
                  final fallback = additionalSourceOf(defaults, selected);
                  final initial = fallback.value ?? additionalDefault(additionalMihomoKeys[selected]!);
                  // Do not add a local override until the editor saves it.
                  if (context.mounted) await _edit(context, ref, selected, initial);
                }),
          ]),
          Padding(padding: const EdgeInsets.all(8), child: Text(ru
            ? 'Параметры сохраняются только в выбранном профиле. Управляемые приложением, платформенные и секретные поля здесь не изменяются.'
            : 'Settings are stored only for this profile. App-managed, platform-specific and sensitive fields are not edited here.',
            style: context.listCaptionStyle)),
        ],
      ),
    );
  }
}

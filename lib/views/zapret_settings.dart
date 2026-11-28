import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/l10n/l10n.dart';
import 'package:fl_clash/models/managed_settings.dart';
import 'dart:async';
import 'package:fl_clash/providers/zapret_list_updater.dart';
import 'package:fl_clash/core/desktop/helper_client.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/widgets/widgets.dart';
import 'package:material_ui/material_ui.dart';
import 'package:fl_clash/pages/editor.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

class ZapretSettingsView extends ConsumerStatefulWidget {
  const ZapretSettingsView({super.key});

  @override
  ConsumerState<ZapretSettingsView> createState() => _ZapretSettingsViewState();
}

class _ZapretSettingsViewState extends ConsumerState<ZapretSettingsView> {
  final _editor = TextEditingController();
  List<HelperZapretListInfo> _lists = const [];
  String? _selected;
  bool _loading = true;
  bool _listLoaded = false;
  bool _updating = false;
  String? _error;
  String? _notice;
  bool _updatingHelper = false;

  @override
  void initState() {
    super.initState();
    scheduleMicrotask(() {
      if (!mounted) return;
      unawaited(_loadLists());
      unawaited(ref.read(zapretDiagnosticsProvider.notifier).refresh());
      unawaited(ref.read(zapretControllerProvider.notifier).refresh());
    });
  }

  @override
  void dispose() {
    _editor.dispose();
    super.dispose();
  }

  Future<void> _loadLists({String? select}) async {
    setState(() {
      _loading = true;
      _listLoaded = false;
      _error = null;
      _notice = null;
    });
    try {
      final lists = await helperClient.zapretLists();
      final currentSelection = _selected;
      final filename = (select != null && lists.any((item) => item.filename == select))
          ? select
          : (currentSelection != null &&
                  lists.any((item) => item.filename == currentSelection)
              ? currentSelection
              : (lists.isEmpty ? null : lists.first.filename));
      if (filename == null) {
        if (mounted) setState(() { _lists = lists; _selected = null; _loading = false; });
        return;
      }
      final data = await helperClient.readZapretList(filename);
      if (!mounted) return;
      setState(() {
        _lists = lists;
        _selected = filename;
        _editor.text = data.content;
        _loading = false;
        _listLoaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _listLoaded = false;
        _error = error is HelperException ? error.message : error.toString();
      });
    }
  }

  Future<void> _selectList(String filename) async {
    setState(() {
      _selected = filename;
      _loading = true;
      _listLoaded = false;
      _editor.clear();
      _error = null;
    });
    try {
      final data = await helperClient.readZapretList(filename);
      if (!mounted) return;
      setState(() {
        _editor.text = data.content;
        _loading = false;
        _listLoaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _listLoaded = false;
        _error = error is HelperException ? error.message : error.toString();
      });
    }
  }

  Future<void> _updateLists() async {
    if (_updating || _lists.isEmpty) return;
    final l = AppLocalizations.of(context);
    setState(() {
      _updating = true;
      _error = null;
      _notice = null;
    });
    try {
      final result = await zapretListUpdater.update(l, canCommit: () =>
          mounted && !_updatingHelper && !ref.read(safeModeProvider) &&
          !ref.read(zapretControllerProvider).busy);
      if (!mounted) return;
      await _loadLists(select: _selected);
      if (!mounted) return;
      setState(() {
        _error = result.error;
        _notice = result.notice;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  Future<void> _updateHelperService() async {
    if (_updatingHelper) return;
    final l = AppLocalizations.of(context);
    final confirmed = await showFloatingDialog<bool>(
      context: context,
      child: CommonDialog(
        title: l.forkReinstallHelperQuestion,
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(AppLocalizations.of(context).confirm),
          ),
        ],
        child: Text(l.forkReinstallHelperHint),
      ),
    );
    if (confirmed != true || !mounted) return;
    setState(() {
      _updatingHelper = true;
      _error = null;
      _notice = null;
    });
    try {
      await zapretListUpdater.edit(() =>
          ref.read(zapretControllerProvider.notifier).updateHelperService());
      if (!mounted) return;
      setState(() {
        _notice = l.forkHelperReinstalled;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error is HelperException ? error.message : error.toString();
      });
    } finally {
      if (mounted) setState(() => _updatingHelper = false);
    }
  }


  Future<void> _showProtectionList(String title, List<String> entries) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(title),
        content: SizedBox(
          width: 650,
          child: SingleChildScrollView(
            child: SelectableText(entries.join('\n')),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context).close),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final zapret = ref.watch(zapretControllerProvider);
    final listsBusy = _loading || _updating || _updatingHelper;
    final sections = <Widget>[
      const ManagedSettingsHint(keys: {zapretStartSetting}),
      generateSection(
        title: AppLocalizations.of(context).forkHelperService,
        items: [
          ManagedSetting(
            settingKey: zapretStartSetting,
            onTakenOver: zapret.busy ? null : () => ref
                .read(zapretControllerProvider.notifier)
                .setStartWithMihomo(!zapret.startWithMihomo),
            child: ListItem(
              title: Text(AppLocalizations.of(context).forkStartWithMihomo),
              subtitle: Text(AppLocalizations.of(context).forkStopWithMihomo),
              trailing: Switch(
                value: zapret.startWithMihomo,
                onChanged: zapret.busy ? null : ref.read(zapretControllerProvider.notifier).setStartWithMihomo,
              ),
            ),
          ),
            ListItem(
              leading: const GlyphIcon(AppGlyphs.vpn),
              title: Text(AppLocalizations.of(context).forkReinstallHelper),
              subtitle: Text(AppLocalizations.of(context).forkReinstallHelperDesc),
              trailing: _updatingHelper
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CommonCircleLoading(size: 18),
                    )
                  : null,
              onTap: zapret.busy || _updatingHelper
                  ? null
                  : _updateHelperService,
            ),
        ],
      ),
      const ListSectionGap(),
      generateSection(
        title: AppLocalizations.of(context).forkMihomoProtection,
        items: [
          ListItem(
            title: Text(AppLocalizations.of(context).forkExcludedIps),
            subtitle: Text('${zapret.protectedIps.length} · ${AppLocalizations.of(context).forkAutomaticFromProfile}'),
            onTap: zapret.protectedIps.isEmpty ? null : () => _showProtectionList(
              AppLocalizations.of(context).forkExcludedIps, zapret.protectedIps,
            ),
          ),
          ListItem(
            title: Text(AppLocalizations.of(context).forkExcludedDomains),
            subtitle: Text('${zapret.protectedDomains.length} · ${AppLocalizations.of(context).forkAutomaticFromProfile}'),
            onTap: zapret.protectedDomains.isEmpty ? null : () => _showProtectionList(
              AppLocalizations.of(context).forkExcludedDomains, zapret.protectedDomains,
            ),
          ),
          ListItem(
            leading: const GlyphIcon(AppGlyphs.refresh),
            title: Text(AppLocalizations.of(context).forkRefreshExclusions),
            onTap: zapret.busy ? null : () async {
              try {
                await ref.read(zapretControllerProvider.notifier).refreshInfrastructure();
              } catch (error) {
                if (mounted) setState(() => _error = error.toString());
              }
            },
          ),
        ],
        footer: AppLocalizations.of(context).forkProtectionHint,
      ),
      const ListSectionGap(),
      generateSection(
        title: AppLocalizations.of(context).forkZapretLists,
        items: [
          if (_error != null)
            ListItem(
              leading: GlyphIcon(AppGlyphs.error, color: context.colorScheme.error),
              title: Text(AppLocalizations.of(context).error),
              subtitle: Text(
                _error!,
                style: TextStyle(color: context.colorScheme.error),
              ),
            ),
          if (_notice != null)
            ListItem(
              leading: GlyphIcon(AppGlyphs.info, color: context.colorScheme.primary),
              title: Text(AppLocalizations.of(context).forkResults),
              subtitle: Text(_notice!),
            ),
          if (_loading && _lists.isEmpty)
            ListItem(
              title: Text(AppLocalizations.of(context).loading),
              trailing: const SizedBox.square(
                dimension: 18,
                child: CommonCircleLoading(size: 18),
              ),
            ),
          if (_lists.isNotEmpty && _selected != null)
            ListItem<String>.options(
              title: Text(AppLocalizations.of(context).forkListFile),
              options: _lists.map((item) => item.filename).toList(),
              value: _selected!,
              textBuilder: (filename) {
                final item = _lists.firstWhere(
                  (entry) => entry.filename == filename,
                );
                return '${item.filename} · ${item.entries}';
              },
              onChanged: (value) {
                if (_loading || _updating || _updatingHelper) return;
                if (value != _selected) unawaited(_selectList(value));
              },
            ),
          if (_selected != null)
            ListItem(
              leading: const GlyphIcon(AppGlyphs.edit),
              title: Text(AppLocalizations.of(context).forkEditList),
              subtitle: Text(_selected!),
              trailing: const GlyphIcon(AppGlyphs.chevronForward),
              onTap: !_listLoaded || listsBusy
                  ? null
                  : () async {
                      final filename = _selected!;
                      final original = _editor.text;
                      final concurrentEdit = AppLocalizations.of(context).forkConcurrentEdit;
                      await BaseNavigator.push<void>(
                        context,
                        EditorPage(
                          title: filename,
                          content: _editor.text,
                          onSave: (editorContext, title, content) async {
                            final text = await content.readText();
                            await zapretListUpdater.edit(() async {
                              final current = await helperClient.readZapretList(filename);
                              if (!sameZapretList(current.content, original)) {
                                throw StateError(concurrentEdit);
                              }
                              await helperClient.writeZapretList(filename, text);
                            });
                            if (editorContext.mounted) {
                              Navigator.of(editorContext).pop();
                            }
                          },
                        ),
                      );
                      if (mounted) await _loadLists(select: filename);
                    },
            ),
          ListItem(
            leading: const GlyphIcon(AppGlyphs.download),
            title: Text(AppLocalizations.of(context).forkUpdateLists),
            subtitle: Text('${AppLocalizations.of(context).forkUpdateListsHint} · 12 h'),
            trailing: _updating
                ? const SizedBox.square(
                    dimension: 18,
                    child: CommonCircleLoading(size: 18),
                  )
                : null,
            onTap: _lists.isEmpty || listsBusy ? null : _updateLists,
          ),
          ListItem(
            leading: const GlyphIcon(AppGlyphs.refresh),
            title: Text(AppLocalizations.of(context).forkReloadLists),
            subtitle: Text(AppLocalizations.of(context).forkReloadListsHint),
            trailing: _loading && _lists.isNotEmpty
                ? const SizedBox.square(
                    dimension: 18,
                    child: CommonCircleLoading(size: 18),
                  )
                : null,
            onTap: listsBusy ? null : () => _loadLists(),
          ),
        ],
        footer:
            AppLocalizations.of(context).forkListsFooter,
      ),
    ];

    return CommonScaffold(
      title: 'Zapret',
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16).copyWith(
          top: context.sectionsTopPadding,
          bottom: 16 + context.bottomInset,
        ),
        children: sections,
      ),
    );
  }
}

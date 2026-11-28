part of '../action.dart';

typedef ProfileSettingsSource = ({
  int? id,
  DateTime? updatedAt,
  ProfileType? type,
  ExtendType? extendType,
});

ProfileSettingsSource profileSettingsSourceOf(Profile? profile) => (
  id: profile?.id,
  updatedAt: profile?.lastUpdateDate,
  type: profile?.type,
  extendType: profile?.extendType,
);

/// The current subscription's or file's config keys become the app's
/// settings on every update and switch (see [syncProfileSettings]); a custom
/// profile has no file and a scripted one may rewrite the keys, so both skip.
@Riverpod(keepAlive: true)
class ProfileSettingsAction extends _$ProfileSettingsAction {
  CoreController get _core => ref.read(coreHandlerProvider);

  int _generation = 0;

  // Release requests survive a superseding profile read or transient failure.
  final _released = <String>{};

  /// Set when the Core could not be asked; its next connection asks again.
  bool _unread = false;

  @override
  void build() {
    ref.listen(
      currentProfileProvider.select(profileSettingsSourceOf),
      (_, next) => scheduleMicrotask(() {
        if (ref.mounted) unawaited(apply(next));
      }),
    );
    ref.listen(coreStatusProvider, (prev, next) {
      if (_unread &&
          next == CoreStatus.connected &&
          prev != CoreStatus.connected) {
        unawaited(
          apply(profileSettingsSourceOf(ref.read(currentProfileProvider))),
        );
      }
    });
    scheduleMicrotask(() {
      if (ref.mounted) {
        unawaited(apply(profileSettingsSourceOf(ref.read(currentProfileProvider))));
      }
    });
  }

  Future<void> apply(ProfileSettingsSource source, {Set<String> released = const {}}) async {
    if (!ref.mounted) return;
    _released.addAll(released.where(isClashOwnershipKey));
    final id = source.id;
    final generation = ++_generation;
    _unread = false;
    final hasSource = id != null &&
        source.type != ProfileType.custom && source.extendType != ExtendType.script;
    final previousSource = ref.read(yamlSectionSourcesProvider);
    // Retain the last successful source on refresh of the same profile.
    // An in-flight or failed update must not temporarily expose inherited
    // keys as absent or allow an accidental duplicate override.
    if (!hasSource || previousSource?.profileId != id) {
      ref.read(yamlSettingReferencesProvider.notifier).set(null);
      ref.read(yamlSectionSourcesProvider.notifier).set(null);
    }
    if (id == null ||
        source.type == ProfileType.custom ||
        source.extendType == ExtendType.script) {
      // Returning a locally owned setting when there is no YAML source
      // means restoring its app default, not silently keeping the old value.
      final reset = _released.difference(ref.read(appSettingProvider).ownedSettings);
      if (reset.isNotEmpty) {
        ref.read(patchClashConfigProvider.notifier).update(
          (state) => keepOwnedSettings(defaultClashConfig, state, reset),
        );
        if (reset.contains(clashSettingKey('authentication'))) {
          ref.read(networkSettingProvider.notifier).update(
            (state) => state.copyWith(authentication: const AuthenticationProps()),
          );
        }
      }
      _released.clear();
      ref.read(yamlSettingReferencesProvider.notifier).set(const {});
      ref.read(managedClashKeysProvider.notifier).set(const {});
      ref.read(globalOverrideProvider.notifier).value = false;
      return;
    }
    final ProfileBase base;
    try {
      base = (await _core.getProfileBase(id)).base;
    } catch (error) {
      commonPrint.log(
        'profile $id settings not read: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      if (ref.mounted && generation == _generation) {
        _unread = true;
      }
      return;
    }
    if (!ref.mounted || generation != _generation) {
      return;
    }
    final modes = ref.read(availableModesProvider);
    final named = base.present.toSet().intersection(managedClashKeys);
    final settings = ref.read(appSettingProvider);
    final previous = previousYamlSources(settings.panelSetSettings);
    final releasedSnapshot = Set<String>.of(_released);
    final current = ref.read(patchClashConfigProvider);
    final inherited = syncProfileSettings(current, base.config, base.present, modes: modes);
    final inheritedAuthentication = authenticationFrom(base.config['authentication']);
    final owned = {
      ...settings.ownedSettings,
      if (!hasYamlSourceVersion(settings.panelSetSettings))
        ...legacyLocalClashKeys(current,
          ref.read(networkSettingProvider).authentication, named,
          inherited: inherited, inheritedAuthentication: inheritedAuthentication).difference(releasedSnapshot),
    };
    final kept = keptClashKeys(named: named, previous: previous, owned: owned, released: releasedSnapshot);
    final resetMissing = {
      for (final key in releasedSnapshot)
        if (!owned.contains(key) && !named.contains(key.substring(6))) key,
    };
    ref.read(appSettingProvider.notifier).update((state) => state.copyWith(
      ownedSettings: owned,
      panelSetSettings: withYamlSources(state.panelSetSettings, named),
    ));
    ref
        .read(managedClashKeysProvider.notifier)
        .set(managedClashKeysOf(base.present));
    ref.read(globalOverrideProvider.notifier).value = base.globalOverride;
    ref
        .read(patchClashConfigProvider.notifier)
        .update(
          (state) {
            final merged = keepOwnedSettings(
              state,
              keepOwnedSettings(defaultClashConfig,
                syncProfileSettings(state, base.config, base.present, modes: modes),
                resetMissing),
              kept,
            );
            return system.isWindows
                ? withProfileGeoUrls(merged, base.sourceSettings['geox-url'])
                : merged;
          },
        );
    if (!kept.contains(clashSettingKey('authentication'))) {
      ref
          .read(networkSettingProvider.notifier)
          .update(
            (state) => state.copyWith(
              authentication: authenticationFrom(base.config['authentication']),
            ),
          );
    }
    ref.read(yamlSettingReferencesProvider.notifier).set(
      yamlSettingReferences(inherited, inheritedAuthentication, named),
    );
    ref.read(yamlSectionSourcesProvider.notifier).set(yamlSectionSourcesOf(id, base.sourceSettings, defaults: {for (final key in ['dns','tun','profile','experimental','sniffer','ntp',...additionalMihomoKeys.keys.where((key) => !key.contains('.'))]) if (base.config.containsKey(key)) key: base.config[key]}));
    _released.removeAll(releasedSnapshot);
  }
}

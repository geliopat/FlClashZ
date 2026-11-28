part of '../action.dart';

@Riverpod(keepAlive: true)
class ResourcesAction extends _$ResourcesAction {
  var _autoUpdating = false;
  Timer? _timer;
  final _newProfiles = <int, Set<String>>{};
  int? _appliedProfileId;
  bool _refreshingProfile = false;
  int _appliedGeneration = 0;

  @override
  void build() {
    ref.onDispose(() => _timer?.cancel());
    ref.listen(coreStatusProvider, (before, after) {
      if (before != after && after != CoreStatus.connected) {
        _appliedProfileId = null;
        _appliedGeneration++;
      }
    });
  }

  /// One timer, also while the window is hidden. Core owns its Geo and
  /// native provider timers; this pass covers application-managed resources.
  void startAutoUpdates() {
    if (!system.isWindows) return;
    _timer ??= Timer.periodic(const Duration(minutes: 1), (_) {
      if (ref.mounted && ref.read(initProvider)) unawaited(autoUpdate());
    });
  }

  void profileAdded(int id) {
    _newProfiles.putIfAbsent(id, () => <String>{});
  }

  void profileRemoved(int id) {
    _newProfiles.remove(id);
    if (_appliedProfileId == id) {
      _appliedProfileId = null;
      _appliedGeneration++;
    }
  }

  /// Geo RPC acknowledgement is not the download result. Only the final
  /// event may mark a resource complete; failures remain eligible for retry.
  void geoCompleted(GeoResource type, String? error) {
    final id = _appliedProfileId;
    if (id == null || !_currentApplied(id)) return;
    final completed = _newProfiles[id];
    if (completed == null) return;
    if (error == null || error.isEmpty) {
      completed.add(type.updatingKey);
    } else {
      completed.remove(type.updatingKey);
    }
  }

  Future<void> profileApplied(int? id) async {
    if (_appliedProfileId != id) _appliedGeneration++;
    _appliedProfileId = id;
    if (id != null && _newProfiles.containsKey(id)) {
      await _refreshNewProfile();
    }
  }

  bool _currentApplied(int id) => ref.mounted &&
      _appliedProfileId == id &&
      ref.read(currentProfileIdProvider) == id &&
      ref.read(coreStatusProvider) == CoreStatus.connected &&
      !ref.read(safeModeProvider);

  /// Only the applied profile's HTTP providers can be refreshed by the Core.
  /// Do not switch profiles or reload a config just to fetch its resources.
  Future<void> _refreshNewProfile() async {
    final id = _appliedProfileId;
    if (id == null || _refreshingProfile || !_currentApplied(id)) return;
    final completed = _newProfiles[id];
    if (completed == null) return;
    _refreshingProfile = true;
    final generation = _appliedGeneration;
    bool current() => _appliedGeneration == generation && _currentApplied(id);
    try {
      final core = ref.read(coreHandlerProvider);
      final providers = await core.getExternalProviders();
      if (!current()) return;
      var allAccepted = true;
      // Start geo downloads before waiting for remote providers.
      if (ref.read(patchClashConfigProvider).geoAutoUpdate) {
        final geo = ref.read(geoResourceActionProvider.notifier);
        for (final type in GeoResource.values) {
          if (!current()) return;
          final key = type.updatingKey;
          if (completed.contains(key)) continue;
          if (!ref.read(updatingKeysProvider).contains(key)) {
            await _tryUpdate(type.name, () =>
                geo.updateGeoResource(type, announceSuccess: false));
          }
          // A concurrent update and an accepted RPC are both still pending.
          if (!completed.contains(key)) allAccepted = false;
        }
      }
      for (final provider in providers) {
        if (!current()) return;
        if (provider.vehicleType.toLowerCase() != 'http') continue;
        final key = provider.updatingKey;
        if (completed.contains(key)) continue;
        if (ref.read(updatingKeysProvider).contains(key)) {
          allAccepted = false;
          continue;
        }
        if (await _tryUpdate(provider.name, () async {
          final message = await ref.read(proxiesActionProvider.notifier)
              .updateProvider(provider, showLoading: true);
          if (message.isNotEmpty) throw MessageException(message);
        })) {
          if (!current()) return;
          completed.add(key);
        } else {
          allAccepted = false;
        }
      }
      if (allAccepted && current()) _newProfiles.remove(id);
    } catch (error) {
      commonPrint.log('profile resources: ${compactError(error)}',
          logLevel: LogLevel.warning);
    } finally {
      _refreshingProfile = false;
      if (ref.mounted && generation != _appliedGeneration) {
        unawaited(_refreshNewProfile());
      }
    }
  }

  Future<void> updateIconSet(IconSet iconSet) {
    return _track(
      iconSet.updatingKey,
      () => ref.read(iconSetsActionProvider.notifier).sync(iconSet),
    );
  }

  Future<void> updateRuleProvider(ClashProvider provider) {
    return _track(
      provider.updatingKey,
      () => ref
          .read(clashProvidersActionProvider.notifier)
          .putProvider(provider, previous: provider, refresh: true),
    );
  }

  Future<void> updateScript(Script script) {
    return ref.read(scriptsActionProvider.notifier).updateScript(script);
  }

  Future<void> _track(String key, Future<Object?> Function() task) async {
    final updatingKeys = ref.read(updatingKeysProvider.notifier);
    final operation = updatingKeys.start(key);
    try {
      await task();
    } finally {
      updatingKeys.stop(key, operation);
    }
  }

  /// A geo file fails here only when the Core turns the request down; a
  /// download that fails later reaches the user from [GeoResourceAction].
  Future<List<UpdatingMessage>> updateAll() async {
    final appLocalizations = currentAppLocalizations;
    final geoResourceAction = ref.read(geoResourceActionProvider.notifier);
    final failures = <UpdatingMessage>[];
    Future<void> update(
      String key,
      String label,
      Future<void> Function() task,
    ) async {
      if (ref.read(updatingKeysProvider).contains(key)) {
        return;
      }
      try {
        await task();
      } catch (e) {
        failures.add(
          UpdatingMessage(
            label: label,
            message: userFacingErrorMessage(e, appLocalizations),
          ),
        );
      }
    }

    final (iconSets, scripts, providers) = await (
      database.iconSetsDao.query().get(),
      database.scriptsDao.query().get(),
      database.clashProvidersDao.query().get(),
    ).wait;
    await Future.wait([
      for (final geoResource in GeoResource.values)
        update(
          geoResource.updatingKey,
          geoResource.name,
          () => geoResourceAction.updateGeoResource(
            geoResource,
            announceSuccess: false,
          ),
        ),
      for (final iconSet in iconSets)
        if (iconSet.isRemote)
          update(
            iconSet.updatingKey,
            iconSet.name,
            () => updateIconSet(iconSet),
          ),
      for (final provider in providers)
        if (provider.isRemote)
          update(
            provider.updatingKey,
            provider.label,
            () => updateRuleProvider(provider),
          ),
      for (final script in scripts)
        if (script.url != null)
          update(script.updatingKey, script.label, () => updateScript(script)),
    ]);
    return failures;
  }

  /// Geo files are left to the Core, which reads the same two settings.
  Future<void> autoUpdate() async {
    if (!ref.mounted || ref.read(safeModeProvider)) return;
    await _refreshNewProfile();
    if (!ref.mounted) return;
    final setting = ref.read(patchClashConfigProvider);
    if (!setting.geoAutoUpdate || setting.geoUpdateInterval <= 0 || _autoUpdating) {
      return;
    }
    _autoUpdating = true;
    try {
      final interval = Duration(hours: setting.geoUpdateInterval);
      bool isDue(DateTime? lastUpdateTime) =>
          lastUpdateTime?.add(interval).isBeforeNow ?? true;
      for (final iconSet in await database.iconSetsDao.query().get()) {
        if (!ref.mounted || ref.read(safeModeProvider)) return;
        if (iconSet.isRemote &&
            !ref.read(updatingKeysProvider).contains(iconSet.updatingKey) &&
            isDue(iconSet.lastUpdateTime)) {
          await _tryUpdate(iconSet.name, () => updateIconSet(iconSet));
        }
      }
      for (final script in await database.scriptsDao.query().get()) {
        if (!ref.mounted || ref.read(safeModeProvider)) return;
        if (script.url != null &&
            !ref.read(updatingKeysProvider).contains(script.updatingKey) &&
            isDue(script.lastUpdateTime)) {
          await _tryUpdate(script.label, () => updateScript(script));
        }
      }
      for (final provider in await database.clashProvidersDao.query().get()) {
        if (!ref.mounted || ref.read(safeModeProvider) ||
            ref.read(coreStatusProvider) != CoreStatus.connected) {
          break;
        }
        if (provider.isRemote &&
            !ref.read(updatingKeysProvider).contains(provider.updatingKey) &&
            isDue((await provider.fileInfo)?.lastModified)) {
          await _tryUpdate(provider.label, () => updateRuleProvider(provider));
        }
      }
    } catch (error) {
      commonPrint.log('resource timer: ${compactError(error)}',
          logLevel: LogLevel.warning);
    } finally {
      _autoUpdating = false;
    }
  }

  Future<bool> _tryUpdate(String label, Future<void> Function() update) async {
    try {
      await update();
      return true;
    } catch (e) {
      commonPrint.log(
        'auto update $label: ${compactError(e)}',
        logLevel: LogLevel.warning,
      );
      return false;
    }
  }
}

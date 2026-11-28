part of '../action.dart';

@Riverpod(keepAlive: true)
class GeoResourceAction extends _$GeoResourceAction {
  /// Whether each manual update announces a success; a failure always shows.
  final _manualUpdates = <GeoResource, bool>{};
  final _operations = <GeoResource, int>{};
  final _requests = <GeoResource, int>{};
  int _nextRequest = 0;

  CoreController get _core => ref.read(coreHandlerProvider);

  @override
  void build() {
    ref.listen(coreStatusProvider, (_, next) {
      if (next != CoreStatus.connected) {
        _manualUpdates.clear();
        _operations.clear();
        _requests.clear();
      }
    });
  }

  /// The stale sweep drops an update's key when its end never arrived, while
  /// its token stays here and would keep the next update from showing.
  bool _isRunning(GeoResource geoResource) {
    if (_operations.containsKey(geoResource) &&
        !ref.read(updatingKeysProvider).contains(geoResource.updatingKey)) {
      _operations.remove(geoResource);
    }
    return _operations.containsKey(geoResource);
  }

  int _startUpdating(GeoResource geoResource) {
    _isRunning(geoResource);
    return _operations.putIfAbsent(
      geoResource,
      () => ref
          .read(updatingKeysProvider.notifier)
          .start(geoResource.updatingKey, scope: UpdatingScope.core),
    );
  }

  void _stopUpdating(GeoResource geoResource, [int? operation]) {
    final current = _operations[geoResource];
    if (current == null || (operation != null && current != operation)) {
      return;
    }
    _operations.remove(geoResource);
    ref
        .read(updatingKeysProvider.notifier)
        .stop(geoResource.updatingKey, current);
  }

  /// Completes once the Core has accepted the update, not once it finishes.
  /// Completion arrives as a geo-update event through [handleCoreUpdate];
  /// callers that need it watch [isUpdatingProvider] for the key to clear.
  /// A request the Core turns down leaves an update already running as it
  /// was.
  Future<void> updateGeoResource(
    GeoResource geoResource, {
    bool announceSuccess = true,
  }) async {
    final running = _isRunning(geoResource);
    final previous = _manualUpdates[geoResource];
    _manualUpdates[geoResource] = announceSuccess;
    final operation = _startUpdating(geoResource);
    final request = ++_nextRequest;
    _requests[geoResource] = request;
    try {
      final message = await _core.updateGeoData(geoResource.name);
      if (message.isNotEmpty) {
        throw MessageException(message);
      }
    } catch (_) {
      // A late rejection must not resurrect feedback after completion,
      // disconnect, or a newer request for the same resource.
      if (!ref.mounted || _requests[geoResource] != request ||
          _operations[geoResource] != operation) rethrow;
      if (previous != null) {
        _manualUpdates[geoResource] = previous;
      } else {
        _manualUpdates.remove(geoResource);
      }
      if (!running) {
        _stopUpdating(geoResource, operation);
        _requests.remove(geoResource);
      }
      rethrow;
    }
  }

  void handleCoreUpdate(
    String geoType,
    bool updating,
    bool skipped,
    String? error,
  ) {
    final geoResource = GeoResource.fromJson(geoType.toLowerCase());
    final announceSuccess = updating
        ? null
        : _manualUpdates.remove(geoResource);
    if (announceSuccess != null && error != null && error.isNotEmpty) {
      dialogs.showNotifier(error, level: MessageLevel.error);
    } else if (announceSuccess == true) {
      final l10n = currentAppLocalizations;
      final message = skipped
          ? l10n.geoSkipped(geoResource.name)
          : l10n.geoUpdated(geoResource.name);
      dialogs.showNotifier(message);
    }
    if (updating) {
      _startUpdating(geoResource);
      if (system.isWindows) {
        ref.read(resourcesActionProvider.notifier).geoStarted(geoResource);
      }
    } else {
      _requests.remove(geoResource);
      _stopUpdating(geoResource);
      if (system.isWindows) {
        ref.read(resourcesActionProvider.notifier).geoCompleted(geoResource, error);
      }
    }
  }

  void updateGeoResourceUrl(GeoResource geoResource, String newUrl) {
    final sources = ref.read(yamlSectionSourcesProvider);
    if (system.isWindows && sources?.profileId == ref.read(currentProfileIdProvider) &&
        profileGeoUrls(sources?.explicit['geox-url']).containsKey(geoResource)) {
      throw StateError('This resource source is defined by the subscription');
    }
    if (!newUrl.isUrl) {
      throw ArgumentError.value(newUrl, 'newUrl', 'Not a valid URL');
    }
    ref.read(patchClashConfigProvider.notifier).update((state) {
      return state.copyWith(geoXUrl: {...state.geoXUrl, geoResource: newUrl});
    });
  }
}

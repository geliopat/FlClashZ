part of '../action.dart';

enum _SetupTaskResult { completed, handoffToCoreRestart, failed }

typedef _SetupInputs = (
  SetupState,
  PatchClashConfig,
  NetworkProps,
  SetupParams,
);

typedef BuiltProfile = ({
  String yaml,
  String md5,
  ConfigCounts counts,
  SetupBase? base,
});

class _RunRequest {
  final bool running;
  final bool initialize;

  /// Adopts a run the Android service has, config and groups alike.
  final bool resume;
  final DateTime? previousStartTime;
  final bool undoesFailedStart;
  final void Function(Object)? onZapretStopError;

  const _RunRequest({
    required this.running,
    required this.initialize,
    required this.resume,
    required this.previousStartTime,
    this.undoesFailedStart = false,
    this.onZapretStopError,
  });
}

@Riverpod(keepAlive: true)
class SetupAction extends _$SetupAction {
  CoreController get _core => ref.read(coreHandlerProvider);

  Timer? _runtimeTimer;
  final _setupScheduler = SerialTaskScheduler();
  final _listenerScheduler = SerialTaskScheduler();
  _RunRequest? _latestRunRequest;
  DateTime? _startTime;
  _SetupInputs? _appliedInputs;
  final _builtHostCandidates = <String, HostCandidates>{};
  HostCandidates _appliedHostCandidates = const {};
  HostCandidates get appliedHostCandidates => _appliedHostCandidates;
  var _lastPushDuration = Duration.zero;
  var _pendingForceApply = false;
  var _pushes = 0;
  var _coreGeneration = 0;
  var _tunMissed = false;
  var _configRequests = 0;
  var _setupAfterInit = false;
  Completer<void>? _initialized;
  bool get _exiting => !ref.mounted || ref.read(systemActionProvider.notifier).isExiting;

  void quiesceForExit() {
    _stopRuntimeTicker();
    debouncer.cancel(FunctionTag.applyProfile);
    debouncer.cancel(FunctionTag.updateConfig);
    debouncer.cancel(FunctionTag.suspend);
    _pendingForceApply = false;
    _setupAfterInit = false;
    _initialized?.complete();
    _initialized = null;
  }

  /// Moves as each config push starts and again once the Core answers it.
  int get pushes => _pushes;

  /// A start, stop or restart of the listeners has not finished yet.
  bool get isChangingRun => _listenerScheduler.isBusy;

  bool get _isRunning => _startTime != null && _startTime!.isBeforeNow;

  @override
  void build() {
    ref.onDispose(_stopRuntimeTicker);
    ref.listen(coreStatusProvider, (before, after) {
      if (before == after || !system.isWindows) return;
      _coreGeneration++;
      // A different core process cannot inherit an acknowledged apply.
      _appliedInputs = null;
      _appliedHostCandidates = const {};
      globalState.lastConfigMd5 = null;
      globalState.lastConfigCounts = null;
    });
    ref.listen(appVisibleProvider, (_, _) => _syncRuntimeTicker());
    ref.listen(
      appSettingProvider.select((state) => state.showTrayTitle),
      (_, _) => _syncRuntimeTicker(),
    );
    ref.listen(initProvider, (_, initialized) {
      if (initialized) {
        _initialized?.complete();
        _initialized = null;
      }
      if (initialized && _setupAfterInit) {
        _setupAfterInit = false;
        unawaited(fullSetup());
      }
    });
  }

  bool get _isTrafficShown =>
      ref.read(appVisibleProvider) ||
      (system.isWindows && !ref.read(safeModeProvider)) ||
      (system.isMacOS &&
          !ref.read(safeModeProvider) &&
          ref.read(appSettingProvider).showTrayTitle);

  SetupParams get _setupParams {
    final selectedMap = ref.read(selectedMapProvider);
    final appSetting = ref.read(appSettingProvider);
    return SetupParams(
      selectedMap: selectedMap,
      testUrl: appSetting.testUrl,
      skipCertVerify: !appSetting.checkCertificate,
    );
  }

  // The selection reaches the Core through changeProxy, not through an apply.
  SetupParams get _appliedParams =>
      _setupParams.copyWith(selectedMap: const {});

  Future<bool> fullSetup() async {
    if (_exiting) return false;
    // Startup may already be applying the profile this replaces.
    if (!ref.read(initProvider)) {
      _setupAfterInit = true;
      return true;
    }
    ref.read(proxiesActionProvider.notifier).cancelDelayTests();
    ref.read(delayDataSourceProvider.notifier).value = {};
    final setupResult = applyProfile(force: true);
    ref.read(logsProvider.notifier).value = FixedList(maxLogsLength);
    ref.read(requestsProvider.notifier).value = FixedList(maxRequestsLength);
    ref.read(dnsQueriesProvider.notifier).value = FixedList(
      maxDnsQueriesLength,
    );
    ref.read(dnsQueryCountProvider.notifier).value = 0;
    ref.read(requestCountProvider.notifier).value = 0;
    try {
      return await setupResult;
    } catch (e, s) {
      commonPrint.log('fullSetup ===> ${compactError(e)}, $s');
      return false;
    }
  }

  void _setLocalRunning(bool running) {
    _stopRuntimeTicker();
    if (!running) {
      _startTime = null;
      debouncer.cancel(FunctionTag.applyProfile);
      _pendingForceApply = false;
      _updateRunTime();
      return;
    }

    _startTime ??= DateTime.now();
    _updateRunTime();
    _syncRuntimeTicker();
  }

  void _syncRuntimeTicker() {
    if (_exiting || _startTime == null || !_isTrafficShown) {
      _stopRuntimeTicker();
      return;
    }
    if (_runtimeTimer != null) {
      return;
    }
    _refreshRunningState();
    _runtimeTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _refreshRunningState(),
    );
  }

  void _stopRuntimeTicker() {
    _runtimeTimer?.cancel();
    _runtimeTimer = null;
  }

  void _refreshRunningState() {
    _updateRunTime();
    unawaited(ref.read(commonActionProvider.notifier).updateTraffic());
  }

  void _updateRunTime() {
    final startTime = _startTime;
    ref.read(runTimeProvider.notifier).value = startTime == null
        ? null
        : DateTime.now().millisecondsSinceEpoch -
              startTime.millisecondsSinceEpoch;
  }

  @protected
  Future<DateTime?> serviceStartTime() async => service?.getRunTime();

  Future<void> initStatus() async {
    if (!globalState.needInitStatus) {
      return;
    }
    final intent = _latestRunRequest;
    final startTime = await serviceStartTime();
    final appliedMd5 = startTime != null && startTime.isBeforeNow
        ? await preferences.getAppliedConfigMd5()
        : null;
    if (!identical(_latestRunRequest, intent)) {
      await globalState.safeRun(() => applyProfile(force: true));
      return;
    }
    _startTime = startTime;
    if (_isRunning) {
      globalState.lastConfigMd5 = appliedMd5;
      await _run(true, initialize: true, resume: true);
    } else if (ref.read(appSettingProvider).autoRun) {
      await setRunning(true, initialize: true);
    } else {
      await globalState.safeRun(() => applyProfile(force: true));
    }
  }

  Future<bool> setRunning(bool running, {bool initialize = false}) async {
    if (_exiting) return false;
    if (running && !initialize && !ref.read(initProvider)) {
      // A start from Quick Settings, automation or Always-on can arrive while
      // startup is still deciding the run; it waits for that, and yields to
      // whatever command startup or the user gave since.
      final before = _latestRunRequest;
      await (_initialized ??= Completer<void>()).future;
      if (_exiting) return false;
      if (!identical(_latestRunRequest, before)) {
        return true;
      }
    }
    return _run(running, initialize: running && initialize);
  }

  /// Explicit tray start forces Zapret even when its automatic-start
  /// preference is disabled. Stop still disconnects the VPN if Zapret
  /// cannot confirm shutdown, and reports that failure afterwards.
  Future<bool> setTrayRunning(bool running) async {
    Object? stopError;
    final success = await _run(
      running,
      initialize: running && !ref.read(initProvider),
      forceZapret: running,
      onZapretStopError: (error) => stopError = error,
    );
    if (stopError case final error?) {
      if (error is Exception) throw error;
      if (error is Error) throw error;
      throw StateError(error.toString());
    }
    return success;
  }

  Future<bool> _run(
    bool running, {
    required bool initialize,
    bool resume = false,
    bool undoesFailedStart = false,
    bool forceZapret = false,
    void Function(Object)? onZapretStopError,
  }) {
    if (_exiting) return Future.value(false);
    final request = _RunRequest(
      running: running,
      initialize: initialize,
      resume: resume,
      previousStartTime: _startTime,
      undoesFailedStart: undoesFailedStart,
      onZapretStopError: onZapretStopError,
    );
    _latestRunRequest = request;
    _setLocalRunning(running);
    if (request.initialize) {
      globalState.needInitStatus = false;
    }
    if (!running) return _stop(request);
    return _start(request).then((success) async {
      if (success && system.isWindows && _isCurrent(request) &&
          (request.previousStartTime == null || forceZapret) && !request.resume &&
          !ref.read(safeModeProvider)) {
        try {
          await ref.read(zapretControllerProvider.notifier)
              .startAlongsideMihomo(force: forceZapret);
          if (forceZapret && _isCurrent(request) &&
              !ref.read(zapretControllerProvider).running) {
            throw StateError(ref.read(zapretControllerProvider).error ??
                currentAppLocalizations.forkLaunchUnavailable);
          }
        } catch (error) {
          commonPrint.log('Linked Zapret start failed: $error', logLevel: LogLevel.warning);
          if (forceZapret && _isCurrent(request)) rethrow;
        }
      }
      return success;
    });
  }

  Future<bool> _start(_RunRequest request) async {
    if (request.initialize) {
      var applied = false;
      try {
        applied = await applyProfile(
          force: !request.resume,
          preloadInvoke: () => _startCoreRunning(request),
        );
      } catch (_) {
        applied = false;
      }
      if (!applied && _isCurrent(request)) {
        await globalState.safeRun(
          () => _run(false, initialize: false, undoesFailedStart: true),
        );
      }
      return applied;
    }

    try {
      await _startCoreRunning(request);
    } catch (_) {
      _rollbackRunning(request);
      rethrow;
    }
    _reconcileTun();
    final applied = await inputsApplied();
    if (_isCurrent(request) && !applied) {
      applyProfileDebounce(force: true, silence: true);
    }
    return true;
  }

  Future<void> _startCoreRunning(_RunRequest request) async {
    if (!await _setCoreRunning(request) && _isCurrent(request)) {
      throw _unanswered(CoreMethod.startListener);
    }
  }

  Future<bool> _stop(_RunRequest request) async {
    final bool answered;
    try {
      answered = await _setCoreRunning(request);
    } catch (_) {
      _rollbackRunning(request);
      rethrow;
    }
    if (!_isCurrent(request)) {
      return true;
    }
    await _clearTraffic(request, capture: answered);
    // A silent Core is gone or hung; running again would proxy traffic to it.
    if (!answered) {
      throw _unanswered(CoreMethod.stopListener);
    }
    return true;
  }

  Future<void> _clearTraffic(_RunRequest request, {bool capture = true}) async {
    if (system.isWindows && capture &&
        ref.read(coreStatusProvider) == CoreStatus.connected) {
      await ref.read(commonActionProvider.notifier).updateTraffic();
      if (!ref.mounted || !_isCurrent(request)) return;
    }
    if (!ref.mounted || !_isCurrent(request)) return;
    final history = system.isWindows && !ref.read(safeModeProvider)
        ? ref.read(trafficHistoryProvider)
        : null;
    final reset = history?.beginReset();
    var confirmed = false;
    try {
      await resetCoreTraffic();
      confirmed = true;
    } catch (error) {
      commonPrint.log('Traffic reset: ${compactError(error)}',
          logLevel: LogLevel.warning);
    } finally {
      if (reset != null) {
        history!.finishReset(reset, confirmed: confirmed);
      }
    }
    if (!ref.mounted || !_isCurrent(request)) return;
    ref.read(trafficsProvider.notifier).clear();
    ref.read(totalTrafficProvider.notifier).value = const Traffic();
  }

  Future<bool> _setCoreRunning(_RunRequest request) {
    return _listenerScheduler.run(() async {
      if (!_isCurrent(request)) {
        return true;
      }
      if (request.running && ref.read(suspendProvider)) {
        return true;
      }
      if (ref.read(safeModeProvider)) {
        return true;
      }
      if (!request.running && system.isWindows) {
        try {
          await ref.read(zapretControllerProvider.notifier).stopAlongsideMihomo();
        } catch (error) {
          commonPrint.log('Linked Zapret stop failed: $error', logLevel: LogLevel.warning);
          request.onZapretStopError?.call(error);
        }
        if (!_isCurrent(request)) return true;
      }
      return _setListening(request.running);
    });
  }

  Future<bool> _setListening(bool running) async {
    final vpnOptions = await ref.read(vpnOptionsProvider.future);
    final answered = await setCoreRunning(running);
    ref.read(runningVpnOptionsProvider.notifier).value = running && answered
        ? vpnOptions
        : null;
    return answered;
  }

  CoreMethodException _unanswered(CoreMethod method) => CoreMethodException(
    code: 'no_response',
    message: 'Core did not answer ${method.name}',
  );

  /// An excluded SSID parks the listener without ending the run.
  void syncSuspend() {
    if (_exiting) return;
    debouncer.call(FunctionTag.suspend, () {
      return _listenerScheduler.run(() async {
        if (_exiting || !ref.read(isStartProvider) || ref.read(safeModeProvider)) {
          return;
        }
        await _setListening(!ref.read(suspendProvider));
      });
    });
  }

  Future<void> restartVpn() async {
    if (_exiting) return;
    if (!ref.read(isStartProvider)) {
      return;
    }
    final request = _RunRequest(
      running: true,
      initialize: false,
      resume: false,
      previousStartTime: _startTime,
    );
    _latestRunRequest = request;
    _startTime = null;
    _setLocalRunning(true);
    final bool? answered;
    try {
      answered = await _listenerScheduler.run(() async {
        if (!_isCurrent(request) ||
            ref.read(suspendProvider) ||
            ref.read(safeModeProvider)) {
          return null;
        }
        final vpnOptions = await ref.read(vpnOptionsProvider.future);
        var restartZapret = false;
        if (system.isWindows) {
          try {
            restartZapret = await ref.read(zapretControllerProvider.notifier).stopAlongsideMihomo();
          } catch (error) {
            commonPrint.log('VPN restart postponed: Zapret stop not confirmed: $error', logLevel: LogLevel.warning);
            return false;
          }
        }
        if (!_isCurrent(request)) return null;
        final answered = await restartCoreRunning();
        if (answered) {
          ref.read(runningVpnOptionsProvider.notifier).value = vpnOptions;
          if (system.isWindows && _isCurrent(request)) {
            await ref.read(zapretControllerProvider.notifier).startAlongsideMihomo(force: restartZapret).catchError((Object error) {
              commonPrint.log('Linked Zapret restart failed: $error', logLevel: LogLevel.warning);
            });
          }
        }
        return answered;
      });
    } catch (_) {
      _keepRunning(request);
      rethrow;
    }
    if (answered == null || !_isCurrent(request)) {
      return;
    }
    if (!answered) {
      _keepRunning(request);
      throw _unanswered(CoreMethod.startListener);
    }
    await _clearTraffic(request);
  }

  void _keepRunning(_RunRequest request) {
    if (_isCurrent(request)) {
      _startTime = request.previousStartTime;
      _setLocalRunning(true);
    }
  }

  void _rollbackRunning(_RunRequest request) {
    if (!_isCurrent(request)) {
      return;
    }
    _startTime = request.previousStartTime;
    _setLocalRunning(!request.running);
  }

  bool _isCurrent(_RunRequest request) => !_exiting && identical(_latestRunRequest, request);

  /// Identity of the latest run request, answered or rolled back alike.
  Object? get runIntent => _latestRunRequest;

  /// A stop that undid a failed start leaves the run still asked for.
  bool? get requestedRunning {
    final request = _latestRunRequest;
    return request == null
        ? null
        : request.running || request.undoesFailedStart;
  }

  Future<void> updateConfigDebounce() async {
    if (_exiting) return;
    _configRequests++;
    debouncer.call(FunctionTag.updateConfig, updateConfig);
  }

  @protected
  Future<bool> setCoreRunning(bool running) {
    return running ? _core.startListener() : _core.stopListener();
  }

  @protected
  Future<bool> restartCoreRunning() => _core.restartListener();

  @protected
  FutureOr<void> resetCoreTraffic() => _core.resetTraffic();

  @visibleForTesting
  Future<void> updateConfig() async {
    if (_exiting) return;
    _configRequests++;
    await globalState.safeRun(() async {
      final patchConfig = ref.read(patchClashConfigProvider);
      final shouldContinueSetup = await requestAdmin(patchConfig.tun.enable);
      if (!shouldContinueSetup) {
        await _restartCoreAfterAuthorization();
        return;
      }
      // Behind the apply in flight: until its push lands the Core has no
      // config to update and answers "config is not applied".
      final message = await _setupScheduler.run(() {
        if (_exiting) return Future.value('');
        final networkSetting = ref.read(networkSettingProvider);
        return _core.updateConfig(
          _effectivePatchConfig(
            ref.read(patchClashConfigProvider),
          ).toUpdateParams(
            authentication: networkSetting.authentication.credentials,
            skipCertVerify: !ref.read(appSettingProvider).checkCertificate,
          ),
        );
      });
      if (message.isNotEmpty) throw MessageException(message);
      _reconcileTun();
    });
  }

  @protected
  Duration get minApplyDebounce => const Duration(seconds: 2);

  /// A push held up by a rule-set download or a Core timeout says little
  /// about the load, yet would hold back every apply after it.
  @protected
  Duration get maxApplyDebounce => const Duration(seconds: 10);

  void applyProfileDebounce({bool silence = false, bool force = false}) {
    if (_exiting) return;
    _configRequests++;
    _pendingForceApply |= force;
    debouncer.call(
      FunctionTag.applyProfile,
      (silence) {
        final force = _pendingForceApply;
        _pendingForceApply = false;
        applyProfile(silence: silence, force: force);
      },
      args: [silence],
      duration: Duration(
        microseconds: _lastPushDuration.inMicroseconds.clamp(
          minApplyDebounce.inMicroseconds,
          maxApplyDebounce.inMicroseconds,
        ),
      ),
    );
  }

  /// A mode the user picks in the app, asked first while the subscription
  /// sets it; the tray and hotkeys have nowhere to ask and take it over.
  Future<void> pickMode(Mode mode, {bool ask = true}) async {
    if (!ref.read(availableModesProvider).contains(mode)) return;
    final managed = ref.read(managedSettingsActionProvider.notifier);
    if (!ask) {
      managed.takeOverIfLocked('clash.mode');
    } else if (!await managed.confirmTakeOver('clash.mode')) {
      return;
    }
    changeMode(mode);
    ref.read(profileHeadersActionProvider.notifier).forgetTakenMode();
  }

  void changeMode(Mode mode) {
    if (!ref.read(availableModesProvider).contains(mode)) return;
    ref
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith(mode: mode));
    if (mode == Mode.global) {
      ref
          .read(proxiesActionProvider.notifier)
          .updateCurrentGroupName(GroupName.GLOBAL.name);
    }
  }

  /// For leaving an editor: a profile whose inputs match the config the Core
  /// already runs is not rebuilt, which on a large profile takes a while.
  void autoApplyProfile() {
    runAfterFrame(() async {
      if (!await inputsApplied()) {
        await applyProfile();
      }
    });
  }

  void applyIfGlobalRulesUsed() {
    final profile = ref.read(currentProfileProvider);
    if (profile == null ||
        profile.type == ProfileType.custom ||
        profile.extendType != ExtendType.standard) {
      return;
    }
    applyProfileDebounce(silence: true);
  }

  /// Whether the Core runs what the current profile and settings make now.
  Future<bool> inputsApplied() async {
    final applied = _appliedInputs;
    if (applied == null) {
      return false;
    }
    final profileId = ref.read(currentProfileIdProvider);
    final SetupState setupState;
    try {
      setupState = await ref.read(setupStateProvider(profileId).future);
    } catch (_) {
      return false;
    }
    return applied ==
        (
          setupState,
          _effectivePatchConfig(ref.read(patchClashConfigProvider)),
          ref.read(networkSettingProvider),
          _appliedParams,
        );
  }

  // False means building the profile, the config write, or the Core setup
  // step failed. Windows retains the last accepted profile on build failure;
  // the old non-Windows fallback is kept for its existing service contract.
  // authorizeCore failures still throw.
  Future<bool> applyProfile({
    bool silence = false,
    bool force = false,
    Future<void> Function()? preloadInvoke,
  }) async {
    final result = await _runSetup(
      force: force,
      silence: silence,
      preloadInvoke: preloadInvoke,
    );
    return result != _SetupTaskResult.failed;
  }

  Future<_SetupTaskResult> _runSetup({
    bool silence = false,
    bool force = false,
    Future<void> Function()? preloadInvoke,
  }) async {
    if (_exiting) return _SetupTaskResult.failed;
    _configRequests++;
    final result = await _setupScheduler.run(() {
      if (_exiting) return Future.value(_SetupTaskResult.failed);
      return _setupConfig(
        force: force,
        silence: silence,
        preloadInvoke: preloadInvoke,
        onUpdated: () async {
          await ref.read(proxiesActionProvider.notifier).updateGroups();
          await ref.read(providersProvider.notifier).syncProviders();
        },
      );
    });
    if (result != _SetupTaskResult.handoffToCoreRestart) {
      if (result == _SetupTaskResult.completed) _reconcileTun();
      return result;
    }
    // Release the current serial task before restartCore reapplies the profile.
    final restarted = await _restartCoreAfterAuthorization();
    return restarted ? _SetupTaskResult.completed : _SetupTaskResult.failed;
  }

  Future<bool> _restartCoreAfterAuthorization() async {
    if (_exiting) return false;
    _tunMissed = false;
    final coreAction = ref.read(coreActionProvider.notifier);
    // Awaited from inside its own restore, the restart would wait on itself.
    final underWay = coreAction.requestRelaunch();
    if (underWay != null) {
      unawaited(underWay.then((_) {}, onError: (_) => _reopenAuthorization()));
      return true;
    }
    try {
      return await coreAction.restartCore();
    } catch (_) {
      _reopenAuthorization();
      rethrow;
    }
  }

  void _reopenAuthorization() {
    ref.read(authorizedTunEnableProvider.notifier).value =
        TunAuthorizationState.none;
  }

  /// The Core goes on without a TUN it could not open; the next enable
  /// authorizes again, as the authorization the Core ran under did not hold.
  Future<void> tunFailed() async {
    while (true) {
      if (_exiting) return;
      final tun = ref.read(patchClashConfigProvider).tun;
      final profileId = ref.read(currentProfileIdProvider);
      final requests = _configRequests;
      if (!tun.enable) return;
      // A push still waiting may open the TUN, or skip the Core as unchanged
      // and report nothing, so the Core is asked once it has gone.
      if (_pushWaiting) {
        await Future<void>.delayed(tunRecheckDelay);
        continue;
      }
      if (!await confirmTunFailed() || _exiting) return;
      // A config asked for meanwhile may sit behind the answer, unpushed.
      if (!_pushWaiting &&
          requests == _configRequests &&
          ref.read(patchClashConfigProvider).tun == tun &&
          ref.read(currentProfileIdProvider) == profileId) {
        break;
      }
    }
    _tunMissed = true;
    _reopenAuthorization();
    ref
        .read(patchClashConfigProvider.notifier)
        .update((state) => state.copyWith.tun(enable: false));
    dialogs.showNotifier(
      currentAppLocalizations.tunStartFailed,
      level: MessageLevel.error,
    );
  }

  /// With a base, [BuiltProfile.yaml] is only the overlay the Core applies.
  Future<BuiltProfile> getProfile({
    required SetupState setupState,
    required PatchClashConfig patchConfig,
  }) async {
    final profileId = setupState.profileId;
    if (profileId == null) {
      return (yaml: '', md5: '', counts: configCountsOf(const {}), base: null);
    }
    final defaultUA = globalState.ua;
    final networkSetting = ref.read(
      networkSettingProvider.select(
        (state) => (
          appendSystemDns: state.appendSystemDns,
          bypassPrivateRoute: state.bypassPrivateRoute,
          authentication: state.authentication,
        ),
      ),
    );
    final appendSystemDns = networkSetting.appendSystemDns;
    final isCustom = setupState.profileType == ProfileType.custom;
    final scriptContent =
        !isCustom && setupState.extendType == ExtendType.script
        ? await setupState.script?.content
        : null;
    final hasScript = scriptContent?.isNotEmpty == true;
    // Chains build on the profile's own proxies and groups, which a base
    // leaves out for the Core to merge back in.
    final sourceBase = !isCustom && (system.isWindows || (!hasScript && setupState.proxyChains.isEmpty))
        ? await _core.getProfileBase(profileId)
        : null;
    final profileBase = !hasScript && setupState.proxyChains.isEmpty ? sourceBase : null;
    Map<String, dynamic> rawConfig = isCustom
        ? {
            'proxies': appProxiesPayload(
              setupState.appProxies,
              dialers: setupState.proxyDialers,
              groups: setupState.proxyGroups,
            ),
          }
        : profileBase?.base.config ?? await _core.getConfig(profileId);
    final proxyGroups = isCustom ? setupState.proxyGroups : <ProxyGroup>[];
    final rules = isCustom ? setupState.rules : <Rule>[];
    if (system.isWindows && !isCustom && sourceBase != null) {
      rawConfig = restoreExplicitMihomoSettings(
        rawConfig, sourceBase.base.sourceSettings,
      );
    }
    if (hasScript) {
      rawConfig = await handleEvaluate(scriptContent!, rawConfig);
    }
    HostCandidates? hostCandidates;
    if (system.isWindows && !ref.read(safeModeProvider)) {
      final smart = ref.read(smartHostsProvider);
      hostCandidates = collectHostCandidates(rawConfig['hosts'], patchConfig.hosts, smart.candidates);
      rawConfig = mergeSmartHosts(rawConfig, patchConfig.hosts, smart.entries);
    }
    final directory = await appPath.profilesPath;
    final injected = await _resolveInjectedProviders(
      setupState,
      proxyGroups: proxyGroups,
      rules: rules,
    );
    final matchTarget = setupState.matchTarget?.trim();
    final matchOverride = matchTarget?.isNotEmpty == true ? matchTarget : null;
    final res = await makeRealProfileTask(
      MakeRealProfileState(
        rules: rules,
        proxyGroups: proxyGroups,
        injectedProxyProviders: injected.proxies,
        injectedRuleProviders: injected.rules,
        profilesPath: directory,
        profileId: profileId,
        rawConfig: rawConfig,
        realPatchConfig: system.isWindows && !isCustom
            ? withProfileGeoUrls(patchConfig, hasScript
                ? rawConfig['geox-url'] : sourceBase?.base.sourceSettings['geox-url'])
            : patchConfig,
        overrides: setupState.overrides,
        bypassPrivateRoute: networkSetting.bypassPrivateRoute,
        keepEmptyDnsOverrides: setupState.profileType != ProfileType.custom,
        appendSystemDns: appendSystemDns,
        addedRules: setupState.addedRules,
        defaultUA: defaultUA,
        authentication: networkSetting.authentication.credentials,
        matchTarget:
            matchOverride ??
            (profileBase == null
                ? null
                : lastMatchTarget(profileBase.base.matchRules)),
        safeMode: ref.read(safeModeProvider),
        proxyChains: setupState.proxyChains,
      ),
    );
    if (hostCandidates != null) {
      final digest = profileBase == null
          ? res.md5
          : '${res.md5}${profileBase.base.digest}${matchOverride ?? ''}'.toMd5();
      _builtHostCandidates[digest] = hostCandidates;
      while (_builtHostCandidates.length > 4) {
        _builtHostCandidates.remove(_builtHostCandidates.keys.first);
      }
    }
    if (profileBase == null) {
      return (yaml: res.yaml, md5: res.md5, counts: res.counts, base: null);
    }
    final (:base, :path) = profileBase;
    return (
      yaml: res.yaml,
      md5: '${res.md5}${base.digest}${matchOverride ?? ''}'.toMd5(),
      counts: (
        groups: res.counts.groups + base.proxyGroups,
        proxies: res.counts.proxies + base.proxies,
        rules: res.counts.rules + base.rules,
      ),
      base: SetupBase(
        path: path,
        overlay: res.yaml,
        matchTarget: matchOverride,
      ),
    );
  }

  /// Only what the custom profile actually references is injected, so an
  /// app-level provider costs nothing in the profiles that never name it.
  Future<({Map<String, dynamic> proxies, Map<String, dynamic> rules})>
  _resolveInjectedProviders(
    SetupState setupState, {
    required List<ProxyGroup> proxyGroups,
    required List<Rule> rules,
  }) async {
    final usedProxyProviders = <String>{
      for (final proxyGroup in proxyGroups) ...?proxyGroup.use,
    };
    final usedRuleProviders = <String>{
      for (final rule in rules) ...rule.ruleSets,
      if (setupState.profileType == ProfileType.custom)
        ...setupState.overrides.ruleSets,
    };
    if (usedProxyProviders.isEmpty && usedRuleProviders.isEmpty) {
      return (
        proxies: const <String, dynamic>{},
        rules: const <String, dynamic>{},
      );
    }
    final options = setupState.overrides.proxyProviders;
    final proxies = <String, dynamic>{};
    for (final entry in setupState.profileProviders.entries) {
      if (!usedProxyProviders.contains(entry.key)) {
        continue;
      }
      proxies[entry.key] = {
        'type': 'file',
        'path': await appPath.getProfilePath(entry.value.toString()),
        ...?options[entry.key]?.definition,
      };
    }
    final clashProvidersAction = ref.read(
      clashProvidersActionProvider.notifier,
    );
    final ruleProviders = <String, dynamic>{};
    for (final provider in setupState.clashProviders) {
      if (!usedRuleProviders.contains(provider.label)) {
        continue;
      }
      final prepared = await clashProvidersAction.prepare(provider);
      ruleProviders[prepared.label] = prepared.definition(
        await prepared.corePath,
      );
    }
    return (proxies: proxies, rules: ruleProviders);
  }

  Future<String> getProfileWithId(int profileId) async {
    try {
      final setupState = await ref.read(setupStateProvider(profileId).future);
      final patchClashConfig = ref.read(patchClashConfigProvider);
      final res = await getProfile(
        setupState: setupState,
        patchConfig: patchClashConfig,
      );
      return switch (res.base) {
        final base? => await _core.buildProfile(base),
        null => res.yaml,
      };
    } catch (e) {
      dialogs.showNotifier(e.toString(), level: MessageLevel.error);
    }
    return '';
  }

  PatchClashConfig _effectivePatchConfig(PatchClashConfig patchConfig) {
    if (ref.read(safeModeProvider)) {
      return patchConfig.copyWith(
        tun: patchConfig.tun.copyWith(enable: false),
        externalController: '',
      );
    }
    final authorized =
        ref.read(authorizedTunEnableProvider) ==
        TunAuthorizationState.authorized;
    final secure = ref.read(androidSecureProvider);
    return patchConfig.copyWith(
      tun: patchConfig.tun.copyWith(
        enable: patchConfig.tun.enable && authorized,
      ),
      mixedPort: secure ? 0 : patchConfig.mixedPort,
      port: secure ? 0 : patchConfig.port,
      socksPort: secure ? 0 : patchConfig.socksPort,
      redirPort: secure ? 0 : patchConfig.redirPort,
      tproxyPort: secure ? 0 : patchConfig.tproxyPort,
    );
  }

  /// The event may describe a push a later one replaced.
  @protected
  Future<bool> confirmTunFailed() => _setupScheduler.run(_core.getTunFailed);

  /// A Core drops the event for a TUN it could not open once its queue is
  /// full, so a push that asked for TUN asks after it as well.
  void _reconcileTun() {
    if (!ref.mounted ||
        !coreNeedsAuthorization ||
        ref.read(safeModeProvider) ||
        !ref.read(patchClashConfigProvider).tun.enable) {
      return;
    }
    unawaited(
      tunFailed().catchError((Object error) {
        commonPrint.log('TUN check failed: $error', logLevel: LogLevel.warning);
      }),
    );
  }

  bool get _pushWaiting =>
      debouncer.isPending(FunctionTag.updateConfig) ||
      debouncer.isPending(FunctionTag.applyProfile);

  @protected
  Duration get tunRecheckDelay => const Duration(milliseconds: 300);

  @protected
  Future<AuthorizeCode> authorizeCore() {
    return system.authorizeCore();
  }

  /// Android drives its TUN through the VPN service; the core is never
  /// elevated there, so nothing is asked and the core's own tun stays off.
  @protected
  bool get coreNeedsAuthorization => !system.isAndroid;

  @visibleForTesting
  Future<bool> requestAdmin(bool enableTun) async {
    if (!enableTun || !coreNeedsAuthorization || ref.read(safeModeProvider)) {
      return true;
    }
    final authorizationState = ref.read(authorizedTunEnableProvider);
    if (authorizationState != TunAuthorizationState.none) {
      return true;
    }

    final authorizationNotifier = ref.read(
      authorizedTunEnableProvider.notifier,
    );
    authorizationNotifier.value = TunAuthorizationState.unauthorized;

    final code = await authorizeCore();

    switch (code) {
      case AuthorizeCode.success:
        authorizationNotifier.value = TunAuthorizationState.authorized;
        return false;
      case AuthorizeCode.none:
        authorizationNotifier.value = TunAuthorizationState.authorized;
        // A fallback launch, or one from before the install, ran the Core
        // that missed the TUN without the authorization now in place.
        return !_tunMissed;
      case AuthorizeCode.error:
        authorizationNotifier.value = TunAuthorizationState.none;
        ref
            .read(patchClashConfigProvider.notifier)
            .update((state) => state.copyWith.tun(enable: false));
        dialogs.showNotifier(
          currentAppLocalizations.tunAuthorizationFailed,
          level: MessageLevel.error,
        );
        return true;
    }
  }

  /// An empty profile list is left alone: it is the first-run state, and it is
  /// what the profile stream holds before its first emission.
  @visibleForTesting
  Profile? recoverMissingProfile() {
    final profileId = ref.read(currentProfileIdProvider);
    if (profileId == null) return null;
    final profiles = ref.read(profilesProvider);
    if (profiles.isEmpty) return null;
    final fallback = profiles.first;
    commonPrint.log(
      'profile $profileId is missing, falling back to ${fallback.id}',
      logLevel: LogLevel.warning,
    );
    ref.read(currentProfileIdProvider.notifier).value = fallback.id;
    return fallback;
  }

  /// The optimized profile path stores an overlay rather than the complete
  /// configuration. Expand the same base/overlay pair used by Mihomo so
  /// protection also includes server addresses omitted from that overlay.
  Future<String> _zapretEffectiveYaml(BuiltProfile? profile) async {
    final base = profile?.base;
    return base == null ? profile?.yaml ?? '' : await _core.buildProfile(base);
  }

  Future<void> _syncZapretInfrastructure(BuiltProfile profile, int? profileId) async {
    if (!system.isWindows || ref.read(safeModeProvider)) return;
    try {
      final yaml = await _zapretEffectiveYaml(profile);
      if (!ref.mounted || profileId != ref.read(currentProfileIdProvider)) return;
      final controller = ref.read(zapretControllerProvider.notifier);
      final transition = await controller.beginProfileApply(yaml, profileId);
      await controller.finishProfileApply(transition,
        yaml: yaml, profileId: profileId, accepted: true);
    } catch (error) {
      commonPrint.log('Zapret infrastructure refresh failed: $error', logLevel: LogLevel.warning);
    }
  }

  Future<_SetupTaskResult> _setupConfig({
    bool force = false,
    bool silence = false,
    Future<void> Function()? preloadInvoke,
    FutureOr Function()? onUpdated,
  }) async {
    var profile = ref.read(currentProfileProvider) ?? recoverMissingProfile();
    // A refresh failure is surfaced by safeRun; setup keeps the old profile.
    if (profile case final missing? when await missing.isMissingFile) {
      await globalState.safeRun(
        () => ref
            .read(profilesActionProvider.notifier)
            .fetchMissingFile(missing.id),
      );
      final current = ref.read(currentProfileProvider);
      profile = current;
    }
    commonPrint.log('setup ===> ${profile?.realLabel}');
    final patchConfig = ref.read(patchClashConfigProvider);
    final shouldContinueSetup = await requestAdmin(patchConfig.tun.enable);
    if (!shouldContinueSetup) {
      return _SetupTaskResult.handoffToCoreRestart;
    }
    final pushWatch = Stopwatch()..start();
    final realPatchConfig = _effectivePatchConfig(patchConfig);
    final networkSetting = ref.read(networkSettingProvider);
    SetupState? setupState;
    final realProfile = await globalState.safeRun(() async {
      final state = await ref.read(setupStateProvider(profile?.id).future);
      setupState = state;
      return getProfile(setupState: state, patchConfig: realPatchConfig);
    }, title: 'build profile');
    if (_exiting) return _SetupTaskResult.failed;
    final profileFailed = realProfile == null;
    if (system.isWindows && profileFailed) {
      // No empty/default replacement and no listener start after build error.
      return _SetupTaskResult.failed;
    }
    var setupParams = _setupParams.copyWith(base: realProfile?.base);
    final inputs = switch (setupState) {
      final state? when !profileFailed => (
        state,
        realPatchConfig,
        networkSetting,
        _appliedParams,
      ),
      _ => null,
    };
    final yamlString = realProfile?.yaml ?? '';
    final yamlMd5 = realProfile?.md5 ?? '';
    final hostCandidates = _builtHostCandidates.remove(yamlMd5) ?? const <String, Map<String, String>>{};
    if (!profileFailed && yamlMd5 == globalState.lastConfigMd5 && !force) {
      _appliedInputs = inputs;
      _appliedHostCandidates = hostCandidates;
      globalState.lastConfigCounts = realProfile.counts;
      await preloadInvoke?.call();
      await _syncZapretInfrastructure(realProfile, profile?.id);
      if (system.isWindows) {
        unawaited(ref.read(resourcesActionProvider.notifier).profileApplied(profile?.id));
      }
      return _SetupTaskResult.completed;
    }
    // Z3 rejects invalid Windows profiles without replacing native routes.
    // Keep the last acknowledged display metadata until a definite answer.
    final previousCounts = globalState.lastConfigCounts;
    final previousHosts = _appliedHostCandidates;
    final coreGeneration = _coreGeneration;
    // Until the push succeeds do not report the new profile as applied.
    _appliedInputs = null;
    if (system.isWindows) {
      unawaited(ref.read(resourcesActionProvider.notifier).profileApplied(null));
    }
    _appliedHostCandidates = const {};
    final pushRevision = ++_pushes;
    try {
      if (system.isWindows) {
        ref.read(proxiesActionProvider.notifier).cancelDelayTests();
      }
      globalState.lastConfigMd5 = null;
      globalState.lastConfigCounts = null;
      if (system.isAndroid) {
        await ref.read(vpnOptionsProvider.future);
        await preferences.saveShareState(ref.read(sharedStateProvider));
        await preferences.saveAppliedConfigMd5(null);
      }
      // Recaptured so _start's catch can roll back after safeRun swallows it.
      (Object, StackTrace)? handoffFailure;
      var setupFailed = false;
      await globalState.loadingRun(
        () async {
          ZapretController? zapret;
          ({int revision, bool restore, bool wasStopping, bool changed})? transition;
          var protectionYaml = '';
          var accepted = false;
          Directory? stagedBase;
          try {
            if (system.isWindows && !ref.read(safeModeProvider)) {
              protectionYaml = await _zapretEffectiveYaml(realProfile);
              final controller = ref.read(zapretControllerProvider.notifier);
              zapret = controller;
              transition = await controller.beginProfileApply(protectionYaml, profile?.id);
            }
            if (setupParams.base == null) {
              if (system.isWindows) {
                // Send the complete overlay through the native parse-then-write
                // path. The empty base adds no routes, proxies or resources.
                stagedBase = await Directory(await appPath.homeDirPath)
                    .createTemp('profile-apply-');
                final empty = File(join(stagedBase.path, 'base.yaml'));
                await empty.writeAsString('{}', flush: true);
                setupParams = setupParams.copyWith(base: SetupBase(
                  path: empty.path, overlay: yamlString.isEmpty ? '{}' : yamlString,
                ));
              } else {
                final configFilePath = await appPath.configFilePath;
                await File(configFilePath).writeAsStringAtomically(yamlString);
              }
            }
            final profileId = profile?.id;
            if (profileId != null) {
              await appPath.ensureProviderDirs(profileId);
            }
            if (_exiting) throw StateError('Application is exiting');
            final String message;
            try {
              message = await _core.setupConfig(
                params: setupParams,
                preloadInvoke: preloadInvoke,
              );
            } finally {
              _pushes++;
            }
            if (message.isNotEmpty) {
              if (system.isWindows) {
                // An explicit rejection (unlike a lost IPC response) proves
                // the old config remains in the same native process.
                if (coreGeneration == _coreGeneration) {
                  globalState.lastConfigCounts = previousCounts;
                  _appliedHostCandidates = previousHosts;
                }
              } else {
                globalState.lastConfigCounts = configCountsOf(const {});
              }
              // Do not restore the old digest or input equality: a retry
              // must submit the current settings again.
              await globalState.safeRun(() => onUpdated?.call());
              throw MessageException(message);
            }
            accepted = !profileFailed;
            if (accepted) _appliedHostCandidates = hostCandidates;
          } catch (e, s) {
            setupFailed = true;
            if (preloadInvoke != null) {
              handoffFailure = (e, s);
            }
            rethrow;
          } finally {
            if (stagedBase != null) {
              try {
                await stagedBase.delete(recursive: true);
              } on FileSystemException {
                // Best-effort cleanup must not mask the profile apply result.
              }
            }
            if (zapret != null && transition != null) {
              try {
                await zapret.finishProfileApply(transition,
                  yaml: protectionYaml, profileId: profile?.id, accepted: accepted);
              } catch (error) {
                // Core apply has already completed. Surface the Zapret error
                // without rolling back or misreporting the Mihomo config.
                commonPrint.log('Zapret infrastructure reconciliation failed: $error',
                  logLevel: LogLevel.warning);
              }
            }
          }
          if (_exiting) { setupFailed = true; return; }
          globalState.lastConfigMd5 = yamlMd5;
          globalState.lastConfigCounts =
              realProfile?.counts ?? configCountsOf(const {});
          _appliedInputs = inputs;
          if (system.isAndroid) {
            await preferences.saveAppliedConfigMd5(yamlMd5);
          }
          if (profile?.id == ref.read(currentProfileIdProvider)) {
            await ref
                .read(proxiesActionProvider.notifier)
                .resendPicksSince(setupParams.selectedMap);
          }
          await onUpdated?.call();
          if (system.isWindows && accepted) {
            unawaited(ref.read(resourcesActionProvider.notifier).profileApplied(profile?.id));
          }
        },
        silence: true,
        tag: !silence ? LoadingTag.proxies : null,
      );
      _lastPushDuration = pushWatch.elapsed;
      if (handoffFailure != null) {
        Error.throwWithStackTrace(handoffFailure!.$1, handoffFailure!.$2);
      }
      if (setupFailed || profileFailed) {
        return _SetupTaskResult.failed;
      }
      return _SetupTaskResult.completed;
    } finally {
      // Staging, preference or Zapret preparation can fail before the
      // native setupConfig RPC. Always release the in-flight revision.
      if (_pushes == pushRevision) _pushes++;
    }
  }
}

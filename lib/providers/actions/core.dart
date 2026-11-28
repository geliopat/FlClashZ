part of '../action.dart';

@Riverpod(keepAlive: true)
class CoreAction extends _$CoreAction {
  CoreController get _core => ref.read(coreHandlerProvider);
  bool get _exiting => !ref.mounted || ref.read(systemActionProvider.notifier).isExiting;

  static const crashRestartLimit = 3;
  static const crashRestartWindow = Duration(seconds: 5);

  int _requestedRestartRevision = 0;
  Future<bool>? _restartOperation;
  Future<bool>? _coreReleaseOperation;
  bool _coreReleaseCrashed = false;
  bool get isRestarting => _restartOperation != null || _coreReleaseOperation != null;
  int _restartsBegun = 0;
  bool _relaunchRequested = false;
  int _failedRestarts = 0;
  DateTime? _crashRestartedAt;
  bool _restartingAfterCrash = false;
  String? _unansweredCrash;
  bool _answeringCrashes = false;

  @override
  void build() {}

  @protected
  DateTime currentTime() => DateTime.now();

  Future<void> initCore() async {
    final isInit = await _core.isInit;

    final version = ref.read(versionProvider);
    if (!isInit) {
      final res = await _core.init(version);
      if (!res) throw StateError('Core initialization refused');
      commonPrint.log('init result: $res');
    } else {
      await ref.read(proxiesActionProvider.notifier).updateGroups();
      await ref.read(providersProvider.notifier).syncProviders();
    }
    _core.setHostActive(ref.read(appVisibleProvider));
    try {
      globalState.coreVersion = await _core.getCoreVersion();
    } catch (_) {}
  }

  Future<void> startCore() async {
    if (_exiting) return;
    final restartsBegun = _restartsBegun;
    ref.read(coreStatusProvider.notifier).value = CoreStatus.connecting;
    try {
      final result = await startLifecycle();
      if (!_exiting && restartsBegun == _restartsBegun) {
        await _applyLifecycleResult(result);
      }
    } catch (error) {
      // A restart begun since, such as one answering a crash in init, owns it.
      if (_exiting || restartsBegun != _restartsBegun) {
        return;
      }
      ref.read(coreStatusProvider.notifier).value = CoreStatus.disconnected;
      dialogs.showNotifier(error.toString(), level: MessageLevel.error);
    }
  }

  @protected
  Future<CoreLifecycleResult> startLifecycle() {
    return _core.start();
  }

  @protected
  Future<CoreLifecycleResult> restartLifecycle() {
    return _core.restart();
  }

  // Authenticate the running adapter before exposing a connected state or
  // applying a profile. The same gate covers launch, restart and rollback.
  @protected
  Future<void> verifyRunningCore() async {
    if (!system.isWindows || safeModeBuild || ref.read(safeModeProvider)) return;
    final selected = await coreReleaseSelection.selectedForLaunch();
    final capabilities = await _core.getCoreCapabilities();
    final identity = await _core.getCoreIdentity();
    final missing = requiredWindowsCoreCapabilities.difference(capabilities);
    if (missing.isNotEmpty || identity == null) {
      throw StateError('Incompatible core adapter: missing ${missing.join(', ')}');
    }
    final actual = await _core.getCoreVersion();
    String normalize(String v) => v.startsWith('v') ? v : 'v$v';
    final expected = selected?.version.mihomoVersion ?? coreVersionDefine;
    if (expected.isNotEmpty && normalize(actual) != normalize(expected)) {
      throw StateError('Unexpected running Mihomo version: $actual');
    }
    if (selected != null &&
        (selected.engineRevision == null || selected.hostRevision == null ||
        identity['version'] != selected.version.value ||
        identity['engineRevision'] != selected.engineRevision ||
        identity['hostRevision'] != selected.hostRevision)) {
      throw StateError('Running independent core identity differs from selected signed release');
    }
  }

  // During initialization, connected allows the existing crash monitor to
  // notice failure. No incompatible adapter can reach this point.
  Future<bool> _applyLifecycleResult(CoreLifecycleResult result) async {
    if (result.outcome == CoreLifecycleOutcome.superseded) {
      return false;
    }
    if (_exiting) return false;
    await verifyRunningCore();
    if (_exiting) return false;
    ref.read(coreStatusProvider.notifier).value = CoreStatus.connected;
    await initCore();
    return !_exiting;
  }

  Future<void> clearDnsCacheOnNetworkChange() async {
    if (ref.read(coreStatusProvider) != CoreStatus.connected) {
      return;
    }
    try {
      await _core.clearDnsCache();
    } catch (error) {
      commonPrint.log(
        'clearDnsCache error: $error',
        logLevel: coreFailureLogLevel(error),
      );
    }
  }

  Future<void> crash() async {
    await _core.crash();
  }

  /// Restarting a Core that keeps falling would only hide why it falls.
  Future<void> restartAfterCrash(String reason) async {
    if (_exiting) return;
    crashFileLogger.enable();
    crashFileLogger.write(Log.app('[Mihomo] $reason').copyWith(logLevel: LogLevel.error));
    // The activation transaction owns recovery during a candidate trial.
    // A competing watchdog relaunch could commit the wrong executable.
    if (_coreReleaseOperation != null) {
      _coreReleaseCrashed = true;
      return;
    }
    if (system.isWindows && !ref.read(mihomoWatchdogProvider)) {
      final id = recoveryJournal.begin('Mihomo', 'watchdog');
      recoveryJournal.record(id, 'Mihomo', 'watchdog', RecoveryOutcome.skipped);
      return;
    }
    final restartedAt = _crashRestartedAt;
    final restartFailed =
        _restartingAfterCrash ||
        (restartedAt != null &&
            currentTime().difference(restartedAt) < crashRestartWindow);
    _failedRestarts = restartFailed ? _failedRestarts + 1 : 0;
    _unansweredCrash = reason;
    if (_answeringCrashes) {
      return;
    }
    _answeringCrashes = true;
    try {
      for (
        var crash = _unansweredCrash;
        crash != null;
        crash = _unansweredCrash
      ) {
        _unansweredCrash = null;
        if (_exiting) return;
        if (_failedRestarts >= crashRestartLimit) {
          if (system.isWindows) {
            final id = recoveryJournal.begin('Mihomo', 'watchdog-limit');
            recoveryJournal.record(id, 'Mihomo', 'watchdog-limit', RecoveryOutcome.skipped);
          }
          commonPrint.log(
            '$crashRestartLimit restarts in a row did not keep the Core up for '
            '${crashRestartWindow.inSeconds}s, leaving it down: $crash',
            logLevel: LogLevel.error,
          );
          return;
        }
        commonPrint.log(
          'Core is down, restarting it: $crash',
          logLevel: LogLevel.warning,
        );
        // restartCore() joins a restart under way instead of relaunching.
        await _restartOperation?.catchError((_) => false);
        if (_exiting) return;
        final running = ref.read(setupActionProvider.notifier).requestedRunning;
        _restartingAfterCrash = true;
        try {
          if (await restartCore(running: running)) {
            _crashRestartedAt = currentTime();
          } else if (_unansweredCrash == null) {
            _failedRestarts++;
            _unansweredCrash = 'Core restart did not restore the requested state';
          }
        } catch (error) {
          if (error case DesktopCoreFailure(phase: DesktopCorePhase.closed)) {
            return;
          }
          if (_unansweredCrash == null) {
            _failedRestarts++;
            _unansweredCrash = compactError(error);
          }
        } finally {
          _restartingAfterCrash = false;
        }
      }
    } finally {
      _answeringCrashes = false;
    }
  }

  /// [running] stands in for a run that a crash rolled back.
  Future<bool> restartCore({bool? running, bool repairHelper = false}) {
    if (_exiting) return Future.value(false);
    final update = _coreReleaseOperation;
    if (update != null) {
      // A Helper repair must follow the exclusive core trial, not interrupt it.
      return repairHelper
          ? update.catchError((_) => false).then((_) => restartCore(running: running, repairHelper: true))
          : update;
    }
    return _restartCore(running: running, repairHelper: repairHelper);
  }

  Future<bool> _restartCore({bool? running, bool repairHelper = false}) {
    if (_exiting) return Future.value(false);
    _requestedRestartRevision++;
    final activeOperation = _restartOperation;
    if (activeOperation != null) {
      // An explicit repair requested during a relaunch must not be ignored.
      return repairHelper
          ? activeOperation.catchError((_) => false).then((_) => restartCore(running: running, repairHelper: true))
          : activeOperation;
    }

    _restartsBegun++;
    final operation = _runRestartWorker(running: running, repairHelper: repairHelper);
    _restartOperation = operation;
    return operation;
  }

  /// Called after Helper has authenticated and staged the signed package.
  /// Keep download/staging outside this operation: a bad package cannot stop
  /// the working core. All configuration/listener recovery uses the existing
  /// restart worker, not an independent process launcher.
  Future<bool> activateCoreRelease(CoreReleaseManifest manifest) =>
      _changeCoreRelease(manifest: manifest);

  Future<bool> restorePreviousCoreRelease() => _changeCoreRelease(restore: true);

  Future<bool> _changeCoreRelease({
    CoreReleaseManifest? manifest,
    bool restore = false,
  }) {
    if (_exiting) return Future.value(false);
    if (!system.isWindows || safeModeBuild || ref.read(safeModeProvider)) {
      return Future.error(StateError('Independent core updates require normal Windows mode'));
    }
    if (_coreReleaseOperation != null) {
      return Future.error(StateError('Core release update already running'));
    }
    final operation = _runCoreReleaseChange(manifest: manifest, restore: restore);
    _coreReleaseOperation = operation;
    return operation.whenComplete(() {
      if (identical(_coreReleaseOperation, operation)) {
        _coreReleaseOperation = null;
        _coreReleaseCrashed = false;
      }
    });
  }

  Future<bool> _runCoreReleaseChange({
    required CoreReleaseManifest? manifest,
    required bool restore,
  }) async {
    // Wait out an earlier restart before the first trial selection is visible.
    await _restartOperation?.catchError((_) => false);
    if (_exiting) return false;
    final setup = ref.read(setupActionProvider.notifier);
    final running = setup.requestedRunning ?? ref.read(isStartProvider);
    final id = recoveryJournal.begin('Mihomo', restore ? 'core-rollback' : 'core-update');
    var outcome = RecoveryOutcome.interrupted;

    Future<bool> restart() async {
      _coreReleaseCrashed = false;
      // This is the sole bypass of the public restart join while the
      // transaction owns the lifecycle. It still uses the same worker.
      final restored = await _restartCore(running: running);
      if (!restored || _coreReleaseCrashed || !await _core.isInit) return false;
      final selected = await coreReleaseSelection.selectedForLaunch();
      final expected = selected?.version.mihomoVersion ?? coreVersionDefine;
      final actual = await _core.getCoreVersion();
      String normalized(String version) => version.startsWith('v') ? version : 'v$version';
      if (expected.isNotEmpty && normalized(actual) != normalized(expected)) return false;
      // A signed release from an older adapter can carry the same Mihomo
      // version. Validate the actual process during the trial, not just its
      // version or the persisted selection. Rollback is allowed to restore
      // the pre-trial process even when its capabilities were older.
      if (manifest != null && selected?.hash == manifest.hash) {
        final identity = await _core.getCoreIdentity();
        if (identity?['version'] != manifest.version.value ||
            identity?['engineRevision'] != manifest.engineRevision ||
            identity?['hostRevision'] != manifest.hostRevision) {
          return false;
        }
        final capabilities = await _core.getCoreCapabilities();
        if (!capabilities.containsAll(requiredWindowsCoreCapabilities)) return false;
      }
      // Detect immediate crashes after successful configuration/listener setup.
      await Future<void>.delayed(const Duration(seconds: 2));
      return !_exiting && !_coreReleaseCrashed &&
          ref.read(coreStatusProvider) == CoreStatus.connected &&
          await _core.isInit;
    }

    bool healthy() => !_exiting && !_coreReleaseCrashed &&
        ref.read(coreStatusProvider) == CoreStatus.connected;

    try {
      final result = restore
          ? await coreReleaseSelection.restorePrevious(restart: restart, healthy: healthy)
          : await coreReleaseSelection.activate(
              manifest!, bundledVersion: coreVersionDefine.isNotEmpty
                  ? coreVersionDefine : await _core.getCoreVersion(),
              restart: restart, healthy: healthy,
            );
      outcome = result ? RecoveryOutcome.succeeded : RecoveryOutcome.failed;
      return result;
    } catch (_) {
      outcome = RecoveryOutcome.failed;
      rethrow;
    } finally {
      recoveryJournal.record(id, 'Mihomo', restore ? 'core-rollback' : 'core-update', outcome);
    }
  }

  Future<bool>? requestRelaunch() {
    final operation = _restartOperation;
    if (operation != null) {
      _relaunchRequested = true;
    }
    return _coreReleaseOperation ?? operation;
  }

  /// An in-process core (Android) cannot be relaunched, so a restart stops
  /// the tunnel, shuts mihomo down inside the process and initializes again.
  @protected
  bool get coreIsEmbedded => coreLib != null;

  Future<bool> _runRestartWorker({bool? running, required bool repairHelper}) async {
    final action = _restartingAfterCrash ? 'watchdog' : 'restart';
    final recoveryId = system.isWindows ? recoveryJournal.begin('Mihomo', action) : null;
    var outcome = RecoveryOutcome.interrupted;
    var lifecycleStarted = false;
    final setupAction = ref.read(setupActionProvider.notifier);
    final bool wasRunning = running ?? ref.read(isStartProvider);
    var restartZapret = false;
    final zapret = system.isWindows && !ref.read(safeModeProvider)
        ? ref.read(zapretControllerProvider.notifier) : null;
    try {
      if (zapret != null) {
        try {
          restartZapret = await zapret.beginCoreRestart(repairHelper: repairHelper);
        } catch (error) {
          commonPrint.log('Mihomo restart postponed: Helper/Zapret preparation failed: $error', logLevel: LogLevel.warning);
          rethrow;
        }
      }
      if (_exiting) return false;
      lifecycleStarted = true;
      ref.read(coreStatusProvider.notifier).value = CoreStatus.connecting;
      final stopping = coreIsEmbedded && wasRunning
          ? setupAction.setRunning(false)
          : null;
      final runIntent = setupAction.runIntent;
      if (coreIsEmbedded) {
        await stopping;
        await _core.shutdown();
      }
      var applied = true;
      do {
        if (_exiting) return false;
        _relaunchRequested = false;
        ref.read(coreStatusProvider.notifier).value = CoreStatus.connecting;
        final result = await restartLifecycle();
        if (!await _applyLifecycleResult(result)) {
          outcome = RecoveryOutcome.failed;
          return false;
        }
        var appliedRevision = 0;
        while (appliedRevision < _requestedRestartRevision &&
            !_relaunchRequested) {
          if (_exiting) return false;
          final revision = _requestedRestartRevision;
          applied = await _restoreRunning(
            setupAction,
            wasRunning: wasRunning,
            runRequested: running,
            observedIntent: runIntent,
          );
          appliedRevision = revision;
        }
      } while (_relaunchRequested);
      if (_exiting) return false;
      zapret?.endCoreRestart();
      if (applied && zapret != null && ref.read(isStartProvider) && !ref.read(safeModeProvider)) {
        await zapret.startAlongsideMihomo(force: restartZapret).catchError((Object error) {
          commonPrint.log('Linked Zapret restart failed: $error', logLevel: LogLevel.warning);
        });
      }
      outcome = applied ? RecoveryOutcome.succeeded : RecoveryOutcome.failed;
      return applied;
    } catch (_) {
      outcome = RecoveryOutcome.failed;
      // A refused Helper/Zapret preflight never stopped Mihomo. Do not
      // announce a disconnection while the previous process still owns IPC.
      if (lifecycleStarted && ref.mounted) {
        ref.read(coreStatusProvider.notifier).value = CoreStatus.disconnected;
      }
      rethrow;
    } finally {
      if (recoveryId != null) recoveryJournal.record(recoveryId, 'Mihomo', action, outcome);
      zapret?.endCoreRestart();
      _relaunchRequested = false;
      _restartOperation = null;
    }
  }

  /// A request made mid-restart hit a dead process; the latest intent wins.
  Future<bool> _restoreRunning(
    SetupAction setupAction, {
    required bool wasRunning,
    required bool? runRequested,
    required Object? observedIntent,
  }) async {
    final intentChanged = !identical(setupAction.runIntent, observedIntent);
    final running = intentChanged
        ? setupAction.requestedRunning == true
        : runRequested ?? (wasRunning || ref.read(isStartProvider));
    if (running) {
      return setupAction.setRunning(true, initialize: true);
    }
    if (ref.read(isStartProvider)) {
      await globalState.safeRun(() => setupAction.setRunning(false));
    }
    return setupAction.applyProfile(force: true);
  }
}

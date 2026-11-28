part of '../action.dart';

final updatePlatformResolverProvider = Provider<Future<UpdatePlatform> Function(ExitApp)>((ref) =>
    (exitApp) => resolveUpdatePlatform(exitApp: exitApp));

@Riverpod(keepAlive: true)
class CommonAction extends _$CommonAction {
  CoreController get _core => ref.read(coreHandlerProvider);
  Future<void>? _trafficUpdate;
  bool _trayOperationInProgress = false;
  Future<bool>? _coreUpdate;

  @override
  void build() {}

  void toggleRunning() {
    final running = !ref.read(isStartProvider);
    unawaited(
      globalState.safeRun(
        () => ref
            .read(setupActionProvider.notifier)
            .setRunning(
              running,
              initialize: running && !ref.read(initProvider),
            ),
      ),
    );
  }

  /// The Windows tray is an explicit request for both components.
  /// It does not change the persistent linked-start preference.
  Future<void> toggleTrayRunning() async {
    if (_trayOperationInProgress || !ref.read(initProvider)) return;
    if (ref.read(zapretControllerProvider).dashboardRestarting) return;
    _trayOperationInProgress = true;
    try {
      final zapret = ref.read(zapretControllerProvider);
      final running = ref.read(isStartProvider) || zapret.running || zapret.busy;
      await globalState.safeRun(
        () => ref.read(setupActionProvider.notifier).setTrayRunning(!running),
      );
    } finally {
      _trayOperationInProgress = false;
    }
  }

  /// Use exactly the dashboard's coordinated restart, not app relaunch.
  Future<void> restartFromTray() async {
    if (_trayOperationInProgress || !ref.read(initProvider) ||
        ref.read(coreStatusProvider) == CoreStatus.connecting) return;
    final restartAll = !ref.read(safeModeProvider);
    if (restartAll) {
      final zapret = ref.read(zapretControllerProvider);
      if (zapret.busy || zapret.dashboardRestarting) return;
    }
    _trayOperationInProgress = true;
    try {
      await globalState.safeRun(() async {
        if (restartAll) {
          await ref.read(zapretControllerProvider.notifier)
              .restartFromDashboard(restartAll: true);
        } else {
          await ref.read(coreActionProvider.notifier).restartCore();
        }
      });
    } finally {
      _trayOperationInProgress = false;
    }
  }

  void updateSpeedStatistics() {
    ref
        .read(appSettingProvider.notifier)
        .update((state) => state.copyWith(showTrayTitle: !state.showTrayTitle));
  }

  void updateMonochromeTrayIcon() {
    ref
        .read(appSettingProvider.notifier)
        .update(
          (state) =>
              state.copyWith(monochromeTrayIcon: !state.monochromeTrayIcon),
        );
  }

  /// The cycling hotkey, which has nowhere to ask before taking the mode
  /// over from the subscription.
  void updateMode() {
    ref
        .read(managedSettingsActionProvider.notifier)
        .takeOverIfLocked('clash.mode');
    final modes = ref.read(availableModesProvider);
    ref.read(patchClashConfigProvider.notifier).update((state) {
      final index = modes.indexWhere((item) => item == state.mode);
      final nextIndex = index + 1 > modes.length - 1 ? 0 : index + 1;
      return state.copyWith(mode: modes[nextIndex]);
    });
    ref.read(profileHeadersActionProvider.notifier).forgetTakenMode();
  }

  Future<void> updateTraffic() {
    return _trafficUpdate ??= _updateTraffic().whenComplete(() {
      _trafficUpdate = null;
    });
  }

  Future<void> _updateTraffic() async {
    final history = system.isWindows && !ref.read(safeModeProvider)
        ? ref.read(trafficHistoryProvider)
        : null;
    final generation = history?.generation;
    if (history?.resetting == true) return;
    try {
      final onlyStatisticsProxy = ref.read(
        appSettingProvider.select((state) => state.onlyStatisticsProxy),
      );
      final [traffic, totalTraffic, alternateTotal] = await Future.wait([
        _readTraffic(() => _core.getTraffic(onlyStatisticsProxy)),
        _readTraffic(() => _core.getTotalTraffic(onlyStatisticsProxy)),
        if (system.isWindows)
          _readTraffic(() => _core.getTotalTraffic(!onlyStatisticsProxy))
        else
          Future<Traffic?>.value(null),
      ]);
      if (!ref.mounted || generation != history?.generation) return;
      if (history != null) {
        await history.record(
          generation: generation!,
          all: onlyStatisticsProxy ? alternateTotal : totalTraffic,
          proxy: onlyStatisticsProxy ? totalTraffic : alternateTotal,
        );
        if (!ref.mounted || generation != history.generation) return;
      }
      if (traffic != null) {
        ref.read(trafficsProvider.notifier).addTraffic(traffic);
      }
      if (totalTraffic != null) {
        ref.read(totalTrafficProvider.notifier).value = totalTraffic;
      }
    } catch (error) {
      commonPrint.log('Traffic sample: ${compactError(error)}',
          logLevel: LogLevel.warning);
    }
  }

  Future<Traffic?> _readTraffic(Future<Traffic> Function() request) async {
    try {
      return await request();
    } catch (error) {
      commonPrint.log(
        'updateTraffic error: $error',
        logLevel: coreFailureLogLevel(error),
      );
      return null;
    }
  }

  /// The provider's update manifest for this channel, when its header names
  /// one; it then stands in for GitHub as the update source.
  Future<Map<String, dynamic>?> checkForUpdate() async {
    final headers = ref.read(currentProfileProvider)?.headers;
    final manifestUrl = globalState.isPre
        ? headers?.preUpdateManifestUrl
        : headers?.updateManifestUrl;
    // Windows fork releases require our signed manifest. Do not fall back
    // to an unsigned GitHub release when the signing key is not configured.
    if (manifestUrl == null && !Platform.isWindows) {
      return request.checkForUpdate();
    }
    try {
      String? source = manifestUrl;
      if (source == null && globalState.isPre) {
        final release = await request.latestPrerelease();
        final tag = release?['tag_name'];
        if (tag is! String || !RegExp(r'^v\d+\.\d+\.\d+-pre\.\d+$').hasMatch(tag)) {
          return null;
        }
        source = 'https://github.com/$repository/releases/download/$tag/manifest.json';
      }
      return await fetchManifestUpdate(
        request.dio,
        Uri.parse(source ?? 'https://github.com/$repository/releases/latest/download/manifest.json'),
        currentVersion: globalState.packageInfo.displayVersion,
        pre: globalState.isPre,
      );
    } catch (error) {
      commonPrint.log(
        'update manifest failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      return null;
    }
  }

  Future<Directory> _updateCacheRoot() async =>
      Directory(join((await appPath.cacheDir.future).path, 'update'));

  /// Clears the downloads of updates this app already runs, once it starts
  /// after installing one.
  Future<void> removeInstalledUpdates() async => removeStaleUpdates(
    await _updateCacheRoot(),
    currentVersion: globalState.packageInfo.displayVersion,
  );

  Future<bool> autoCheckUpdate() async {
    if (!ref.read(appSettingProvider).autoCheckUpdate) return false;
    var offered = false;
    try {
      final res = await checkForUpdate();
      if (ref.mounted && res != null &&
          (res['_required'] == true ||
              res['tag_name'] != ref.read(appSettingProvider).hiddenUpdate)) {
        await checkUpdateResultHandle(data: res);
        offered = true;
      }
    } catch (error) {
      commonPrint.log(
        'checkForUpdate failed: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
    }
    if (!ref.mounted || ref.read(systemActionProvider.notifier).isExiting) {
      return offered;
    }
    // Same automatic update entry point and preference, no separate timer.
    final coreOffered = await checkCoreUpdate();
    return offered || coreOffered;
  }

  bool get _canUpdateCore => ref.mounted && system.isWindows &&
      !safeModeBuild && !ref.read(safeModeProvider) &&
      ref.read(initProvider) &&
      ref.read(coreStatusProvider) == CoreStatus.connected &&
      !ref.read(systemActionProvider.notifier).isExiting;

  Future<bool> checkCoreUpdate({bool isUser = false}) {
    if (!_canUpdateCore) return Future.value(false);
    return _coreUpdate ??= _checkCoreUpdate(isUser: isUser).whenComplete(() {
      _coreUpdate = null;
    });
  }

  Future<bool> _checkCoreUpdate({required bool isUser}) async {
    final ru = currentAppLocalizations.localeName.startsWith('ru');
    String tr(String russian, String english) => ru ? russian : english;
    final title = tr('Обновление ядра', 'Core update');
    final updater = CoreReleaseUpdater(
      downloader: UpdateDownloader(
        root: () async => Directory(join(await appPath.homeDirPath, 'core-update-downloads')),
      ),
      helper: helperClient,
    );
    PreparedCoreRelease? prepared;
    try {
      final offer = await updater.check();
      final journal = await coreReleaseSelection.read();
      if (!_canUpdateCore) return false;
      final raw = coreVersionDefine.isNotEmpty ? coreVersionDefine : bundledMihomoVersion;
      final bundled = raw.startsWith('v') ? raw : 'v$raw';
      final minimum = CoreReleaseVersion.parse('$bundled-z.1');
      final version = offer.manifest.version;
      if (version.compareTo(CoreReleaseVersion.parse(minimumIndependentCoreVersion)) < 0 ||
          version.compareTo(minimum) < 0 ||
          (journal.current != null && version.compareTo(journal.current!.version) <= 0)) {
        if (isUser) await dialogs.showAlert(
          title: title,
          message: TextSpan(text: tr('Обновлений ядра нет', 'No core updates')),
        );
        return false;
      }
      final approved = await dialogs.showMessage(
        title: title,
        message: TextSpan(text: tr(
          'Доступна версия ${version.value}. Установить и перезапустить ядро?',
          'Version ${version.value} is available. Install and restart the core?',
        )),
        confirmText: tr('Обновить', 'Update'),
      );
      if (approved != true || !_canUpdateCore) return true;
      await globalState.loadingRun(() async {
        prepared = await updater.downloadOffer(offer);
        if (!_canUpdateCore) return false;
        final manifest = await updater.stage(prepared!);
        if (!_canUpdateCore) return false;
        final ok = await ref.read(coreActionProvider.notifier).activateCoreRelease(manifest);
        if (ref.mounted) {
          dialogs.showNotifier(ok
              ? tr('Ядро обновлено: ${version.value}', 'Core updated: ${version.value}')
              : tr('Обновление ядра не применено', 'Core update not applied'));
        }
        return ok;
      }, title: title, tag: LoadingTag.checkUpdate);
      return true;
    } catch (error) {
      commonPrint.log('Core update: ${compactError(error)}', logLevel: LogLevel.warning);
      if (isUser && ref.mounted) {
        await dialogs.showAlert(title: title, message: TextSpan(text: tr(
          'Ошибка обновления ядра: ${compactError(error)}',
          'Core update failed: ${compactError(error)}',
        )));
      }
      return false;
    } finally {
      try {
        await prepared?.dispose();
      } catch (error) {
        commonPrint.log('Core update cleanup: ${compactError(error)}', logLevel: LogLevel.warning);
      }
    }
  }

  TextSpan _releaseSpan(BuildContext context, String? body) {
    final version = parseReleaseChangelog(body);
    return TextSpan(
      children: version == null
          ? [
              TextSpan(text: '\n', style: AppTextStyle.subheadline.of(context)),
              for (final submit in parseReleaseBody(body))
                TextSpan(
                  text: '- $submit \n',
                  style: AppTextStyle.subheadline.of(context),
                ),
            ]
          : _changelogSpans(context, version),
    );
  }

  List<TextSpan> _changelogSpans(
    BuildContext context,
    ChangelogVersion version,
  ) {
    return [
      for (final group in version.visibleGroups) ...[
        TextSpan(
          text:
              '\n${changelogGroupTitle(currentAppLocalizations, group.type)}\n',
          style: AppTextStyle.subheadline
              .of(context, emphasized: true)
              .copyWith(
                color: group.type == ChangelogType.breaking
                    ? context.colorScheme.error
                    : context.colorScheme.primary,
              ),
        ),
        for (final entry in group.entries)
          TextSpan(
            text: '• ${entry.text}\n',
            style: AppTextStyle.subheadline.of(context),
          ),
      ],
    ];
  }

  Future<UpdatePlatform> _updatePlatform() async {
    try {
      return await ref.read(updatePlatformResolverProvider)(
        () => ref.read(systemActionProvider.notifier).handleExit(),
      );
    } catch (error) {
      commonPrint.log(
        'Update platform unresolved: ${compactError(error)}',
        logLevel: LogLevel.warning,
      );
      return const ManualUpdatePlatform();
    }
  }

  UpdateErrorKind? _updateInstallBlocker() {
    if (ref.read(safeModeProvider)) {
      return UpdateErrorKind.safeMode;
    }
    if (ref.read(setupActionProvider.notifier).isChangingRun) {
      return UpdateErrorKind.busy;
    }
    return null;
  }

  Future<void> checkUpdateResultHandle({
    Map<String, dynamic>? data,
    bool isUser = false,
  }) async {
    if (data != null) {
      final context = globalState.navigatorKey.currentContext!;
      final notes = _releaseSpan(context, data['body'] as String?);
      final platform = await _updatePlatform();
      if (!context.mounted || !ref.mounted) return;
      final required = data['_required'] == true;
      final downloader = UpdateDownloader(root: _updateCacheRoot);
      await dialogs.showCommonDialog<void>(
        // A required update is not put off by a tap beside it.
        dismissible: !required,
        child: UpdateDialog(
          version: data['tag_name'] as String,
          notes: notes,
          onOpenReleasePage: () =>
              unawaited(launchUrl(releasePageOf(data, repository: repository))),
          onHide: isUser || required
              ? null
              : () => ref
                    .read(appSettingProvider.notifier)
                    .update(
                      (state) => state.copyWith(
                        hiddenUpdate: data['tag_name'] as String,
                      ),
                    ),
          createController: () {
            final controller = UpdateController(
              release: data,
              platform: platform,
              downloader: downloader,
              repository: repository,
              pre: globalState.isPre,
              manifest: data['_isManifest'] == true,
              installBlocker: _updateInstallBlocker,
            );
            app?.onPackageInstallStatus = controller.onInstallStatus;
            return controller;
          },
        ),
      );
    } else if (isUser) {
      unawaited(
        dialogs.showAlert(
          title: currentAppLocalizations.checkUpdate,
          message: TextSpan(text: currentAppLocalizations.checkUpdateError),
        ),
      );
    }
  }
}

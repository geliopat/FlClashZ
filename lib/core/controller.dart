import 'dart:async';
import 'dart:io';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/core/core.dart';
import 'package:fl_clash/core/connection_snapshot.dart';
import 'package:fl_clash/core/interface.dart';
import 'package:fl_clash/core/spill.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/plugins/app.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:path/path.dart';

class CoreController {
  static CoreController? _instance;
  late CoreHandlerInterface _interface;

  CoreController._internal() : _snapshotMaxAge = const Duration(milliseconds: 900) {
    if (system.isAndroid) {
      _interface = coreLib!;
    } else {
      _interface = coreService!;
    }
  }

  @visibleForTesting
  CoreController.test(this._interface) : _snapshotMaxAge = const Duration(milliseconds: 900) {
    _instance = this;
  }

  @visibleForTesting
  CoreController.scoped(this._interface, {Duration? snapshotMaxAge})
    : _snapshotMaxAge = snapshotMaxAge ?? const Duration(milliseconds: 900);

  @visibleForTesting
  static void resetInstance() {
    _instance = null;
  }

  factory CoreController() {
    _instance ??= CoreController._internal();
    return _instance!;
  }

  final Duration _snapshotMaxAge;
  final _engineDiagnosticsScheduler = SerialTaskScheduler();
  int _engineDiagnosticsGeneration = 0;
  late final _connectionSnapshots = ConnectionSnapshotReader(_interface.getConnections, maxAge: _snapshotMaxAge);

  Future<ConnectionSnapshot> getConnectionSnapshot() => _connectionSnapshots.read();

  void invalidateConnectionSnapshot() => _connectionSnapshots.invalidate();

  Future<T> _invalidateConnectionsDuring<T>(Future<T> Function() operation) async {
    _connectionSnapshots.invalidate();
    try {
      return await operation();
    } finally {
      _connectionSnapshots.invalidate();
    }
  }

  Future<CoreLifecycleResult> _changeCoreLifecycle(
    Future<CoreLifecycleResult> Function() operation,
  ) async {
    _engineDiagnosticsGeneration++;
    try {
      return await _invalidateConnectionsDuring(operation);
    } finally {
      _engineDiagnosticsGeneration++;
    }
  }

  Future<CoreLifecycleResult> start() => _changeCoreLifecycle(_interface.start);

  Future<CoreLifecycleResult> restart() => _changeCoreLifecycle(_interface.restart);

  Future<CoreLifecycleResult> close() => _changeCoreLifecycle(_interface.close);

  static Future<void> ensureHomeDir() async {
    final homePath = await appPath.homeDirPath;
    final homeDir = Directory(homePath);
    final isExists = await homeDir.exists();
    if (!isExists) {
      await homeDir.create(recursive: true);
    }
    await system.grantHomeDirAccess(homePath);
  }

  static Future<void> initGeo() async {
    final homePath = await appPath.homeDirPath;
    const geoFileNameList = [MMDB, GEOIP, GEOSITE, ASN];
    try {
      for (final geoFileName in geoFileNameList) {
        final geoFile = File(join(homePath, geoFileName));
        final isExists = await geoFile.exists();
        if (isExists) {
          continue;
        }
        final asset = 'assets/data/$geoFileName';
        // rootBundle inflates the asset on the platform thread, which Android
        // shares with the UI: the four files stall frames for over 100 ms.
        if (app case final app?) {
          await app.extractAsset(asset, geoFile.path);
          continue;
        }
        final data = await rootBundle.load(asset);
        final List<int> bytes = data.buffer.asUint8List();
        await geoFile.writeAsBytes(bytes, flush: true);
      }
    } catch (e) {
      commonPrint.log(
        'Failed to initialize geo data: $e',
        logLevel: LogLevel.error,
      );
      rethrow;
    }
  }

  Future<bool> init(int version) async {
    await ensureHomeDir();
    await initGeo();
    final homeDirPath = await appPath.homeDirPath;
    return _interface.init(InitParams(homeDir: homeDirPath, version: version));
  }

  FutureOr<bool> get isInit => _interface.isInit;

  Future<String> validateConfig(String path) async {
    final res = await _interface.validateConfig(path);
    return res;
  }

  /// An age-encrypted config is rewritten in place into its plaintext, and a
  /// share-link list into a config of its proxies.
  Future<String> validateProfile(
    String path, [
    String ageSecretKey = '',
  ]) async {
    final file = File(path);
    if (await file.isAgeEncrypted) {
      if (ageSecretKey.isEmpty) {
        throw const AgeSecretKeyRequiredException();
      }
      await file.safeWriteAsString(
        await _interface.decryptConfig(path, ageSecretKey),
      );
    }
    final message = await validateConfig(path);
    if (message.isEmpty) {
      return message;
    }
    final List<Map<String, dynamic>> proxies;
    try {
      proxies = await _interface.convertProxies(path);
    } on Exception {
      return message;
    }
    if (proxies.isEmpty) {
      return message;
    }
    await file.safeWriteAsString(await encodeYamlTask({'proxies': proxies}));
    return validateConfig(path);
  }

  Future<List<String>> validateProxies(List<Map<String, dynamic>> proxies) {
    if (proxies.isEmpty) {
      return Future.value(const []);
    }
    return _interface.validateProxies(proxies);
  }

  Future<List<String>> validateFilters(List<String> filters) {
    if (filters.isEmpty) {
      return Future.value(const []);
    }
    return _interface.validateFilters(filters);
  }

  Future<List<String>> encodeShareLinks(List<Map<String, dynamic>> proxies) {
    if (proxies.isEmpty) {
      return Future.value(const []);
    }
    return _interface.encodeShareLinks(proxies);
  }

  Future<List<List<Map<String, dynamic>>>> decodeShareLinks(
    List<String> lines,
  ) {
    if (lines.isEmpty) {
      return Future.value(const []);
    }
    return _interface.decodeShareLinks(lines);
  }

  Future<String> validateConfigWithData(List<int> data) async {
    final path = await appPath.tempFilePath;
    final file = File(path);
    await file.safeWriteAsBytes(data);
    final res = await _interface.validateConfig(path);
    await File(path).safeDelete();
    return res;
  }

  Future<String> updateConfig(UpdateParams updateParams) async {
    return _interface.updateConfig(updateParams);
  }

  Future<String> setupConfig({
    required SetupParams params,
    Future<void> Function()? preloadInvoke,
  }) async {
    if (preloadInvoke == null) {
      return _interface.setupConfig(params);
    }
    if (system.isWindows) {
      // Do not open listeners until the exact profile was accepted.
      final result = await _interface.setupConfig(params);
      if (result.isEmpty) await preloadInvoke();
      return result;
    }
    final (result, _) = await (
      _interface.setupConfig(params),
      preloadInvoke(),
    ).wait;
    return result;
  }

  Future<List<Group>> getProxiesGroups({
    required ProxiesSortType sortType,
    required DelayMap delayMap,
    required Map<String, String> selectedMap,
    required String defaultTestUrl,
  }) async {
    final proxiesData = await _interface.getProxies();
    return toGroupsTask(
      ComputeGroupsState(
        proxiesData: proxiesData,
        sortType: sortType,
        delayMap: delayMap,
        selectedMap: selectedMap,
        defaultTestUrl: defaultTestUrl,
      ),
    );
  }

  Future<ChangeProxyResult> changeProxy(ChangeProxyParams changeProxyParams) {
    return _interface.changeProxy(changeProxyParams);
  }

  /// What [groupName] was last set to, read from the Core without building
  /// groups: the pin of a group that picks by testing, empty when it has
  /// none, and the node any other group runs.
  Future<String?> groupPick(String groupName) async {
    final group = (await _interface.getProxies()).proxies[groupName];
    if (group is! Map) return null;
    return (group.containsKey('fixed') ? group['fixed'] : group['now'])
        as String?;
  }

  Future<RouteSnapshot?> watchRoute(bool watch) {
    return _interface.watchRoute(watch);
  }

  Future<RouteCheck?> checkRoutes(CheckRoutesParams params) {
    return _interface.checkRoutes(params);
  }

  Future<List<TrackerInfo>> getConnections() async {
    return _interface.getConnections();
  }

  Future<int> getConnectionCount() async {
    return _interface.getConnectionCount();
  }

  Future<void> closeConnection(String id) async {
    await _invalidateConnectionsDuring(() => _interface.closeConnection(id));
  }

  Future<void> closeConnections() async {
    await _invalidateConnectionsDuring(_interface.closeConnections);
  }

  Future<void> resetConnections() async {
    await _invalidateConnectionsDuring(_interface.resetConnections);
  }

  Future<bool> clearDnsCache() async {
    return _interface.clearDnsCache();
  }

  Future<List<ExternalProvider>> getExternalProviders() async {
    return _interface.getExternalProviders();
  }

  Future<ExternalProvider?> getExternalProvider(
    String externalProviderName,
  ) async {
    return _interface.getExternalProvider(externalProviderName);
  }

  Future<String> updateGeoData(String type) {
    return _interface.updateGeoData(type);
  }

  Future<String> sideLoadExternalProvider({
    required String providerName,
    required String path,
    required String type,
    required String data,
  }) {
    return _interface.sideLoadExternalProvider(
      providerName: providerName,
      path: path,
      type: type,
      data: data,
    );
  }

  Future<String> dumpRuleSet(String path) {
    return _interface.dumpRuleSet(path);
  }

  Future<RuleSetInfo> compileRuleSet(
    String name, {
    String url = '',
    bool skipCertVerify = false,
  }) {
    return _interface.compileRuleSet(
      name,
      url: url,
      skipCertVerify: skipCertVerify,
    );
  }

  Future<String> updateExternalProvider({required String providerName}) async {
    return _interface.updateExternalProvider(providerName);
  }

  Future<bool> startListener() async {
    return _interface.startListener();
  }

  Future<bool> stopListener() async {
    return _interface.stopListener();
  }

  Future<bool> restartListener() async {
    return _interface.restartListener();
  }

  Future<bool> getTunFailed() => _interface.getTunFailed();

  Future<Delay?> getDelay(
    String url,
    String proxyName,
    Duration timeout,
  ) async {
    return _interface.asyncTestDelay(url, proxyName, timeout);
  }

  Future<ProxySpeedResult?> speedTest(ProxySpeedRequest request) =>
      _interface.speedTest(request);

  Future<OutboundIpResult?> outboundIp(OutboundIpParams params) =>
      _interface.outboundIp(params);

  Future<Map<String, String>> getAppliedHosts() => _interface.getAppliedHosts();

  Future<List<Map<String, dynamic>>> zapretCdnCheck() => _interface.zapretCdnCheck();

  Future<List<ServiceCheckItem>> serviceCheck(ServiceCheckParams params) =>
      _interface.serviceCheck(params);

  Future<Map<String, dynamic>> getConfig(int id) async {
    return _readConfig(await appPath.getProfilePath(id.toString()));
  }

  Future<Map<String, dynamic>> _readConfig(String path) async {
    final data = Map<String, dynamic>.from(await _interface.getConfig(path));
    data['rules'] = data['rule'];
    data.remove('rule');
    return data;
  }

  Future<Map<String, dynamic>> getProfileOutbounds(int id) async {
    return _interface.getProfileOutbounds(
      await appPath.getProfilePath(id.toString()),
    );
  }

  Future<Map<String, dynamic>?> getProxyDefinition(String name) {
    return _interface.getProxyDefinition(name);
  }

  Future<String> buildProfile(SetupBase base) async {
    return readSpilledText(await _interface.buildProfile(base));
  }

  Future<({ProfileBase base, String path})> getProfileBase(int id) async {
    final path = await appPath.getProfilePath(id.toString());
    final base = await _interface.getProfileBase(path);
    final config = Map<String, dynamic>.from(base.config)..remove('rule');
    return (base: base.copyWith(config: config), path: path);
  }

  Future<Traffic> getTraffic(bool onlyStatisticsProxy) async {
    return _interface.getTraffic(onlyStatisticsProxy);
  }

  Future<Traffic> getTotalTraffic(bool onlyStatisticsProxy) async {
    return _interface.getTotalTraffic(onlyStatisticsProxy);
  }

  Future<CoreMemoryStats?> getMemoryStats() async {
    return _interface.getMemoryStats();
  }

  Future<String> getCoreVersion() async {
    return _interface.getCoreVersion();
  }

  /// Feature discovery must use the running process, not the installed
  /// manifest or the upstream Mihomo version. Old signed hosts lack this RPC.
  Future<Set<String>> getCoreCapabilities() async {
    try {
      final data = await _interface.invokeMethod<List<dynamic>>(
        method: CoreMethod.getCoreCapabilities,
      );
      return data?.whereType<String>().toSet() ?? const {};
    } on CoreMethodException catch (error) {
      if (error.code == 'not_implemented') return const {};
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCoreIdentity() async {
    try {
      return await _interface.invokeMethod<Map<String, dynamic>>(
        method: CoreMethod.getCoreIdentity,
      );
    } on CoreMethodException catch (error) {
      if (error.code == 'not_implemented') return null;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> getChainHealth() async {
    final result = await _interface.invokeMethod<Map<String, dynamic>>(
      method: CoreMethod.getChainHealth,
    );
    if (result == null) throw const CoreMethodException(code: 'no_response', message: 'No chain health response');
    return result;
  }

  Future<void> setChainHealth({
    required String name, required String group, required String identity,
    required bool enabled,
  }) async {
    final result = await _interface.invokeMethod<bool>(
      method: CoreMethod.setChainHealth,
      arguments: {'name': name, 'group': group, 'identity': identity, 'enabled': enabled},
    );
    if (result != true) throw const CoreMethodException(code: 'invalid_response', message: 'Chain health setting not applied');
  }

  Future<Map<String, dynamic>> getEngineDiagnostics() async {
    final result = await _interface.invokeMethod<Map<String, dynamic>>(
      method: CoreMethod.getEngineDiagnostics,
    );
    if (result == null) {
      throw const CoreMethodException(code: 'no_response', message: 'No engine diagnostics response');
    }
    return result;
  }

  /// Z3 accepts a complete settings object. Serialize all client writes,
  /// including read/modify/write, to avoid lost updates between pages.
  Future<Map<String, dynamic>> patchEngineDiagnostics({
    int? closedFlowCapacity,
    bool? chainDiagnostics,
    bool Function()? isCurrent,
  }) {
    final generation = _engineDiagnosticsGeneration;
    void checkGeneration() {
      if (generation != _engineDiagnosticsGeneration || isCurrent?.call() == false) {
        throw const CoreMethodException(
          code: 'no_response', message: 'Core diagnostics request superseded',
        );
      }
    }
    return _engineDiagnosticsScheduler.run(() async {
      checkGeneration();
      final snapshot = await getEngineDiagnostics();
      checkGeneration();
      final settings = snapshot['settings'] as Map;
      await _writeEngineDiagnostics(
        closedFlowCapacity: closedFlowCapacity ?? settings['closedFlowCapacity'] as int,
        chainDiagnostics: chainDiagnostics ?? settings['chainDiagnostics'] as bool,
      );
      checkGeneration();
      final updated = await getEngineDiagnostics();
      checkGeneration();
      return updated;
    });
  }

  Future<void> setEngineDiagnostics({
    required int closedFlowCapacity,
    required bool chainDiagnostics,
  }) {
    final generation = _engineDiagnosticsGeneration;
    return _engineDiagnosticsScheduler.run(() {
      if (generation != _engineDiagnosticsGeneration) {
        throw const CoreMethodException(
          code: 'no_response', message: 'Core diagnostics request superseded',
        );
      }
      return _writeEngineDiagnostics(
        closedFlowCapacity: closedFlowCapacity, chainDiagnostics: chainDiagnostics,
      );
    });
  }

  Future<void> _writeEngineDiagnostics({
    required int closedFlowCapacity,
    required bool chainDiagnostics,
  }) async {
    final result = await _interface.invokeMethod<Map<String, dynamic>>(
      method: CoreMethod.setEngineDiagnostics,
      arguments: {
        'closedFlowCapacity': closedFlowCapacity,
        'chainDiagnostics': chainDiagnostics,
      },
    );
    if (result == null || result['closedFlowCapacity'] != closedFlowCapacity ||
        result['chainDiagnostics'] != chainDiagnostics) {
      throw const CoreMethodException(code: 'invalid_response', message: 'Diagnostics settings not applied');
    }
  }

  Future<bool> shutdown() => _interface.shutdown();

  Future<void> resetTraffic() async {
    await _interface.resetTraffic();
  }

  void startLog() {
    _interface.startLog();
  }

  void setHostActive(bool active) {
    _interface.setHostActive(active);
  }

  void stopLog() {
    _interface.stopLog();
  }

  Future<void> requestGc() async {
    await _interface.forceGc();
  }

  Future<void> crash() async {
    await _interface.crash();
  }

  Future<String> clearEffect(int profileId) async {
    return _interface.clearEffect(profileId);
  }
}

final coreController = CoreController();

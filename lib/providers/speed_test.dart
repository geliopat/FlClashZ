import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum SpeedTestService { cloudflare, yandex, custom, cachefly }

// The old Yandex selection is migrated for VPN tests only. DIRECT is fixed
// to Internetometer independently, including at the Go IPC boundary.
SpeedTestService vpnSpeedService(SpeedTestService service) =>
    service == SpeedTestService.yandex ? SpeedTestService.cloudflare : service;

const speedTestDefaultDownload = 'https://speed.cloudflare.com/__down?bytes=16777216';
const speedTestDefaultUpload = 'https://speed.cloudflare.com/__up';

const delayTestPresets = <String, String>{
  'Google': defaultTestUrl,
  'Cloudflare': 'https://cp.cloudflare.com/generate_204',
  'Microsoft': 'https://www.msftconnecttest.com/connecttest.txt',
  'Apple': 'https://captive.apple.com/hotspot-detect.html',
  'Firefox': 'https://detectportal.firefox.com/success.txt',
  'Ubuntu': 'http://connectivity-check.ubuntu.com/',
  'Yandex': 'https://yandex.ru/',
  'YouTube': 'https://www.youtube.com/generate_204',
  'GitHub': 'https://github.com/',
};

bool validTestEndpoint(String text) {
  final uri = Uri.tryParse(text);
  return uri != null && (uri.scheme == 'http' || uri.scheme == 'https') &&
      uri.host.isNotEmpty && uri.userInfo.isEmpty && !uri.hasFragment;
}

class SpeedTestSettings {
  const SpeedTestSettings({
    this.service = SpeedTestService.cloudflare,
    this.downloadUrl = speedTestDefaultDownload,
    this.uploadUrl = speedTestDefaultUpload,
    this.streams = 4,
    this.seconds = 8,
    this.maxMB = 100,
    this.direction = 'both',
  });
  final SpeedTestService service;
  final String downloadUrl;
  final String uploadUrl;
  final int streams, seconds, maxMB;
  final String direction;
  static const streamOptions = [1, 2, 4, 6, 8];
  static const timeOptions = [3, 5, 8, 10, 15, 20, 25];
  static const volumeOptions = [10, 25, 50, 100, 200, 500];
  SpeedTestSettings copyWith({
    SpeedTestService? service, String? downloadUrl, String? uploadUrl,
    int? streams, int? seconds, int? maxMB, String? direction,
  }) => SpeedTestSettings(
    service: service ?? this.service,
    downloadUrl: downloadUrl ?? this.downloadUrl,
    uploadUrl: uploadUrl ?? this.uploadUrl,
    streams: streams ?? this.streams,
    seconds: seconds ?? this.seconds,
    maxMB: maxMB ?? this.maxMB,
    direction: direction ?? this.direction,
  );
}

final speedTestSettingsProvider =
    NotifierProvider<SpeedTestSettingsController, SpeedTestSettings>(
      SpeedTestSettingsController.new,
    );

class SpeedTestSettingsController extends Notifier<SpeedTestSettings> {
  int _revision = 0;
  Future<void> _writes = Future.value();
  @override
  SpeedTestSettings build() {
    unawaited(_load());
    return const SpeedTestSettings();
  }

  Future<void> _load() async {
    final revision = _revision;
    final prefs = await SharedPreferences.getInstance();
    if (!ref.mounted || revision != _revision) return;
    state = SpeedTestSettings(
      service: vpnSpeedService(SpeedTestService.values.asNameMap()[
        prefs.getString('speedTest.service')
      ] ?? SpeedTestService.cloudflare),
      downloadUrl: prefs.getString('speedTest.download') ?? speedTestDefaultDownload,
      uploadUrl: prefs.getString('speedTest.upload') ?? speedTestDefaultUpload,
      streams: SpeedTestSettings.streamOptions.contains(prefs.getInt('speedTest.streams')) ? prefs.getInt('speedTest.streams')! : 4,
      seconds: SpeedTestSettings.timeOptions.contains(prefs.getInt('speedTest.seconds')) ? prefs.getInt('speedTest.seconds')! : 8,
      maxMB: SpeedTestSettings.volumeOptions.contains(prefs.getInt('speedTest.maxMB')) ? prefs.getInt('speedTest.maxMB')! : 100,
      direction: const ['both', 'download', 'upload'].contains(prefs.getString('speedTest.direction')) ? prefs.getString('speedTest.direction')! : 'both',
    );
  }

  Future<void> set(SpeedTestSettings settings) async {
    if (!validTestEndpoint(settings.downloadUrl) ||
        !validTestEndpoint(settings.uploadUrl)) {
      return;
    }
    _revision++;
    state = settings.copyWith(service: vpnSpeedService(settings.service));
    final latest = state;
    _writes = _writes.then((_) async {
      try {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('speedTest.service', latest.service.name);
    await prefs.setString('speedTest.download', latest.downloadUrl);
    await prefs.setString('speedTest.upload', latest.uploadUrl);
    await prefs.setInt('speedTest.streams', latest.streams);
    await prefs.setInt('speedTest.seconds', latest.seconds);
    await prefs.setInt('speedTest.maxMB', latest.maxMB);
    await prefs.setString('speedTest.direction', latest.direction);
      } catch (_) {}
    });
    await _writes;
  }
}

bool speedTestableProxy(Proxy proxy) =>
    GroupTypeExtension.getGroupType(proxy.type) == null &&
    !GroupType.values.any((group) => group.value == proxy.type.toLowerCase()) &&
    proxy.name.isNotEmpty &&
    (proxy.name == 'DIRECT' ||
      !{'DIRECT', 'REJECT', 'REJECT-DROP', 'PASS', 'COMPATIBLE'}
          .contains(proxy.name.toUpperCase())) &&
    (proxy.name == 'DIRECT' || proxy.type.toLowerCase() != 'direct');

Set<String> speedTestTargets(List<Group> groups) {
  final groupNames = groups.map((group) => group.name).toSet();
  return {
    for (final group in groups)
      for (final proxy in group.all)
        if (!groupNames.contains(proxy.name) && speedTestableProxy(proxy))
          proxy.name,
    'DIRECT',
  };
}

class SpeedTestState {
  const SpeedTestState({this.pending = const {}, this.running,
    this.results = const {}, this.busy = false});
  final Set<String> pending;
  final String? running;
  final Map<String, ProxySpeedResult> results;
  final bool busy;
}

final speedTestProvider = NotifierProvider<SpeedTestController, SpeedTestState>(
  SpeedTestController.new,
);

class SpeedTestController extends Notifier<SpeedTestState> {
  int _generation = 0;
  @override
  SpeedTestState build() {
    ref.listen(currentProfileIdProvider, (_, _) => _invalidate());
    ref.listen(coreStatusProvider, (_, status) {
      if (status != CoreStatus.connected) _invalidate();
    });
    ref.listen(speedTestSettingsProvider, (_, _) => _invalidate());
    return const SpeedTestState();
  }

  void _invalidate() {
    _generation++;
    state = SpeedTestState(busy: state.busy);
  }

  Future<void> testAll() => _run(speedTestTargets(ref.read(groupsProvider)));

  Future<void> testProxy(Proxy proxy) async {
    final group = ref.read(groupsProvider).getGroup(proxy.name);
    if (!speedTestableProxy(proxy) && group == null) return;
    await _run({proxy.name});
  }

  Future<void> testGroup(String name) async {
    if (ref.read(groupsProvider).getGroup(name) == null) return;
    await _run({name});
  }

  Future<void> testGroupMembers(String name) async {
    final groups = ref.read(groupsProvider);
    final visited = <String>{};
    final targets = <String>{};
    void walk(String groupName) {
      if (!visited.add(groupName)) return;
      final group = groups.getGroup(groupName);
      if (group == null) return;
      for (final p in group.all) {
        if (groups.getGroup(p.name) != null) { walk(p.name); }
        else if (speedTestableProxy(p)) { targets.add(p.name); }
      }
    }
    walk(name);
    await _run(targets);
  }

  Future<void> _run(Set<String> targets) async {
    if (targets.isEmpty || state.busy ||
        ref.read(coreStatusProvider) != CoreStatus.connected) {
      return;
    }
    final settings = ref.read(speedTestSettingsProvider);
    final generation = ++_generation;
    final pending = {...targets};
    final results = {...state.results};
    state = SpeedTestState(pending: {...pending}, results: {...results}, busy: true);
    try {
      for (final name in targets) {
        if (!ref.mounted || generation != _generation) break;
        state = SpeedTestState(pending: {...pending}, running: name,
            results: {...results}, busy: true);
        ProxySpeedResult? result;
        try {
          result = await ref.read(coreHandlerProvider).speedTest(
            ProxySpeedRequest(
              proxyName: name,
              service: name == 'DIRECT' ? 'yandex' : vpnSpeedService(settings.service).name,
              downloadUrl: settings.downloadUrl,
              uploadUrl: settings.uploadUrl,
              streams: settings.streams,
              seconds: settings.seconds,
              maxMB: settings.maxMB,
              direction: settings.direction,
            ),
          );
        } catch (_) {
          result = null;
        }
        if (!ref.mounted || generation != _generation) break;
        pending.remove(name);
        results[name] = result ?? const ProxySpeedResult(
          downloadError: 'failed', uploadError: 'failed',
        );
        state = SpeedTestState(pending: {...pending}, results: {...results}, busy: true);
      }
    } finally {
      if (ref.mounted) state = SpeedTestState(results: state.results);
    }
  }
}


/// Keep the custom URL independently of the currently active preset. The
/// actual probe still reads AppSettingProps.testUrl, so profile-specific
/// health-check URLs and existing routing semantics are not changed.
final customDelayUrlProvider = NotifierProvider<CustomDelayUrlController, String>(
  CustomDelayUrlController.new,
);
class CustomDelayUrlController extends Notifier<String> {
  int _revision = 0;
  static const _key = 'networkTests.customDelayUrl';

  @override
  String build() {
    final current = ref.read(appSettingProvider).testUrl;
    final initial = validTestEndpoint(current) && !delayTestPresets.containsValue(current)
        ? current : 'https://connectivitycheck.gstatic.com/generate_204';
    unawaited(_load(initial));
    return initial;
  }

  Future<void> _load(String initial) async {
    final revision = _revision;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted || revision != _revision) return;
      final current = ref.read(appSettingProvider).testUrl;
      final saved = prefs.getString(_key);
      // A restored legacy config containing a custom URL wins over stale prefs.
      state = validTestEndpoint(current) && !delayTestPresets.containsValue(current)
          ? current : saved != null && validTestEndpoint(saved) ? saved : initial;
    } catch (_) {
      // Keep the in-memory value if preferences are temporarily unavailable.
    }
  }

  Future<void> remember(String url) async {
    if (!validTestEndpoint(url)) return;
    final revision = ++_revision;
    state = url;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (!ref.mounted || revision != _revision) return;
      await prefs.setString(_key, url);
    } catch (_) {
      // Keep the current session's custom URL.
    }
  }

  void choose(String choice) {
    final current = ref.read(appSettingProvider).testUrl;
    if (choice != 'custom' && !delayTestPresets.containsValue(current)) {
      unawaited(remember(current));
    }
    final url = choice == 'custom' ? state : delayTestPresets[choice];
    if (url != null && validTestEndpoint(url)) {
      ref.read(appSettingProvider.notifier).update((s) => s.copyWith(testUrl: url));
    }
  }
}

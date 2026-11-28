import 'dart:convert';
import 'dart:io';

import 'package:fl_clash/common/constant.dart';
import 'package:fl_clash/core/controller.dart';
import 'package:fl_clash/models/models.dart';
import 'package:flutter/foundation.dart';

const directOutbound = 'DIRECT';
const routedOutbound = '';

/// [id] must match the checker name registered in core/service_check.go.
enum ServiceTarget {
  google('google', 'Google', 'google'),
  github('github', 'GitHub', 'github'),
  youtube('youtube', 'YouTube', 'youtube'),
  chatgpt('chatgpt', 'ChatGPT', 'openai'),
  claude('claude', 'Claude', 'claude'),
  gemini('gemini', 'Gemini', 'gemini'),
  netflix('netflix', 'Netflix', 'netflix'),
  disneyPlus('disney-plus', 'Disney+', 'disneyplus'),
  primeVideo('prime-video', 'Prime Video', 'primevideo'),
  spotify('spotify', 'Spotify', 'spotify'),
  tiktok('tiktok', 'TikTok', 'tiktok'),
  discord('discord', 'Discord', 'discord'),
  gosuslugi('gosuslugi', 'Госуслуги', 'gosuslugi'),
  sberbank('sberbank', 'Сбербанк', 'sberbank'),
  vk('vk', 'VK', 'vk'),
  yandex('yandex', 'Яндекс', 'yandex'),
  kinopoisk('kinopoisk', 'Кинопоиск', 'kinopoisk');

  const ServiceTarget(this.id, this.label, this.icon);

  final String id;
  final String label;
  final String icon;

  static ServiceTarget? byId(String id) {
    for (final target in values) {
      if (target.id == id) return target;
    }
    return null;
  }
}

enum ServiceProbeStatus {
  available('available'),
  unavailable('unavailable'),
  restricted('restricted'),
  disallowedIsp('disallowed-isp'),
  blocked('blocked'),
  unsupportedRegion('unsupported-region'),
  originalsOnly('originals-only'),
  comingSoon('coming-soon'),
  timeout('timeout'),
  failed('failed');

  const ServiceProbeStatus(this.id);

  final String id;

  static ServiceProbeStatus byId(String id) {
    for (final status in values) {
      if (status.id == id) return status;
    }
    return ServiceProbeStatus.failed;
  }
}

List<ServiceTarget> orderServiceTargets(List<String> order) {
  return {
    for (final id in order) ?ServiceTarget.byId(id),
    ...ServiceTarget.values,
  }.toList();
}

class ServiceCheck {
  const ServiceCheck(
    this.status, {
    this.delay,
    this.chains = const [],
    this.region,
    this.checkedAt,
    this.coreEpoch = 0,
    this.routeVersion = 0,
    this.hits = const [],
  });

  factory ServiceCheck.of(ServiceCheckItem item) {
    return ServiceCheck(
      ServiceProbeStatus.byId(item.status),
      delay: item.delay > 0 ? item.delay : null,
      chains: item.chains,
      region: item.region.isEmpty ? null : item.region,
      checkedAt: item.checkedAt > 0
          ? DateTime.fromMillisecondsSinceEpoch(item.checkedAt)
          : null,
      coreEpoch: item.coreEpoch,
      routeVersion: item.routeVersion,
      hits: item.hits,
    );
  }

  final ServiceProbeStatus status;
  final int? delay;
  final List<String> chains;
  final String? region;
  final DateTime? checkedAt;
  final int coreEpoch;
  final int routeVersion;
  final List<RouteHit> hits;

  String? get node => chains.firstOrNull;

  @override
  bool operator ==(Object other) =>
      other is ServiceCheck &&
      other.status == status &&
      other.delay == delay &&
      listEquals(other.chains, chains) &&
      other.region == region &&
      other.checkedAt == checkedAt &&
      other.coreEpoch == coreEpoch &&
      other.routeVersion == routeVersion &&
      listEquals(other.hits, hits);

  @override
  int get hashCode => Object.hash(
    status,
    delay,
    Object.hashAll(chains),
    region,
    checkedAt,
    coreEpoch,
    routeVersion,
    Object.hashAll(hits),
  );

  @override
  String toString() =>
      'ServiceCheck(${status.id}, delay: $delay, node: $node, region: $region)';
}

/// An empty [proxyName] lets the Core route by its rules; an empty [targets]
/// checks every service.
Future<Map<ServiceTarget, ServiceCheck>> checkServices(
  CoreController core, {
  String proxyName = '',
  List<ServiceTarget> targets = const [],
  Duration timeout = probeTimeoutDuration,
}) async {
  final items = await core.serviceCheck(
    ServiceCheckParams(
      proxyName: proxyName,
      names: targets.map((target) => target.id).toList(),
      timeout: timeout.inMilliseconds,
    ),
  );
  return {
    for (final item in items)
      ?ServiceTarget.byId(item.name): ServiceCheck.of(item),
  };
}

IpInfo Function(String) _json(IpInfo Function(Map<String, dynamic>) parse) {
  return (body) => parse(jsonDecode(body) as Map<String, dynamic>);
}

/// None behind Cloudflare: where it is throttled, a direct lookup stalls on
/// those until the timeout.
final Map<String, IpInfo Function(String)> ipInfoSources = {
  'http://ip-api.com/json': _json(IpInfo.fromIpAPIJson),
  'https://ipinfo.io/json': _json(IpInfo.fromIpInfoJson),
  'https://api.ipquery.io/?format=json': _json(IpInfo.fromIpQueryJson),
  'https://api.seeip.org/geoip': _json(IpInfo.fromSeeIpJson),
  'https://ident.me/json': _json(IpInfo.fromIdentMeJson),
};

/// Additional opt-in sources. Automatic selection keeps the original race.
const selectableIpSources = <String, String>{
  'IPinfo': 'https://ipinfo.io/json',
  'IPWhois': 'https://ipwho.is/',
  'IPAPI': 'http://ip-api.com/json',
  'ipapi.co': 'https://ipapi.co/json/',
  'GeoJS': 'https://get.geojs.io/v1/ip/geo.json',
  'Cloudflare': 'https://www.cloudflare.com/cdn-cgi/trace',
  'DB-IP': 'https://api.db-ip.com/v2/free/self',
  'FreeIPAPI': 'https://free.freeipapi.com/api/v1/json/',
  'IPify': 'https://api.ipify.org?format=json',
  'AWS': 'https://checkip.amazonaws.com/',
};

IpInfo? parseFlexibleIpBody(String body) {
  final plain = body.trim();
  String? ip;
  String? country;
  if (InternetAddress.tryParse(plain) != null) {
    ip = plain;
  } else if (plain.startsWith('{')) {
    final Object? value;
    try {
      value = jsonDecode(plain);
    } on FormatException {
      return null;
    }
    if (value is! Map || value['success'] == false ||
        value['error'] == true || value['status'] == 'fail') {
      return null;
    }
    final address = value['ip'] ?? value['query'] ?? value['ipAddress'];
    if (address is! String) return null;
    ip = address;
    final code = value['country_code'] ?? value['countryCode'] ??
        value['country'] ?? value['cc'];
    if (code is String) country = code;
  } else {
    final fields = <String, String>{};
    for (final line in plain.split('\n')) {
      final split = line.indexOf('=');
      if (split > 0) fields[line.substring(0, split)] = line.substring(split + 1).trim();
    }
    ip = fields['ip'];
    country = fields['loc'];
  }
  if (ip == null || InternetAddress.tryParse(ip) == null) return null;
  final code = country?.trim().toUpperCase() ?? '';
  return IpInfo(ip: ip, countryCode: RegExp(r'^[A-Z]{2}$').hasMatch(code) ? code : '');
}

/// Raw so the route stamp survives; [parseOutboundIp] reads the address.
Future<OutboundIpResult?> lookupOutboundIp(
  CoreController core,
  String proxyName, {
  Duration timeout = outboundIpTimeoutDuration,
  List<String>? urls,
}) {
  return core.outboundIp(
    OutboundIpParams(
      proxyName: proxyName,
      urls: urls ?? ipInfoSources.keys.toList(),
      timeout: timeout.inMilliseconds,
    ),
  );
}

IpInfo? parseOutboundIp(OutboundIpResult? result, {String? customUrl}) {
  if (result == null || result.error != null || result.body.isEmpty) {
    return null;
  }
  final parse = ipInfoSources[result.url];
  try {
    if (parse != null) return parse(result.body);
    if (selectableIpSources.containsValue(result.url) || result.url == customUrl) {
      return parseFlexibleIpBody(result.body);
    }
    return null;
  } on FormatException {
    return null;
  } on TypeError {
    return null;
  }
}

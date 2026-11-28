import 'dart:convert';

import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/models/models.dart';
import 'package:fl_clash/ui/color.dart';
import 'package:material_ui/material_ui.dart' show ThemeMode;
import 'package:test/test.dart';

const _gib = 1024 * 1024 * 1024;

Profile _profile({
  Map<String, String> headers = const {},
  SubscriptionInfo? info,
}) => Profile(
  id: 1,
  autoUpdateDuration: Duration.zero,
  providerHeaders: headers,
  subscriptionInfo: info,
);

void main() {
  group('FlClashZ header names', () {
    test('new names work for every inherited header', () {
      const headers = ProviderHeaders({
        'flclashz-view': 'app.theme:dark',
        'flclashz-widgets': 'profiles,zapret',
        'flclashz-background': 'https://example.com/bg.png,25',
        'flclashz-settings': 'autostart',
        'flclashz-special': 'denywidgets,hideip',
        'flclashz-update': 'https://example.com/stable.json',
        'flclashz-update-pre': 'https://example.com/pre.json',
        'flclashz-servicename': 'My VPN',
        'flclashz-servicelogo': 'https://example.com/logo.svg',
        'flclashz-serverinfo': 'Auto',
        'flclashz-buyplan': 'https://example.com/plan,3',
        'flclashz-buytraffic': 'https://example.com/traffic,10',
        'flclashz-newdomain': 'backup.example.com',
      });
      expect(headers.view?.themeMode, ThemeMode.dark);
      expect(headers.dashboardWidgets, [DashboardWidget.profiles, DashboardWidget.zapret]);
      expect(headers.background?.visibility, 25);
      expect(headers.appSwitches, {'autostart'});
      expect(headers.widgetEditingDenied, isTrue);
      expect(headers.hideIp, isTrue);
      expect(headers.updateManifestUrl, 'https://example.com/stable.json');
      expect(headers.preUpdateManifestUrl, 'https://example.com/pre.json');
      expect(headers.serviceName, 'My VPN');
      expect(headers.serviceLogo, 'https://example.com/logo.svg');
      expect(headers.serverGroup, 'Auto');
      expect(headers.buyPlan?.threshold, 3);
      expect(headers.buyTraffic?.threshold, 10);
      expect(headers.fallbackHosts, ['backup.example.com']);
    });
    test('new wins, including empty or invalid, without merging', () {
      const headers = ProviderHeaders({
        'flclashx-settings': 'minimize',
        'flclashz-settings': 'autostart',
        'flclashx-special': 'denywidgets',
        'flclashz-special': '',
        'flclashx-update': 'https://old.example.com/manifest.json',
        'flclashz-update': 'invalid',
        'flclashx-view': 'app.theme:dark',
        'flclashz-view': 'app.theme:light',
        'flclashx-newdomain': 'backup.example.com',
        'flclashx-zapret': 'autostart',
      });
      expect(headers.appSwitches, {'autostart'});
      expect(headers.widgetEditingDenied, isFalse);
      expect(headers.updateManifestUrl, isNull);
      expect(headers.view?.themeMode, ThemeMode.light);
      expect(headers.fallbackHosts, ['backup.example.com']);
      expect(headers.zapret, isNull);
    });
  });
  group('flclashz-zapret', () {
    test('captures header case-insensitively and parses presence flags', () {
      final headers = providerHeadersOf({'FlClashZ-Zapret': [' AUTOSTART, mode:StrictSplit, AutoFallback, autotune, tunemode:VeryFast, tuneonfail '], 'other': ['ignored']});
      expect(headers.keys, ['flclashz-zapret']);
      final policy = ProviderHeaders(headers).zapret!;
      expect(policy.autostart, isTrue);
      expect(policy.autofallback, isTrue);
      expect(policy.autotune, isTrue);
      expect(policy.tuneonfail, isTrue);
      expect(policy.mode, 'strictsplit');
      expect(policy.tunemode, 'veryfast');
    });
    test('empty or partial header turns absent flags off; no header is null', () {
      expect(const ProviderHeaders({}).zapret, isNull);
      final empty = const ProviderHeaders({'flclashz-zapret': ''}).zapret!;
      expect((empty.autostart, empty.autofallback, empty.autotune, empty.tuneonfail), (false, false, false, false));
      final partial = parseZapretHeader('autostart,mode:fullbypass,tunemode:full')!;
      expect(partial.autostart, isTrue);
      expect(partial.autofallback, isFalse);
      expect(partial.mode, 'fullbypass');
      expect(partial.tunemode, 'full');
    });
    test('ignores invalid values and unknown keys, last valid value wins', () {
      final policy = parseZapretHeader('autostart:false,autotune:true,mode:strictsplit,mode:bad,mode:fullbypass,tunemode:fast,tunemode:bad,unknown')!;
      expect(policy.autostart, isFalse);
      expect(policy.autotune, isFalse);
      expect(policy.mode, 'fullbypass');
      expect(policy.tunemode, 'fast');
      expect(parseZapretHeader('mode:bad,tunemode:bad')!.mode, isNull);
      expect(parseZapretHeader('mode:bad,tunemode:bad')!.tunemode, isNull);
    });
  });
  group('LinkOffer.parse', () {
    test('reads the link alone, or with its threshold after a comma', () {
      expect(
        LinkOffer.parse('https://pay.example.com/plan'),
        const LinkOffer(url: 'https://pay.example.com/plan'),
      );
      expect(
        LinkOffer.parse(' https://pay.example.com/plan , 3 '),
        const LinkOffer(url: 'https://pay.example.com/plan', threshold: 3),
      );
      expect(
        LinkOffer.parse('https://pay.example.com/q?a=1,b,10'),
        const LinkOffer(url: 'https://pay.example.com/q?a=1,b', threshold: 10),
      );
    });

    test('ignores what is not a link and a threshold that is not a number', () {
      expect(LinkOffer.parse(null), isNull);
      expect(LinkOffer.parse('pay now'), isNull);
      for (final threshold in ['soon', 'NaN', 'Infinity', '-Infinity']) {
        expect(
          LinkOffer.parse('https://pay.example.com,$threshold'),
          const LinkOffer(url: 'https://pay.example.com'),
          reason: threshold,
        );
      }
    });
  });

  group('update manifest header', () {
    test('independent core manifest is captured and separate from app updates', () {
      final headers = ProviderHeaders(providerHeadersOf({
        'FlClashZ-Update-Core': [' https://mirror.example/core-manifest.json '],
        'FlClashZ-Update': ['https://mirror.example/app.json'],
      }));
      expect(headers.coreUpdateManifestUrl, 'https://mirror.example/core-manifest.json');
      expect(headers.updateManifestUrl, 'https://mirror.example/app.json');
      expect(const ProviderHeaders({}).coreUpdateManifestUrl, isNull);
    });

    test('core manifest rejects invalid HTTPS origins and respects header priority', () {
      for (final value in [
        '', 'http://mirror.example/core.json', 'https:core.json',
        'https://user@mirror.example/core.json',
        'https://mirror.example:8443/core.json',
        'https://mirror.example/core.json#fragment',
      ]) {
        expect(ProviderHeaders({'flclashz-update-core': value}).coreUpdateManifestUrl, isNull,
            reason: value);
      }
      expect(const ProviderHeaders({
        'flclashx-update-core': 'https://mirror.example/old.json',
        'flclashz-update-core': 'https://mirror.example/new.json',
      }).coreUpdateManifestUrl, 'https://mirror.example/new.json');
      expect(const ProviderHeaders({
        'flclashx-update-core': 'https://mirror.example/old.json',
        'flclashz-update-core': '',
      }).coreUpdateManifestUrl, isNull);
    });

    test('reads an https manifest url per channel, rejects other schemes', () {
      const headers = ProviderHeaders({
        'flclashx-update': 'https://mirror.example/manifest.json',
        'flclashx-update-pre': 'https://mirror.example/pre.json',
      });
      expect(headers.updateManifestUrl, 'https://mirror.example/manifest.json');
      expect(headers.preUpdateManifestUrl, 'https://mirror.example/pre.json');

      expect(
        const ProviderHeaders({
          'flclashx-update': 'http://mirror.example/m.json',
        }).updateManifestUrl,
        isNull,
      );
      expect(const ProviderHeaders({}).updateManifestUrl, isNull);
      expect(const ProviderHeaders({}).preUpdateManifestUrl, isNull);
    });
  });

  group('service headers', () {
    test('read the name, logo and server group plain or base64', () {
      final encoded = base64.encode(utf8.encode('Мой VPN'));
      final headers = ProviderHeaders({
        'flclashx-servicename': encoded,
        'flclashx-servicelogo': 'https://cdn.example.com/logo.svg',
        'flclashx-serverinfo': 'Auto',
      });
      expect(headers.serviceName, 'Мой VPN');
      expect(headers.serviceLogo, 'https://cdn.example.com/logo.svg');
      expect(headers.serverGroup, 'Auto');
      expect(
        const ProviderHeaders({
          'flclashx-servicename': 'Plain Name',
        }).serviceName,
        'Plain Name',
      );
      expect(
        const ProviderHeaders({'flclashx-servicelogo': 'logo.png'}).serviceLogo,
        isNull,
      );
      expect(const ProviderHeaders({}).serviceName, isNull);
    });

    test('the board key of older panels changes nothing', () {
      expect(
        const ProviderHeaders({'flclashx-view': 'app.board:extended'}).view,
        isNull,
      );
    });

    test('providermode is a special flag', () {
      expect(
        const ProviderHeaders({
          'flclashx-special': 'hideip, ProviderMode',
        }).providerMode,
        isTrue,
      );
      expect(const ProviderHeaders({}).providerMode, isFalse);
    });
  });

  group('device headers in the answer', () {
    test('the flags read true in any case and nothing else', () {
      expect(
        _profile(
          headers: const {'x-hwid-max-devices-reached': 'True'},
        ).headers.deviceLimitReached,
        isTrue,
      );
      expect(
        _profile(
          headers: const {'x-hwid-max-devices-reached': '1'},
        ).headers.deviceLimitReached,
        isFalse,
      );
      expect(_profile().headers.deviceLimitReached, isFalse);
      expect(
        _profile(
          headers: const {'x-hwid-not-supported': 'true'},
        ).headers.deviceIdUnsupported,
        isTrue,
      );
      expect(_profile().headers.deviceIdUnsupported, isFalse);
    });

    test('the full announcement is decoded but never cut', () {
      final long = 'x' * (maxAnnouncementLength + 5);
      final headers = _profile(
        headers: {'announce': 'base64:${base64.encode(utf8.encode(long))}'},
      ).headers;
      expect(headers.fullAnnouncement, long);
      expect(headers.announcement, hasLength(maxAnnouncementLength + 1));
      expect(_profile().headers.fullAnnouncement, isNull);
    });
  });

  group('updateInterval', () {
    test('reads whole positive hours and nothing else', () {
      ProviderHeaders of(String value) =>
          ProviderHeaders({'profile-update-interval': value});
      expect(of('12').updateInterval, const Duration(hours: 12));
      expect(of(' 1 ').updateInterval, const Duration(hours: 1));
      expect(of('0').updateInterval, isNull);
      expect(of('-3').updateInterval, isNull);
      expect(of('soon').updateInterval, isNull);
      expect(const ProviderHeaders({}).updateInterval, isNull);
    });

    test('ignores an interval no date could be counted on by', () {
      ProviderHeaders of(String value) =>
          ProviderHeaders({'profile-update-interval': value});
      expect(of('8784').updateInterval, const Duration(hours: 8784));
      expect(of('8785').updateInterval, isNull);
      expect(of('2400000000').updateInterval, isNull);
    });
  });

  group('ViewRequest.parse', () {
    test('reads the proxies keys only with their prefix', () {
      expect(
        ViewRequest.parse(
          'proxies.type:tab; proxies.sort:delay ;proxies.layout:tight',
        ),
        const ViewRequest(
          type: ProxiesType.tab,
          sort: ProxiesSortType.delay,
          layout: ProxiesLayout.tight,
        ),
      );
      expect(
        ViewRequest.parse('icon:plain;proxies.card:compact'),
        const ViewRequest(card: ProxyCardType.compact),
      );
      expect(
        ViewRequest.parse('proxies.card:oneline'),
        const ViewRequest(card: ProxyCardType.oneline),
      );
    });

    test('the older icon, card and style names mean nothing now', () {
      expect(
        ViewRequest.parse(
          'proxies.icon:standard;proxies.card:expand;app.style:tonalSpot',
        ),
        isNull,
      );
      expect(ViewRequest.parse('proxies.card:min')?.card, isNull);
    });

    test('hidetimeout hides or shows the proxies that timed out', () {
      expect(
        ViewRequest.parse('proxies.hidetimeout:true')?.hideTimeout,
        isTrue,
      );
      expect(
        ViewRequest.parse('proxies.hidetimeout:False')?.hideTimeout,
        isFalse,
      );
      expect(ViewRequest.parse('proxies.hidetimeout:maybe'), isNull);
      expect(managedViewKeysOf(ViewRequest.parse('proxies.hidetimeout:true')), {
        'view.proxies.hidetimeout',
      });
    });

    test('reads the app keys only under their prefix', () {
      expect(
        ViewRequest.parse(
          'app.board:extended;app.navbar:docked;app.tabs:fade;app.glass:ultra',
        ),
        const ViewRequest(
          floatingNavigationBar: false,
          tabAnimation: TabAnimation.fade,
          liquidGlass: LiquidGlassMode.ultra,
        ),
      );
      expect(
        ViewRequest.parse('app.navbar:floating')?.floatingNavigationBar,
        isTrue,
      );
      expect(
        ViewRequest.parse('board:extended;navbar:docked;glass:ultra'),
        isNull,
      );
      expect(
        ViewRequest.parse('app.navbar:sticky;app.tabs:zoom;app.glass:max'),
        isNull,
      );
    });

    test('reads the theme mode', () {
      expect(
        ViewRequest.parse('app.theme:dark'),
        const ViewRequest(themeMode: ThemeMode.dark),
      );
      expect(ViewRequest.parse('app.theme:Auto')?.themeMode, ThemeMode.system);
      expect(ViewRequest.parse('app.theme:light')?.themeMode, ThemeMode.light);
      expect(ViewRequest.parse('app.theme:system'), isNull);
      expect(ViewRequest.parse('theme:dark'), isNull);
    });

    test('reads the colour, the style and pure black', () {
      expect(
        ViewRequest.parse(
          'app.color:#ff5733;app.style:Monochrome;app.black:true',
        ),
        const ViewRequest(
          color: 0xFFFF5733,
          colorStyle: ColorStyle.monochrome,
          pureBlack: true,
        ),
      );
      expect(ViewRequest.parse('app.color:80FF5733')?.color, 0x80FF5733);
      expect(ViewRequest.parse('app.black:no')?.pureBlack, isFalse);
      expect(
        ViewRequest.parse('app.color:FF57;app.style:rainbow;app.black:maybe'),
        isNull,
      );
    });

    test('is nothing when no key is understood', () {
      expect(ViewRequest.parse('type:grid;colour:red'), isNull);
      expect(ViewRequest.parse('no colon'), isNull);
      expect(ViewRequest.parse(null), isNull);
    });
  });

  group('dashboardWidgets', () {
    test('names the cards in order, by their current names only', () {
      expect(
        const ProviderHeaders({
          'flclashx-widgets':
              ' networkSpeed, Announcement ,metainfo,outboundModeV2,profiles',
        }).dashboardWidgets,
        [
          DashboardWidget.networkSpeed,
          DashboardWidget.announcement,
          DashboardWidget.profiles,
        ],
      );
    });

    test('accepts zapret as an ordinary flclashx-widgets entry', () {
      expect(
        const ProviderHeaders({'flclashx-widgets': 'zapret'}).dashboardWidgets,
        [DashboardWidget.zapret],
      );
      expect(
        const ProviderHeaders({
          'flclashx-widgets': 'networkSpeed,zapret,profiles',
        }).dashboardWidgets,
        [
          DashboardWidget.networkSpeed,
          DashboardWidget.zapret,
          DashboardWidget.profiles,
        ],
      );
    });

    test('drops names nothing answers to and repeats', () {
      expect(
        const ProviderHeaders({
          'flclashx-widgets': 'zashboardButton,memoryInfo,memoryinfo,future',
        }).dashboardWidgets,
        [DashboardWidget.memoryInfo],
      );
      expect(
        const ProviderHeaders({
          'flclashx-widgets': 'zashboardButton',
        }).dashboardWidgets,
        isNull,
      );
      expect(const ProviderHeaders({}).dashboardWidgets, isNull);
    });

    test('editing is denied by the denywidgets special', () {
      expect(const ProviderHeaders({}).widgetEditingDenied, isFalse);
      expect(
        const ProviderHeaders({
          'flclashx-denywidgets': 'true',
        }).widgetEditingDenied,
        isFalse,
      );
      expect(
        const ProviderHeaders({
          'flclashx-special': 'noglobal, DenyWidgets',
        }).widgetEditingDenied,
        isTrue,
      );
    });
  });

  group('PanelBackground.parse', () {
    test('reads the url alone or with how much of it to show', () {
      expect(
        PanelBackground.parse('https://cdn.example.com/bg.jpg'),
        const PanelBackground(url: 'https://cdn.example.com/bg.jpg'),
      );
      expect(
        PanelBackground.parse(' https://cdn.example.com/bg.jpg , 35 '),
        const PanelBackground(
          url: 'https://cdn.example.com/bg.jpg',
          visibility: 35,
        ),
      );
      expect(
        PanelBackground.parse('https://cdn.example.com/bg.jpg,250')?.visibility,
        100,
      );
      expect(
        PanelBackground.parse('https://cdn.example.com/bg.jpg,0')?.visibility,
        1,
      );
    });

    test('is nothing without a url', () {
      expect(PanelBackground.parse('wallpaper,40'), isNull);
      expect(PanelBackground.parse(''), isNull);
      expect(PanelBackground.parse(null), isNull);
      expect(
        PanelBackground.parse(
          'https://cdn.example.com/bg.jpg,soon',
        )?.visibility,
        isNull,
      );
    });
  });

  group('globalModeAllowed', () {
    test('is taken away only by the noglobal special', () {
      expect(const ProviderHeaders({}).globalModeAllowed, isTrue);
      expect(
        const ProviderHeaders({
          'flclashx-special': 'androidsecure',
        }).globalModeAllowed,
        isTrue,
      );
      expect(
        const ProviderHeaders({
          'flclashx-special': 'androidsecure, NoGlobal',
        }).globalModeAllowed,
        isFalse,
      );
    });
  });

  group('hideIp', () {
    test('is asked for only by the hideip special', () {
      expect(const ProviderHeaders({}).hideIp, isFalse);
      expect(
        const ProviderHeaders({'flclashx-special': 'noglobal'}).hideIp,
        isFalse,
      );
      expect(
        const ProviderHeaders({'flclashx-special': 'noglobal, HideIP'}).hideIp,
        isTrue,
      );
    });
  });

  group('noVibration', () {
    test('is asked for only by the novibrate special', () {
      expect(const ProviderHeaders({}).noVibration, isFalse);
      expect(
        const ProviderHeaders({'flclashx-special': 'hideip'}).noVibration,
        isFalse,
      );
      expect(
        const ProviderHeaders({
          'flclashx-special': 'hideip, NoVibrate',
        }).noVibration,
        isTrue,
      );
    });
  });

  group('fallbackUrlsOf', () {
    final url = Uri.parse('https://u:p@old.example.com/sub/abc?x=1');
    List<String> moved(String header) => ProviderHeaders({
      'flclashx-newdomain': header,
    }).fallbackUrlsOf(url).map((u) => u.toString()).toList();

    test('moves the link onto each host, keeping path, query and login', () {
      expect(moved('new.example.com, backup.example.net:8443'), [
        'https://u:p@new.example.com/sub/abc?x=1',
        'https://u:p@backup.example.net:8443/sub/abc?x=1',
      ]);
    });

    test('takes the scheme and port from a full origin', () {
      expect(moved('http://plain.example.com'), [
        'http://u:p@plain.example.com/sub/abc?x=1',
      ]);
      expect(
        const ProviderHeaders({
          'flclashx-newdomain': 'new.example.com',
        }).fallbackUrlsOf(Uri.parse('https://old.example.com:8443/s')),
        [Uri.parse('https://new.example.com:8443/s')],
      );
    });

    test('leaves out the current host, repeats and what is not a host', () {
      expect(moved('old.example.com, new.example.com, new.example.com'), [
        'https://u:p@new.example.com/sub/abc?x=1',
      ]);
      expect(moved('not a host, new.example.com/path, ?q, a.example.com'), [
        'https://u:p@a.example.com/sub/abc?x=1',
      ]);
      expect(moved(''), isEmpty);
      expect(const ProviderHeaders({}).fallbackUrlsOf(url), isEmpty);
    });

    test('stops at five hosts and yields nothing for a link without one', () {
      final hosts = List.generate(7, (i) => 'h$i.example.com').join(',');
      expect(moved(hosts), hasLength(5));
      expect(
        ProviderHeaders({'flclashx-newdomain': hosts}).fallbackUrlsOf(Uri()),
        isEmpty,
      );
    });
  });

  group('visibleOffersOf', () {
    final now = DateTime(2026, 10, 19, 12);
    int expireIn(int days) =>
        now.add(Duration(days: days, hours: 1)).millisecondsSinceEpoch ~/ 1000;

    test('shows nothing without a profile or without the headers', () {
      expect(visibleOffersOf(null, now: now), isEmpty);
      expect(visibleOffersOf(_profile(), now: now), isEmpty);
    });

    test('an offer without a threshold shows whatever the plan says', () {
      final profile = _profile(
        headers: const {
          'flclashx-buyplan': 'https://pay.example.com/plan',
          'flclashx-buytraffic': 'https://pay.example.com/traffic',
        },
      );
      expect(visibleOffersOf(profile, now: now), const [
        ProfileOffer(
          kind: ProfileOfferKind.buyPlan,
          url: 'https://pay.example.com/plan',
        ),
        ProfileOffer(
          kind: ProfileOfferKind.buyTraffic,
          url: 'https://pay.example.com/traffic',
        ),
      ]);
    });

    test('the renewal waits for the days left to reach its threshold', () {
      Profile ending(int days) => _profile(
        headers: const {'flclashx-buyplan': 'https://pay.example.com/plan,3'},
        info: SubscriptionInfo(expire: expireIn(days)),
      );
      expect(visibleOffersOf(ending(10), now: now), isEmpty);
      expect(visibleOffersOf(ending(3), now: now), hasLength(1));
      expect(visibleOffersOf(ending(-2), now: now), hasLength(1));
      expect(
        visibleOffersOf(
          _profile(headers: const {'flclashx-buyplan': 'https://p.example,3'}),
          now: now,
        ),
        isEmpty,
      );
    });

    test('the renewal names the moment its threshold is crossed', () {
      Profile ending(int days) => _profile(
        headers: const {'flclashx-buyplan': 'https://pay.example.com/plan,3'},
        info: SubscriptionInfo(expire: expireIn(days)),
      );
      final at = nextOfferChange(ending(10), now)!;

      expect(visibleOffersOf(ending(10), now: at), isEmpty);
      expect(
        visibleOffersOf(ending(10), now: at.add(const Duration(seconds: 1))),
        hasLength(1),
      );
      expect(nextOfferChange(ending(3), now), isNull);
      final farThreshold = _profile(
        headers: const {'flclashx-buyplan': 'https://p.example,101000000'},
        info: SubscriptionInfo(expire: expireIn(10)),
      );
      expect(nextOfferChange(farThreshold, now), isNull);
      expect(visibleOffersOf(farThreshold, now: now), hasLength(1));
      for (final threshold in ['-101000000', '-1e300', '1e300']) {
        final extreme = _profile(
          headers: {'flclashx-buyplan': 'https://p.example,$threshold'},
          info: SubscriptionInfo(expire: expireIn(10)),
        );
        expect(nextOfferChange(extreme, now), isNull);
        visibleOffersOf(extreme, now: now);
      }
      expect(
        nextOfferChange(
          _profile(headers: const {'flclashx-buyplan': 'https://p.example'}),
          now,
        ),
        isNull,
      );
    });

    test('the top-up waits for the traffic left to reach its percent', () {
      Profile used(int gib) => _profile(
        headers: const {
          'flclashx-buytraffic': 'https://pay.example.com/traffic,10',
        },
        info: SubscriptionInfo(download: gib * _gib, total: 100 * _gib),
      );
      expect(visibleOffersOf(used(50), now: now), isEmpty);
      expect(visibleOffersOf(used(90), now: now), hasLength(1));
      expect(visibleOffersOf(used(100), now: now), hasLength(1));
      expect(
        visibleOffersOf(
          _profile(
            headers: const {'flclashx-buytraffic': 'https://p.example,10'},
          ),
          now: now,
        ),
        isEmpty,
      );
    });
  });

  group('appSwitches', () {
    test('names the switches the panel turns on, lower case and trimmed', () {
      expect(
        const ProviderHeaders({
          'flclashx-settings': ' Minimize, autostart ,,OPENLOGS',
        }).appSwitches,
        {'minimize', 'autostart', 'openlogs'},
      );
    });

    test('an absent header leaves the switches to the user', () {
      expect(const ProviderHeaders({}).appSwitches, isNull);
      expect(
        const ProviderHeaders({'flclashx-settings': ''}).appSwitches,
        isNull,
      );
    });
  });

  group('specials', () {
    test('androidsecure is one of the special flags', () {
      const headers = ProviderHeaders({'flclashx-special': 'AndroidSecure, x'});
      expect(headers.specials, {'androidsecure', 'x'});
      expect(headers.androidSecure, isTrue);
    });

    test('without the header nothing special is asked', () {
      expect(const ProviderHeaders({}).specials, isNull);
      expect(const ProviderHeaders({}).androidSecure, isFalse);
    });
  });

  group('title and web page', () {
    test('the title comes plain or base64 and the page must be a URL', () {
      expect(
        const ProviderHeaders({'profile-title': 'My VPN'}).title,
        'My VPN',
      );
      expect(
        ProviderHeaders({
          'profile-title': 'base64:${base64.encode(utf8.encode('Мой VPN'))}',
        }).title,
        'Мой VPN',
      );
      expect(
        const ProviderHeaders({
          'profile-web-page-url': 'https://my.example/',
        }).webPageUrl,
        'https://my.example/',
      );
      expect(
        const ProviderHeaders({'profile-web-page-url': 'nope'}).webPageUrl,
        isNull,
      );
    });
  });
}

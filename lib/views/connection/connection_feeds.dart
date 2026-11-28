import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/views/engine_diagnostics.dart';
import 'package:fl_clash/ui/ui.dart';
import 'package:fl_clash/ui/title_tabs.dart';
import 'package:material_ui/material_ui.dart';

import 'connections.dart';
import 'requests.dart';

enum _ConnectionFeed { live, recent, closed }

class ConnectionFeedsView extends StatefulWidget {
  const ConnectionFeedsView({super.key});

  @override
  State<ConnectionFeedsView> createState() =>
      _ConnectionFeedsViewState();
}

class _ConnectionFeedsViewState extends State<ConnectionFeedsView> {
  final _shown = <_ConnectionFeed>{};
  _ConnectionFeed _feed = _ConnectionFeed.live;
  bool _pageActive = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = PageActivityScope.isActiveOf(context);
    if (active && !_pageActive) {
      _feed = _ConnectionFeed.live;
    }
    _pageActive = active;
  }

  Widget _titleTabs(_ConnectionFeed feed) {
    final l = context.appLocalizations;
    return PageTitleTabs(
      labels: [
        l.liveConnections,
        l.recentRequests,
        if (system.isWindows)
          Localizations.localeOf(context).languageCode == 'ru'
              ? 'Закрытые' : 'Closed',
      ],
      selectedIndex: feed.index,
      onSelected: (index) => setState(() {
        _feed = _ConnectionFeed.values[index];
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    final feed = _feed;
    _shown.add(feed);
    final pageActive = _pageActive;
    final titleTabs = _titleTabs(feed);
    return IndexedStack(
      index: feed.index,
      children: [
        for (final option in _ConnectionFeed.values)
          if (option == _ConnectionFeed.closed && !system.isWindows)
            const SizedBox.shrink()
          else if (!_shown.contains(option))
            const SizedBox.shrink()
          else
            PageActivityScope(
              isActive: pageActive && option == feed,
              child: TickerMode(
                enabled: option == feed,
                child: ExcludeFocus(
                  excluding: option != feed,
                  child: switch (option) {
                    _ConnectionFeed.recent => RequestsView(
                      titleWidget: titleTabs,
                    ),
                    _ConnectionFeed.live => ConnectionsView(
                      titleWidget: titleTabs,
                    ),
                    _ConnectionFeed.closed => EngineDiagnosticsView(
                      section: EngineDiagnosticsSection.closed,
                      titleWidget: titleTabs,
                    ),
                  },
                ),
              ),
            ),
      ],
    );
  }
}

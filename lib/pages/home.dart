import 'dart:async';

import 'package:fl_clash/common/common.dart';
import 'package:fl_clash/enum/enum.dart';
import 'package:fl_clash/manager/app_manager.dart';
import 'package:fl_clash/models/common.dart';
import 'package:fl_clash/providers/providers.dart';
import 'package:fl_clash/ui/icons/icons.dart';
import 'package:fl_clash/ui/pop_scope.dart' show maybePopAndWait;
import 'package:fl_clash/widgets/widgets.dart';
import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasViewSize = ref.watch(
      viewSizeProvider.select((size) => !size.isEmpty),
    );
    if (!hasViewSize) {
      return const SizedBox.shrink();
    }
    return HomeBackScopeContainer(
      isTV: system.isTV,
      child: AppSidebarContainer(
        child: _HomeShell(
          child: Consumer(
            builder: (_, ref, _) {
              final navigationItems = ref
                  .watch(currentNavigationItemsStateProvider)
                  .value;
              final isMobile = ref.watch(isMobileViewProvider);
              return _HomePageView(
                navigationItems: navigationItems,
                pageBuilder: (_, index) {
                  final navigationItem = navigationItems[index];
                  return _NavigationPage(
                    key: ValueKey(navigationItem.label),
                    item: navigationItem,
                    isMobile: isMobile,
                    view: navigationItem.builder(context),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }
}

class _HomeShell extends ConsumerWidget {
  const _HomeShell({required this.child});

  final Widget child;

  void _handleToPage(PageLabel pageLabel, WidgetRef ref) {
    ref.read(currentPageLabelProvider.notifier).toPage(pageLabel);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(navigationStateProvider);
    final isMobile = state.viewMode == ViewMode.mobile;
    final navigationItems = state.navigationItems;
    final floating = ref.watch(
      appSettingProvider.select((state) => state.floatingNavigationBar),
    );
    return Material(
      color: system.isWindows ? Colors.transparent : SurfaceLevel.page.colorOf(context.colorScheme),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: FocusTraversalGroup(
                    policy: PageTraversalPolicy(),
                    child: BottomInsetScope(
                      inset: isMobile && floating
                          ? NavigationDock.insetOf(context)
                          : 0,
                      child: _BodyPadding(isMobile: isMobile, child: child),
                    ),
                  ),
                ),
                PositionedDirectional(
                  start: 0,
                  end: 0,
                  bottom: 0,
                  child: AnimatedVisibility.bottomNavigation(
                    visible: isMobile && floating,
                    child: _NavigationPadding(
                      child: NavigationDock(
                        destinations: [
                          for (final item in navigationItems)
                            NavigationDockDestination(
                              glyph: item.glyph,
                              label: item.label.label,
                            ),
                        ],
                        selectedIndex: state.currentIndex,
                        onSelected: (index) {
                          _handleToPage(navigationItems[index].label, ref);
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          AnimatedVisibility.bottomNavigation(
            visible: isMobile && !floating,
            child: _NavigationPadding(
              child: NavigationBar(
                destinations: [
                  for (final (index, item) in navigationItems.indexed)
                    NavigationDestination(
                      icon: AnimatedGlyph(
                        glyph: item.glyph,
                        filled: index == state.currentIndex,
                      ),
                      label: item.label.label,
                    ),
                ],
                selectedIndex: state.currentIndex,
                onDestinationSelected: (index) {
                  _handleToPage(navigationItems[index].label, ref);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BodyPadding extends StatelessWidget {
  const _BodyPadding({required this.isMobile, required this.child});

  final bool isMobile;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      removeTop: false,
      removeBottom: isMobile,
      removeLeft: isMobile,
      removeRight: isMobile,
      context: context,
      child: child,
    );
  }
}

class _NavigationPadding extends StatelessWidget {
  const _NavigationPadding({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return MediaQuery.removePadding(
      removeTop: true,
      removeBottom: false,
      removeLeft: true,
      removeRight: true,
      context: context,
      child: child,
    );
  }
}

class _NavigationPage extends ConsumerStatefulWidget {
  const _NavigationPage({
    super.key,
    required this.item,
    required this.isMobile,
    required this.view,
  });

  final NavigationItem item;
  final bool isMobile;
  final Widget view;

  @override
  ConsumerState<_NavigationPage> createState() => _NavigationPageState();
}

class _NavigationPageState extends ConsumerState<_NavigationPage> {
  late final _routes = _OpenRoutes(onClosed: _dropNavigator);
  final _navigatorKey = GlobalKey<NavigatorState>();
  late bool _nested = !widget.isMobile;
  late final CurrentPageLabel _selection;
  late final Future<bool>? Function() _exit = _closeSectionRoutes;

  @override
  void initState() {
    super.initState();
    _selection = ref.read(currentPageLabelProvider.notifier);
    _selection.registerSectionExit(widget.item.label, _exit);
  }

  Future<bool>? _closeSectionRoutes() {
    final navigator = _navigatorKey.currentState;
    if (navigator == null || _routes.open == 0 || !navigator.canPop()) return null;
    return _returnToRoot(navigator);
  }

  Future<bool> _returnToRoot(NavigatorState navigator) async {
    // maybePop honours PopScope and LocalHistoryEntry. Never force-pop an
    // editor that vetoes navigation; keep the original section selected.
    while (mounted && navigator.mounted && _routes.open > 0) {
      final before = _routes.open;
      final top = _routes.top;
      final hadLocalHistory = top?.willHandlePopInternally ?? false;
      if (!await maybePopAndWait(navigator, top)) return false;
      if (!mounted || !navigator.mounted) return false;
      if (_routes.open < before) continue;
      if (hadLocalHistory && top?.willHandlePopInternally == false) continue;
      return false;
    }
    return mounted && _routes.open == 0;
  }

  @override
  void dispose() {
    _selection.unregisterSectionExit(widget.item.label, _exit);
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _NavigationPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The mobile layout has no navigator here; dropping one with a route open
    // would drop an editor and what it has not saved, so it waits for that.
    _nested = !widget.isMobile || _nested && _routes.open > 0;
  }

  void _dropNavigator() {
    if (mounted && widget.isMobile && _nested && _routes.open == 0) {
      setState(() => _nested = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final scopedView = PageFocusScope(child: widget.view);
    final keptView = KeepScope(
      key: ValueKey(item.label),
      child: _nested
          ? Navigator(
              key: _navigatorKey,
              observers: [_routes],
              pages: [MaterialPage(child: scopedView)],
              onDidRemovePage: (_) {},
            )
          : scopedView,
    );
    return Consumer(
      builder: (_, ref, child) {
        final isActive = ref.watch(
          shownPageLabelProvider.select((label) => label == item.label),
        );
        // A kept-alive page off screen still ticks its animations, and
        // each tick asks for a frame.
        return SectionActivityScope(
          isActive: isActive,
          child: PageActivityScope(
            isActive: isActive,
            child: TickerMode(
              enabled: isActive,
              child: ExcludeFocus(
                excluding: !isActive,
                child: _SectionScrollReset(child: KeyboardInsetHold(child: child!)),
              ),
            ),
          ),
        );
      },
      child: keptView,
    );
  }
}

/// Counts the routes open above a page's own, and reports the last one gone
/// once its exit transition has played.
class _OpenRoutes extends NavigatorObserver {
  _OpenRoutes({required this.onClosed});

  final VoidCallback onClosed;
  final _stack = <Route<dynamic>>[];
  int get open => _stack.isEmpty ? 0 : _stack.length - 1;
  Route<dynamic>? get top => _stack.isEmpty ? null : _stack.last;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute == null) _stack.clear();
    _stack.add(route);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (oldRoute == null) return;
    final index = _stack.indexOf(oldRoute);
    if (index < 0) return;
    if (newRoute == null) {
      _stack.removeAt(index);
    } else {
      _stack[index] = newRoute;
    }
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _closed(route);

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) =>
      _closed(route);

  void _closed(Route<dynamic> route) {
    if (!_stack.remove(route) || open > 0) {
      return;
    }
    if (route is TransitionRoute) {
      unawaited(route.completed.then((_) => onClosed()));
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => onClosed());
    }
  }
}

/// Reset only visual scroll positions; preserve elements, service state and
/// archives. A section's vertical scrollables include nested list controllers,
/// whereas the horizontal home pager is deliberately outside this subtree.
class _SectionScrollReset extends StatefulWidget {
  const _SectionScrollReset({required this.child});
  final Widget child;

  @override
  State<_SectionScrollReset> createState() => _SectionScrollResetState();
}

class _SectionScrollResetState extends State<_SectionScrollReset> {
  bool? _active;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final active = SectionActivityScope.isActiveOf(context);
    final left = _active == true && !active;
    _active = active;
    if (!left) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final positions = <ScrollPosition>{};
      void collect(Element element) {
        if (element is StatefulElement && element.state is ScrollableState) {
          final scrollable = element.state as ScrollableState;
          if (scrollable.mounted) {
            final position = scrollable.position;
            if (position.axis == Axis.vertical && position.hasContentDimensions) {
              positions.add(position);
            }
          }
        }
        element.visitChildren(collect);
      }
      context.visitChildElements(collect);
      for (final position in positions) {
        // Reverse history lists start at their newest end.
        final target = position.axisDirection == AxisDirection.up
            ? position.maxScrollExtent : position.minScrollExtent;
        if (target.isFinite && position.pixels != target) position.jumpTo(target);
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

class _HomePageView extends ConsumerStatefulWidget {
  final IndexedWidgetBuilder pageBuilder;
  final List<NavigationItem> navigationItems;

  const _HomePageView({
    required this.pageBuilder,
    required this.navigationItems,
  });

  @override
  ConsumerState createState() => _HomePageViewState();
}

class _HomePageViewState extends ConsumerState<_HomePageView> {
  late PageController _pageController;

  List<int>? _order;
  int _slide = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(
      initialPage: _pageIndex < 0 ? 0 : _pageIndex,
      keepPage: false,
    );
    ref.listenManual(currentPageLabelProvider, (prev, next) {
      if (prev != next) {
        _toPage(next);
      }
    });
  }

  @override
  void didUpdateWidget(covariant _HomePageView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!listEquals(
      _labelsOf(oldWidget.navigationItems),
      _labelsOf(widget.navigationItems),
    )) {
      _order = null;
      _updatePageController();
    }
  }

  static List<PageLabel> _labelsOf(List<NavigationItem> items) => [
    for (final item in items) item.label,
  ];

  int get _pageIndex => _indexOf(ref.read(currentPageLabelProvider));

  int _indexOf(PageLabel pageLabel) {
    final shown = shownPageLabelOf(pageLabel, widget.navigationItems);
    return widget.navigationItems.indexWhere((item) => item.label == shown);
  }

  Future<void> _toPage(
    PageLabel pageLabel, [
    bool ignoreAnimateTo = false,
  ]) async {
    if (!mounted) {
      return;
    }
    final index = _indexOf(pageLabel);
    if (index == -1) {
      return;
    }
    final tabAnimation = ref.read(appSettingProvider).tabAnimation;
    final isMobile = ref.read(isMobileViewProvider);
    final slide = ++_slide;
    if (!_pageController.hasClients) {
      // The view may be detached while the window is being restored.
      // Retry only the latest selection once the PageView is attached.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && slide == _slide && _pageController.hasClients) {
          _toPage(ref.read(currentPageLabelProvider), true);
        }
      });
      WidgetsBinding.instance.ensureVisualUpdate();
      return;
    }
    final position = _pageController.position;
    if (!isMobile || ignoreAnimateTo ||
        !position.hasViewportDimension || position.viewportDimension <= 0 ||
        !position.hasContentDimensions) {
      if (_order != null) setState(() => _order = null);
      _pageController.jumpToPage(index);
      return;
    }
    final page = _pageController.page?.round() ?? index;
    final order = _order;
    final current = order != null && page >= 0 && page < order.length
        ? order[page]
        : page;
    if (order != null) {
      setState(() => _order = null);
      if (current >= 0 && current < widget.navigationItems.length) {
        _pageController.jumpToPage(current);
      }
    }
    if (current < 0 || current >= widget.navigationItems.length) {
      _pageController.jumpToPage(index);
      return;
    }
    // As TabBarView does, so no page between is built and painted on the way.
    if ((index - current).abs() > 1) {
      final adjacent = index > current ? index - 1 : index + 1;
      setState(() {
        _order = List.generate(widget.navigationItems.length, (item) => item)
          ..[adjacent] = current
          ..[current] = adjacent;
      });
      _pageController.jumpToPage(adjacent);
    }
    final fade = tabAnimation == TabAnimation.fade;
    await _pageController.animateToPage(
      index,
      duration: fade ? fadeTabDuration : kTabScrollDuration,
      curve: fade ? fadeTabCurve : Curves.easeOut,
    );
    if (mounted && slide == _slide && _order != null) {
      setState(() => _order = null);
    }
  }

  void _updatePageController() {
    final pageLabel = ref.read(currentPageLabelProvider);
    _toPage(pageLabel, true);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemCount = ref.watch(
      currentNavigationItemsStateProvider.select((state) => state.value.length),
    );
    final fade = ref.watch(
      appSettingProvider.select(
        (state) => state.tabAnimation == TabAnimation.fade,
      ),
    );
    return PageView.builder(
      controller: _pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      findChildIndexCallback: (key) {
        if (key is! ValueKey<PageLabel>) {
          return null;
        }
        final index = widget.navigationItems.indexWhere(
          (item) => item.label == key.value,
        );
        if (index == -1) {
          return null;
        }
        return _order?.indexOf(index) ?? index;
      },
      itemBuilder: (context, index) {
        final page = widget.pageBuilder(context, _order?[index] ?? index);
        return _FadeTabPage(
          key: page.key,
          controller: _pageController,
          position: index,
          enabled: fade,
          child: page,
        );
      },
    );
  }
}

/// Cancels the page view's slide so a tab switch cross-fades in place, and
/// wraps every page even when off so switching the setting keeps their state.
class _FadeTabPage extends StatelessWidget {
  const _FadeTabPage({
    super.key,
    required this.controller,
    required this.position,
    required this.enabled,
    required this.child,
  });

  final PageController controller;
  final int position;
  final bool enabled;
  final Widget child;

  double get _delta {
    if (!controller.hasClients ||
        !controller.position.hasViewportDimension ||
        controller.position.viewportDimension <= 0 ||
        !controller.position.hasContentDimensions) {
      return 0;
    }
    final page = controller.page ?? position.toDouble();
    return (position - page).clamp(-1.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (_, child) {
        final offset = _delta;
        final delta = enabled ? offset : 0.0;
        return FractionalTranslation(
          translation: Offset(-delta, 0),
          child: Opacity(opacity: 1 - delta.abs(), child: child),
        );
      },
      child: child,
    );
  }
}

class HomeBackScopeContainer extends ConsumerWidget {
  final Widget child;
  final bool isTV;

  const HomeBackScopeContainer({
    super.key,
    required this.child,
    required this.isTV,
  });

  @override
  Widget build(BuildContext context, ref) {
    return CommonPopScope(
      onPop: (context) async {
        final pageLabel = ref.read(shownPageLabelProvider);
        final realContext =
            GlobalObjectKey(pageLabel).currentContext ?? context;
        final canPop = Navigator.canPop(realContext);
        if (canPop) {
          // The route's own pop scope may hold an unsaved edit.
          await Navigator.of(realContext).maybePop();
        } else if (isTV && pageLabel != PageLabel.dashboard) {
          ref
              .read(currentPageLabelProvider.notifier)
              .toPage(PageLabel.dashboard);
        } else {
          // Back on a TV leaves the VPN running; explicit Exit still shuts it down.
          await ref.read(systemActionProvider.notifier).handleClose(!isTV);
        }
        return false;
      },
      child: child,
    );
  }
}

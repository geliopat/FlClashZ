import 'dart:async';

import 'package:flutter/widgets.dart';

import 'inherited.dart';

/// Navigator.maybePop returns after notifying a vetoing PopScope, not after
/// its asynchronous confirmation. Share the pending answer with section
/// navigation without bypassing any ordinary Flutter pop guards.
final _pendingPopAnswers = Expando<Future<bool>>('pending pop confirmation');

Future<bool> maybePopAndWait(NavigatorState navigator, Route<dynamic>? route) async {
  if (route != null) {
    final pending = _pendingPopAnswers[route];
    if (pending != null) return pending;
  }
  final handled = await navigator.maybePop();
  if (!handled || route == null) return handled;
  final pending = _pendingPopAnswers[route];
  return pending == null ? handled : await pending;
}

class CommonPopScope extends StatelessWidget {
  final Widget child;

  /// Any handler vetoes the pop up front, which also turns off the drag back,
  /// so pass one only while there is something to intercept.
  final FutureOr<bool> Function(BuildContext context)? onPop;
  final FutureOr<void> Function()? onPopSuccess;

  const CommonPopScope({
    super.key,
    required this.child,
    this.onPop,
    this.onPopSuccess,
  });

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context);
    final hasBackLayer = route?.willHandlePopInternally == true;
    return PopScope(
      canPop: onPop == null || hasBackLayer,
      onPopInvokedWithResult: onPop == null
          ? null
          : (didPop, _) async {
              if (didPop) {
                return;
              }
              // BackLayerScope adds its entry a frame after this builds, which
              // rebuilds nothing here on a route with another below it.
              if (route?.willHandlePopInternally == true) {
                Navigator.of(context).pop();
                return;
              }
              if (route == null || _pendingPopAnswers[route] != null) return;
              final answer = Completer<bool>();
              _pendingPopAnswers[route] = answer.future;
              var popped = false;
              try {
                final res = await onPop!(context);
                // A late confirmation must never close another route that
                // was opened while the editor was awaiting its answer.
                if (!res || !context.mounted || !route.isCurrent ||
                    route.navigator?.mounted != true) return;
                route.navigator!.pop();
                popped = !route.isCurrent;
                if (popped && onPopSuccess != null) {
                  await onPopSuccess!();
                }
              } catch (error) {
                debugPrint('Page close confirmation failed: $error');
              } finally {
                answer.complete(popped);
                _pendingPopAnswers[route] = null;
              }
            },
      child: child,
    );
  }
}

class BackLayerScope extends StatefulWidget {
  final Widget child;
  final VoidCallback onBack;
  @visibleForTesting
  final void Function(void Function(Duration) callback)?
  schedulePostFrameCallback;

  const BackLayerScope({
    super.key,
    required this.onBack,
    required this.child,
    @visibleForTesting this.schedulePostFrameCallback,
  });

  @override
  State<BackLayerScope> createState() => _BackLayerScopeState();
}

class _BackLayerScopeState extends State<BackLayerScope> {
  ModalRoute<dynamic>? _route;
  LocalHistoryEntry? _entry;
  bool _isDetaching = false;
  bool _isPageActive = true;
  int _syncRevision = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    final isPageActive = PageActivityScope.isActiveOf(context);
    if (identical(_route, route) && _isPageActive == isPageActive) {
      return;
    }
    _detach();
    _route = route;
    _isPageActive = isPageActive;
    final revision = ++_syncRevision;
    final schedulePostFrameCallback =
        widget.schedulePostFrameCallback ??
        WidgetsBinding.instance.addPostFrameCallback;
    schedulePostFrameCallback((_) {
      if (!mounted || revision != _syncRevision) {
        return;
      }
      if (!_isPageActive) {
        widget.onBack();
        return;
      }
      if (route == null) {
        return;
      }
      final entry = LocalHistoryEntry(
        impliesAppBarDismissal: false,
        onRemove: _handleRemove,
      );
      _entry = entry;
      route.addLocalHistoryEntry(entry);
    });
  }

  void _handleRemove() {
    _entry = null;
    if (!_isDetaching && mounted) {
      widget.onBack();
    }
  }

  void _detach() {
    final entry = _entry;
    if (entry == null) {
      return;
    }
    _entry = null;
    _isDetaching = true;
    entry.remove();
    _isDetaching = false;
  }

  @override
  void dispose() {
    _syncRevision++;
    _detach();
    _route = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}

import 'package:flutter/material.dart';
import 'router.dart';
import 'route_guard.dart';

class _RouteEntry {
  final String path;
  final WidgetBuilder builder;

  const _RouteEntry(this.path, this.builder);
}

class CubeRouterDelegate extends RouterDelegate<String>
    with ChangeNotifier, PopNavigatorRouterDelegateMixin<String> {
  @override
  final GlobalKey<NavigatorState> navigatorKey;

  final CubeRouter router;
  final List<RouteGuard> guards;

  final List<_RouteEntry> _stack = [];
  int _navId = 0;

  CubeRouterDelegate(this.router, {this.guards = const []})
    : navigatorKey = GlobalKey<NavigatorState>() {
    // Push the initial route
    _stack.add(_RouteEntry('/', _resolveBuilder('/')));
  }

  String get currentPath => _stack.isEmpty ? '/' : _stack.last.path;

  @override
  String get currentConfiguration => currentPath;

  WidgetBuilder _resolveBuilder(String path) {
    final route =
        router.routes.where((r) => r.path == path).firstOrNull ??
        router.routes.firstOrNull;
    return route?.builder ?? (context) => const SizedBox.shrink();
  }

  Future<void> go(String path) async {
    final id = ++_navId;
    final allowed = await _runGuards(path, id);
    if (id != _navId) return; // Stale navigation
    if (!allowed) return;
    _stack.add(_RouteEntry(path, _resolveBuilder(path)));
    notifyListeners();
  }

  Future<void> replace(String path) async {
    final id = ++_navId;
    final allowed = await _runGuards(path, id);
    if (id != _navId) return; // Stale navigation
    if (!allowed) return;
    if (_stack.isNotEmpty) _stack.removeLast();
    _stack.add(_RouteEntry(path, _resolveBuilder(path)));
    notifyListeners();
  }

  void popUntilRoot() {
    if (_stack.length > 1) {
      _stack.removeRange(1, _stack.length);
      notifyListeners();
    }
  }

  Future<bool> _runGuards(String path, int expectedNavId) async {
    for (final guard in guards) {
      if (!await guard.canActivate(path)) {
        if (expectedNavId != _navId) return false; // Abort redirect if stale
        final redirectPath = guard.redirectPath ?? '/';
        _stack.add(_RouteEntry(redirectPath, _resolveBuilder(redirectPath)));
        notifyListeners();
        return false;
      }
    }
    return true;
  }

  @override
  Future<void> setInitialRoutePath(String configuration) async {
    await setNewRoutePath(configuration);
  }

  @override
  Future<void> setNewRoutePath(String configuration) async {
    await go(configuration);
  }

  @override
  Widget build(BuildContext context) {
    return Navigator(
      key: navigatorKey,
      pages: _stack
          .map(
            (entry) => MaterialPage(
              key: ValueKey(entry.path),
              child: entry.builder(context),
            ),
          )
          .toList(),
      onDidRemovePage: (page) {
        if (_stack.length > 1) {
          _stack.removeLast();
          notifyListeners();
        }
      },
    );
  }
}

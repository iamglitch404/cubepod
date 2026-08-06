import 'package:flutter/widgets.dart';
import 'package:cubepod_router/cubepod_router.dart';
import 'dart:async';

class PathDelayGuard extends RouteGuard {
  @override
  String? get redirectPath => null;

  @override
  FutureOr<bool> canActivate(String path) async {
    if (path == '/slow') {
      await Future.delayed(const Duration(milliseconds: 100));
    } else if (path == '/fast') {
      await Future.delayed(const Duration(milliseconds: 20));
    }
    return true;
  }
}

void main() async {
  final router = CubeRouter([
    CubeRoute(path: '/', builder: (_) => const SizedBox()),
    CubeRoute(path: '/slow', builder: (_) => const SizedBox()),
    CubeRoute(path: '/fast', builder: (_) => const SizedBox()),
  ]);

  final delegate = CubeRouterDelegate(router, guards: [PathDelayGuard()]);

  // Request slow route
  final slowFuture = delegate.go('/slow');
  // Request fast route immediately
  final fastFuture = delegate.go('/fast');

  await Future.wait([slowFuture, fastFuture]);

  debugPrint("Current path: ${delegate.currentPath}");
  if (delegate.currentPath != '/fast') {
    throw Exception(
      "Bug reproduced! Expected /fast, got ${delegate.currentPath}",
    );
  }
}

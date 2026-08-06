import "dart:async";
import "package:flutter/widgets.dart";
import 'package:cubepod_router/cubepod_router.dart';
import 'package:flutter_test/flutter_test.dart';

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

void main() {
  group('CubeRouter', () {
    test('can be instantiated with routes', () {
      final router = CubeRouter([]);
      expect(router, isNotNull);
    });
  });

  group('CubeRouterDelegate', () {
    test(
      'go() aborts slow navigation if a newer fast navigation occurs',
      () async {
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

        expect(
          delegate.currentPath,
          '/fast',
          reason: 'The last requested route should be active',
        );
      },
    );
  });
}

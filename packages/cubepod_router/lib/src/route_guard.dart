import 'dart:async';

/// Intercepts and redirects navigation based on asynchronous conditions (e.g. auth).
abstract class RouteGuard {
  String? get redirectPath;
  FutureOr<bool> canActivate(String path);
}

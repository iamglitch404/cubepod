import 'dart:async';

abstract class RouteGuard {
  String? get redirectPath;
  FutureOr<bool> canActivate(String path);
}

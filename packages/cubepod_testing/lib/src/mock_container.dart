import 'package:cubepod_core/cubepod_core.dart';

class MockContainer {
  static void overrideWith<T extends Object>(T instance, {String? name}) {
    CubePod.register<T>((c) => instance, scope: Scope.singleton, name: name);
  }

  static void reset() {
    CubePod.reset();
  }
}

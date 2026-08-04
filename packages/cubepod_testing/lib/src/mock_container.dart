import 'package:cubepod_core/cubepod_core.dart';

class MockContainer {
  static void overrideWith<T extends Object>(T instance) {
    CubePod.register<T>(() => instance, scope: Scope.singleton);
  }

  static void reset() {
    CubePod.reset();
  }
}

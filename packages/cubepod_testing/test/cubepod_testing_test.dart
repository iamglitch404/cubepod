import 'package:cubepod_core/cubepod_core.dart';
import 'package:cubepod_state/cubepod_state.dart';
import 'package:cubepod_testing/cubepod_testing.dart';
import 'package:flutter_test/flutter_test.dart';

class _RealService {
  String greet() => 'Hello from Real';
}

void main() {
  setUp(() => CubePod.reset());

  group('MockContainer', () {
    test('reset() clears all registrations', () {
      CubePod.register((c) => _RealService(), scope: Scope.singleton);
      MockContainer.reset();
      expect(() => CubePod.get<_RealService>(), throwsStateError);
    });

    test('after reset, new registrations work normally', () {
      MockContainer.reset();
      CubePod.register((c) => _RealService(), scope: Scope.singleton);
      final svc = CubePod.get<_RealService>();
      expect(svc.greet(), 'Hello from Real');
    });

    test('overrideWith<T>() registers instance as singleton', () {
      final fake = _RealService();
      MockContainer.overrideWith<_RealService>(fake);
      final resolved = CubePod.get<_RealService>();
      expect(identical(resolved, fake), isTrue);
    });

    test('overrideWith<T>() returns same instance on repeated resolution', () {
      final fake = _RealService();
      MockContainer.overrideWith<_RealService>(fake);
      final a = CubePod.get<_RealService>();
      final b = CubePod.get<_RealService>();
      expect(identical(a, b), isTrue);
    });

    test('overrideWith<T>() supports named dependencies', () {
      final fake = _RealService();
      MockContainer.overrideWith<_RealService>(fake, name: 'special');

      // Default should fail if not overridden
      expect(() => CubePod.get<_RealService>(), throwsStateError);

      // Named should resolve
      final resolved = CubePod.get<_RealService>(name: 'special');
      expect(identical(resolved, fake), isTrue);
    });
  });

  group('TestObserver', () {
    test('records initial value', () {
      final signal = StateSignal<int>(10);
      final observer = TestObserver(signal);
      expect(observer.history, [10]);
      observer.dispose();
    });

    test('records each subsequent value', () {
      final signal = StateSignal<int>(0);
      final observer = TestObserver(signal);
      signal.value = 1;
      signal.value = 2;
      signal.value = 3;
      expect(observer.history, [0, 1, 2, 3]);
      observer.dispose();
    });

    test('stops recording after dispose', () {
      final signal = StateSignal<int>(0);
      final observer = TestObserver(signal);
      signal.value = 1;
      observer.dispose();
      signal.value = 2;
      expect(observer.history, [0, 1]); // 2 should NOT be recorded
    });

    test('does not record duplicate values (signal equality check)', () {
      final signal = StateSignal<int>(5);
      final observer = TestObserver(signal);
      signal.value = 5; // Same value — should not notify
      expect(observer.history, [5]); // Only initial
      observer.dispose();
    });

    test('TestObserver assertValues works', () {
      final sig = StateSignal(1);
      final obs = TestObserver(sig);
      sig.value = 2;
      obs.assertValues([1, 2]);
      obs.assertLast(2);
      expect(() => obs.assertValues([1]), throwsStateError);
      expect(() => obs.assertLast(3), throwsStateError);
    });
  });
}

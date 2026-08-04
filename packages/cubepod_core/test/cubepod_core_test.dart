import 'package:cubepod_core/cubepod_core.dart';
import 'package:test/test.dart';

class _FakeService {
  int value = 0;
}

class _DisposableService implements Disposable {
  bool wasDisposed = false;
  @override
  void dispose() => wasDisposed = true;
}

void main() {
  setUp(() => CubePod.reset());

  group('CubePod DI', () {
    test('registers and resolves a singleton', () {
      CubePod.register(() => _FakeService(), scope: Scope.singleton);
      final a = CubePod.get<_FakeService>();
      final b = CubePod.get<_FakeService>();
      expect(identical(a, b), isTrue);
    });

    test('factory scope creates a new instance each time', () {
      CubePod.register(() => _FakeService(), scope: Scope.factory);
      final a = CubePod.get<_FakeService>();
      final b = CubePod.get<_FakeService>();
      expect(identical(a, b), isFalse);
    });

    test('throws StateError for unregistered type', () {
      expect(() => CubePod.get<_FakeService>(), throwsStateError);
    });

    test('named registrations work independently', () {
      CubePod.register<_FakeService>(() => _FakeService()..value = 1,
          scope: Scope.singleton, name: 'one');
      CubePod.register<_FakeService>(() => _FakeService()..value = 2,
          scope: Scope.singleton, name: 'two');

      final one = CubePod.get<_FakeService>(name: 'one');
      final two = CubePod.get<_FakeService>(name: 'two');
      expect(one.value, 1);
      expect(two.value, 2);
    });

    test('unregister disposes Disposable instances', () {
      final svc = _DisposableService();
      CubePod.register(() => svc, scope: Scope.singleton);
      CubePod.get<_DisposableService>();
      CubePod.unregister<_DisposableService>();
      expect(svc.wasDisposed, isTrue);
    });

    test('reset clears all registrations and disposes singletons', () {
      final svc = _DisposableService();
      CubePod.register(() => svc, scope: Scope.singleton);
      CubePod.get<_DisposableService>(); // instantiate it
      CubePod.reset();
      expect(svc.wasDisposed, isTrue);
      expect(() => CubePod.get<_DisposableService>(), throwsStateError);
    });

    test('scoped instances are shared within scope and disposed on popScope',
        () {
      CubePod.register(() => _DisposableService(), scope: Scope.scoped);
      CubePod.pushScope();
      final a = CubePod.get<_DisposableService>();
      final b = CubePod.get<_DisposableService>();
      expect(identical(a, b), isTrue); // same within scope
      CubePod.popScope();
      expect(a.wasDisposed, isTrue);
    });
  });
}

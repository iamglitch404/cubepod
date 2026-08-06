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
      CubePod.register((c) => _FakeService(), scope: Scope.singleton);
      final a = CubePod.get<_FakeService>();
      final b = CubePod.get<_FakeService>();
      expect(identical(a, b), isTrue);
    });

    test('factory scope creates a new instance each time', () {
      CubePod.register((c) => _FakeService(), scope: Scope.factory);
      final a = CubePod.get<_FakeService>();
      final b = CubePod.get<_FakeService>();
      expect(identical(a, b), isFalse);
    });

    test('throws StateError for unregistered type', () {
      expect(() => CubePod.get<_FakeService>(), throwsStateError);
    });

    test('named registrations work independently', () {
      CubePod.register<_FakeService>((c) => _FakeService()..value = 1,
          scope: Scope.singleton, name: 'one');
      CubePod.register<_FakeService>((c) => _FakeService()..value = 2,
          scope: Scope.singleton, name: 'two');

      final one = CubePod.get<_FakeService>(name: 'one');
      final two = CubePod.get<_FakeService>(name: 'two');
      expect(one.value, 1);
      expect(two.value, 2);
    });

    test('unregister disposes Disposable instances', () {
      final svc = _DisposableService();
      CubePod.register((c) => svc, scope: Scope.singleton);
      CubePod.get<_DisposableService>();
      CubePod.unregister<_DisposableService>();
      expect(svc.wasDisposed, isTrue);
    });

    test('reset clears all registrations and disposes singletons', () {
      final svc = _DisposableService();
      CubePod.register((c) => svc, scope: Scope.singleton);
      CubePod.get<_DisposableService>(); // instantiate it
      CubePod.reset();
      expect(svc.wasDisposed, isTrue);
      expect(() => CubePod.get<_DisposableService>(), throwsStateError);
    });

    test('scoped instances are shared within scope and disposed', () {
      CubePod.register((c) => _DisposableService(), scope: Scope.scoped);
      final scope1 = CubePod.createScope();
      final a = scope1.get<_DisposableService>();
      final b = scope1.get<_DisposableService>();
      expect(identical(a, b), isTrue); // same within scope

      final scope2 = CubePod.createScope();
      final c = scope2.get<_DisposableService>();
      expect(identical(a, c), isFalse); // different scope

      scope1.dispose();
      expect(a.wasDisposed, isTrue);
      expect(c.wasDisposed, isFalse);
    });

    test('singletons delegate to parent container until root', () {
      CubePod.register((c) => _FakeService(), scope: Scope.singleton);
      final scope = CubePod.createScope();
      final a = scope.get<_FakeService>();
      final b = CubePod.get<_FakeService>();
      expect(identical(a, b), isTrue);
    });
    test('nested scopes correctly override parent dependencies', () {
      CubePod.register((c) => 'root', scope: Scope.factory, name: 'dep');
      CubePod.register((c) => 'Service: ${c.get<String>(name: 'dep')}',
          scope: Scope.factory, name: 'service');

      final child = CubePod.createScope();
      child.register((c) => 'child', scope: Scope.factory, name: 'dep');

      expect(CubePod.get<String>(name: 'service'), 'Service: root');
      expect(child.get<String>(name: 'service'), 'Service: child');
    });

    test('factories no longer accidentally resolve through the root container',
        () {
      CubePod.register((c) => 'root', scope: Scope.scoped, name: 'dep');
      CubePod.register((c) => 'Service: ${c.get<String>(name: 'dep')}',
          scope: Scope.scoped, name: 'service');

      final child = CubePod.createScope();
      child.register((c) => 'child', scope: Scope.scoped, name: 'dep');

      // The service in child should evaluate using the child container and its overridden dep
      expect(child.get<String>(name: 'service'), 'Service: child');

      // The root service should evaluate using the root container
      expect(CubePod.get<String>(name: 'service'), 'Service: root');
    });

    test(
        'throws ArgumentError when Scope.singleton is registered on child container',
        () {
      final child = CubePod.createScope();
      try {
        child.register((c) => _FakeService(), scope: Scope.singleton);
        fail('Expected ArgumentError');
      } on ArgumentError catch (e) {
        expect(
            e.message,
            contains(
                'Scope.singleton can only be registered on the root container'));
      }
    });
  });

  group('CircularDependencyError', () {
    test('throws CircularDependencyError for direct circular dependency', () {
      // A depends on A — detected immediately
      CubePod.register<_FakeService>((c) {
        c.get<_FakeService>(); // attempt to resolve self mid-construction
        return _FakeService();
      }, scope: Scope.factory);

      expect(
        () => CubePod.get<_FakeService>(),
        throwsA(isA<CircularDependencyError>()),
      );
    });

    test('CircularDependencyError message contains the type name', () {
      CubePod.register<_FakeService>((c) {
        c.get<_FakeService>();
        return _FakeService();
      }, scope: Scope.factory);

      try {
        CubePod.get<_FakeService>();
        fail('Expected CircularDependencyError');
      } on CircularDependencyError catch (e) {
        expect(e.toString(), contains('_FakeService'));
        expect(e.toString(), contains('Circular dependency'));
      }
    });
  });

  group('ResourcePool', () {
    test('acquire returns a resource', () {
      final pool = ResourcePool<_DisposableService>(
        () => _DisposableService(),
        maxSize: 3,
      );
      final r = pool.acquire();
      expect(r, isNotNull);
      pool.dispose();
    });

    test('acquire reuses released resources', () {
      final pool = ResourcePool<_DisposableService>(
        () => _DisposableService(),
        maxSize: 3,
      );
      final a = pool.acquire();
      pool.release(a);
      final b = pool.acquire();
      expect(identical(a, b), isTrue); // same instance returned
      pool.dispose();
    });

    test('acquire throws StateError when pool is exhausted', () {
      final pool = ResourcePool<_DisposableService>(
        () => _DisposableService(),
        maxSize: 2,
      );
      pool.acquire();
      pool.acquire();
      expect(() => pool.acquire(), throwsStateError);
      pool.dispose();
    });

    test('dispose calls dispose() on all resources', () {
      final pool = ResourcePool<_DisposableService>(
        () => _DisposableService(),
        maxSize: 3,
      );
      final a = pool.acquire();
      final b = pool.acquire();
      pool.release(b); // b is back in available list

      pool.dispose();

      expect(a.wasDisposed, isTrue);
      expect(b.wasDisposed, isTrue);
    });
  });
}

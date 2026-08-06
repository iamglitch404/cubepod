import 'package:cubepod_core/cubepod_core.dart';

void main() async {
  print('--- Stress & Memory Tests ---');
  await _runMemoryLeakTest();
}

class _DummyService {
  final int id;
  _DummyService(this.id);
}

Future<void> _runMemoryLeakTest() async {
  print('\n[Memory Leak Test]');
  CubePod.reset();
  CubePod.register((c) => _DummyService(0), scope: Scope.factory);

  WeakReference<_DummyService>? weakRef;

  // Create a tight closure scope to ensure strong references are dropped
  void createAndDispose() {
    final scope = CubePod.createScope();
    scope.register((c) => _DummyService(1), scope: Scope.scoped);
    final instance = scope.get<_DummyService>();
    weakRef = WeakReference(instance);

    // Dispose the container, it should drop the reference to the scoped instance
    scope.dispose();
  }

  createAndDispose();

  // Force garbage collection by allocating a lot of objects
  List<dynamic> junk = [];
  for (int i = 0; i < 5000000; i++) {
    junk.add(List.filled(10, 'junk'));
    if (i % 100000 == 0) junk.clear(); // thrash memory
  }

  // Yield to allow GC
  await Future.delayed(const Duration(milliseconds: 100));

  if (weakRef?.target == null) {
    print(
        'PASS: Scoped instances are successfully garbage collected after container disposal.');
  } else {
    print(
        'FAIL: Scoped instances are leaking memory! The WeakReference is still alive.');
  }
}

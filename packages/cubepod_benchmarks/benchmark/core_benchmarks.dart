import 'package:cubepod_core/cubepod_core.dart';

void main() {
  print('--- Core DI Benchmarks ---');
  _runRegistrationBenchmarks();
  _runResolutionBenchmarks();
  _runNestedScopeBenchmarks();
  _runLargeGraphBenchmarks();
}

class _DummyService {
  final int id;
  _DummyService(this.id);
}

void _runRegistrationBenchmarks() {
  print('\n[Registration Latency]');
  final stopwatch = Stopwatch();
  const int iterations = 100000;

  CubePod.reset();
  stopwatch.start();
  for (int i = 0; i < iterations; i++) {
    CubePod.register((c) => _DummyService(i),
        scope: Scope.factory, name: 'dummy_$i');
  }
  stopwatch.stop();

  final timePerOp = stopwatch.elapsedMicroseconds / iterations;
  final opsPerSec = 1000000 / timePerOp;
  print(
      'Factory Registration: ${timePerOp.toStringAsFixed(2)} µs/op (${opsPerSec.toStringAsFixed(0)} ops/sec)');
}

void _runResolutionBenchmarks() {
  print('\n[Resolution Latency]');
  CubePod.reset();
  CubePod.register((c) => _DummyService(0), scope: Scope.singleton);
  CubePod.register((c) => _DummyService(1),
      scope: Scope.factory, name: 'factory');
  CubePod.register((c) => _DummyService(2),
      scope: Scope.scoped, name: 'scoped');

  final scope = CubePod.createScope();

  // Warmup
  CubePod.get<_DummyService>();
  CubePod.get<_DummyService>(name: 'factory');
  scope.get<_DummyService>(name: 'scoped');

  const int iterations = 1000000;

  // Singleton
  var stopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    CubePod.get<_DummyService>();
  }
  stopwatch.stop();
  var timePerOp = stopwatch.elapsedMicroseconds / iterations;
  var opsPerSec = 1000000 / timePerOp;
  print(
      'Singleton Read: ${timePerOp.toStringAsFixed(3)} µs/op (${opsPerSec.toStringAsFixed(0)} ops/sec)');

  // Scoped
  stopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    scope.get<_DummyService>(name: 'scoped');
  }
  stopwatch.stop();
  timePerOp = stopwatch.elapsedMicroseconds / iterations;
  opsPerSec = 1000000 / timePerOp;
  print(
      'Scoped Read: ${timePerOp.toStringAsFixed(3)} µs/op (${opsPerSec.toStringAsFixed(0)} ops/sec)');

  // Factory
  stopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    CubePod.get<_DummyService>(name: 'factory');
  }
  stopwatch.stop();
  timePerOp = stopwatch.elapsedMicroseconds / iterations;
  opsPerSec = 1000000 / timePerOp;
  print(
      'Factory Creation: ${timePerOp.toStringAsFixed(3)} µs/op (${opsPerSec.toStringAsFixed(0)} ops/sec)');
}

void _runNestedScopeBenchmarks() {
  print('\n[Nested Scope Lookup]');
  CubePod.reset();
  CubePod.register((c) => _DummyService(0), scope: Scope.singleton);

  const depths = [1, 10, 50];
  const int iterations = 1000000;

  for (final depth in depths) {
    var currentScope = CubePod.createScope();
    for (int i = 0; i < depth - 1; i++) {
      currentScope = CubePod.createScope(parent: currentScope);
    }

    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < iterations; i++) {
      currentScope.get<_DummyService>();
    }
    stopwatch.stop();
    final timePerOp = stopwatch.elapsedMicroseconds / iterations;
    final opsPerSec = 1000000 / timePerOp;
    print(
        'Depth $depth Read: ${timePerOp.toStringAsFixed(3)} µs/op (${opsPerSec.toStringAsFixed(0)} ops/sec)');
  }
}

void _runLargeGraphBenchmarks() {
  print('\n[Large Graph Resolution]');
  CubePod.reset();

  const size = 1000;
  for (int i = 0; i < size; i++) {
    if (i == 0) {
      CubePod.register((c) => _DummyService(0),
          name: 'node_0', scope: Scope.singleton);
    } else {
      CubePod.register((c) {
        c.get<_DummyService>(name: 'node_${i - 1}');
        return _DummyService(i);
      }, name: 'node_$i', scope: Scope.singleton);
    }
  }

  // Measure cold boot of a 1000-deep dependency chain
  final stopwatch = Stopwatch()..start();
  CubePod.get<_DummyService>(name: 'node_${size - 1}');
  stopwatch.stop();

  print(
      'Cold Boot 1000-node graph: ${stopwatch.elapsedMicroseconds / 1000.0} ms');
}

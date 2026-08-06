import 'dart:collection';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:cubepod_core/cubepod_core.dart';
import 'package:cubepod_state/cubepod_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
// BENCHMARK INFRASTRUCTURE
// ─────────────────────────────────────────────────────────────────────────────

class BenchmarkResult {
  final String name;
  final int opsPerSecond;
  final double avgMicros;
  final int totalMs;

  BenchmarkResult(this.name, this.opsPerSecond, this.avgMicros, this.totalMs);

  @override
  String toString() {
    final opsStr = opsPerSecond > 1000000
        ? '${(opsPerSecond / 1000000).toStringAsFixed(2)}M ops/sec'
        : '${(opsPerSecond / 1000).toStringAsFixed(1)}K ops/sec';
    return '[$name] $opsStr  |  ${avgMicros.toStringAsFixed(3)} µs/op  |  ${totalMs}ms total';
  }
}

/// Runs [fn] [iterations] times and returns performance metrics.
///
/// [fn] should return a value that is accumulated into [_sink] to prevent the
/// Dart AOT/JIT compiler from treating the loop body as dead code and
/// eliminating it entirely (which would produce false 0ms results).
BenchmarkResult benchmark(String name, dynamic Function() fn,
    {int iterations = 1000000}) {
  final watch = Stopwatch()..start();

  // Accumulate results into a black-hole sink to defeat dead-code elimination.
  // The int accumulator is the cheapest possible — no allocation, no boxing.
  var sink = 0;
  for (var i = 0; i < iterations; i++) {
    final res = fn();
    if (res is int) sink ^= res; // XOR is cheaper than addition, same effect
  }
  watch.stop();

  // Use sink so the compiler cannot prove it is unused.
  if (sink == 0x7FFFFFFF) print('Impossible sentinel hit');

  final elapsed = watch.elapsedMicroseconds;
  final ops = elapsed == 0 ? 0 : (iterations * 1000000) ~/ elapsed;
  return BenchmarkResult(
      name, ops, elapsed / iterations, watch.elapsedMilliseconds);
}

void printHeader(String title) {
  print('\n${'═' * 70}');
  print('  $title');
  print('═' * 70);
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 1 — State Read & Write (vs Flutter ValueNotifier)
// ─────────────────────────────────────────────────────────────────────────────

void runSignalBenchmarks() {
  printHeader('1. State Read & Write Speed (vs Flutter ValueNotifier)');

  final signal = StateSignal<int>(0);
  final notifier = ValueNotifier<int>(0);

  print(benchmark(
    'StateSignal.value (Read)',
    () => signal.value,
    iterations: 10000000,
  ));

  print(benchmark(
    'ValueNotifier.value (Read)',
    () => notifier.value,
    iterations: 10000000,
  ));

  print(benchmark(
    'StateSignal.value = (Write)',
    () {
      signal.value++;
      return signal.value;
    },
    iterations: 5000000,
  ));

  print(benchmark(
    'ValueNotifier.value = (Write)',
    () {
      notifier.value++;
      return notifier.value;
    },
    iterations: 5000000,
  ));

  signal.dispose();
  notifier.dispose();
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 2 — Listener Fan-out (100 Listeners)
// ─────────────────────────────────────────────────────────────────────────────

void runListenerFanoutBenchmarks() {
  printHeader('2. Listener Fan-out (100 Listeners, vs ValueNotifier)');

  final signal = StateSignal<int>(0);
  final notifier = ValueNotifier<int>(0);
  var triggerCount = 0;

  for (var i = 0; i < 100; i++) {
    signal.addListener(() => triggerCount++);
    notifier.addListener(() => triggerCount++);
  }

  print(benchmark(
    'StateSignal (Notify 100 listeners)',
    () {
      signal.value++;
      return signal.value;
    },
    iterations: 100000,
  ));

  print(benchmark(
    'ValueNotifier (Notify 100 listeners)',
    () {
      notifier.value++;
      return notifier.value;
    },
    iterations: 100000,
  ));

  // Use triggerCount so the compiler keeps all listeners alive
  if (triggerCount == -1) print('Impossible');
  signal.dispose();
  notifier.dispose();
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 3 — ComputedSignal: Cache Hit vs Stale Recalculation
// This is CubePod's biggest differentiator — memoized reactive derivations.
// ─────────────────────────────────────────────────────────────────────────────

void runComputedBenchmarks() {
  printHeader('3. ComputedSignal — Cache Hit vs Stale Recalculation');

  final source = StateSignal<int>(0);

  // Lightweight computation — we want to measure the memoization layer, not
  // the computation cost itself.
  final computed = ComputedSignal<int>(() => source.value * 2);

  // Force one evaluation to populate the cache.
  computed.value;

  print(benchmark(
    'ComputedSignal.value [CACHE HIT — no upstream change]',
    () => computed.value,
    iterations: 10000000,
  ));

  print(benchmark(
    'ComputedSignal.value [STALE — upstream changes each call]',
    () {
      source.value++; // invalidates cache
      return computed.value; // forces recompute
    },
    iterations: 1000000,
  ));

  // Baseline: manual inline derivation without any framework overhead.
  var rawValue = 0;
  print(benchmark(
    'Manual inline derivation (baseline)',
    () {
      rawValue++;
      return rawValue * 2;
    },
    iterations: 10000000,
  ));

  source.dispose();
  computed.dispose();
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 4 — Dependency Injection Resolution
// Baseline: HashMap<Type, Object> lookup (similar to what get_it uses)
// ─────────────────────────────────────────────────────────────────────────────

void runDIBenchmarks() {
  printHeader('4. DI Resolution (vs raw HashMap<Type,Object> lookup)');

  CubePod.reset();
  CubePod.register<int>((c) => 42, scope: Scope.singleton);

  // Warm the singleton cache
  CubePod.get<int>();

  print(benchmark(
    'CubePod.get<int>() (Singleton — cached)',
    () => CubePod.get<int>(),
    iterations: 5000000,
  ));

  // Baseline: direct HashMap lookup — the minimum possible overhead for any DI
  // system. This is approximately what get_it achieves for singletons.
  final rawMap = HashMap<Type, Object>()..putIfAbsent(int, () => 42);
  print(benchmark(
    'HashMap<Type,Object>[int] (baseline — raw map lookup)',
    () => rawMap[int],
    iterations: 5000000,
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION 5 — Effect Lifecycle & Memory Safety
// Creates and disposes 10,000 effects to verify zero memory retention.
// ─────────────────────────────────────────────────────────────────────────────

void runEffectLifecycleBenchmarks() {
  printHeader('5. Effect Lifecycle — Creation, Trigger & Disposal');

  final source = StateSignal<int>(0);
  var runCount = 0;

  print(benchmark(
    'Effect create + auto-run + dispose (10K cycle)',
    () {
      final eff = effect(() {
        source.value; // track dependency
        runCount++;
      });
      eff.dispose();
      return runCount;
    },
    iterations: 10000,
  ));

  // After 10,000 create+dispose cycles, verify source has zero observers.
  // Uses the @visibleForTesting `observerCount` getter — private field access
  // across package boundaries fails even via dynamic in Dart.
  final observerCount = source.observerCount;
  print('  └─ Retained observer count after 10K dispose cycles: $observerCount'
      ' (expected: 0)');
  assert(observerCount == 0,
      'MEMORY LEAK: $observerCount effects were not fully disposed!');

  source.dispose();
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  test('CubePod Real Benchmarks (Flutter SDK)', () {
    print('\nRunning CubePod benchmarks against Flutter SDK...');
    runSignalBenchmarks();
    runListenerFanoutBenchmarks();
    runComputedBenchmarks();
    runDIBenchmarks();
    runEffectLifecycleBenchmarks();
    print('\n${'═' * 70}');
    print('  All benchmarks complete.');
    print('═' * 70);
  });
}

import 'package:cubepod_state/cubepod_state.dart';

void main() {
  print('--- State & Reactivity Benchmarks ---');
  _runSignalBenchmarks();
  _runComputedBenchmarks();
  _runTransactionBenchmarks();
  _runFanOutBenchmarks();
  _runFormBenchmarks();
}

void _runSignalBenchmarks() {
  print('\n[Signal R/W Throughput]');
  final signal = StateSignal(0);
  final stopwatch = Stopwatch();
  const int iterations = 1000000;

  stopwatch.start();
  for (int i = 0; i < iterations; i++) {
    signal.value = i;
  }
  stopwatch.stop();

  var timePerOp = stopwatch.elapsedMicroseconds / iterations;
  var opsPerSec = 1000000 / timePerOp;
  print(
      'Write (No Listeners): ${timePerOp.toStringAsFixed(3)} µs/op (${opsPerSec.toStringAsFixed(0)} ops/sec)');

  stopwatch.reset();
  stopwatch.start();
  for (int i = 0; i < iterations; i++) {
    final _ = signal.value;
  }
  stopwatch.stop();

  timePerOp = stopwatch.elapsedMicroseconds / iterations;
  opsPerSec = 1000000 / timePerOp;
  print(
      'Read (No Context): ${timePerOp.toStringAsFixed(3)} µs/op (${opsPerSec.toStringAsFixed(0)} ops/sec)');
}

void _runComputedBenchmarks() {
  print('\n[ComputedSignal Recomputation Cost]');
  final a = StateSignal(1);
  final b = StateSignal(2);
  final computed = ComputedSignal(() => a.value + b.value);

  // Warmup
  computed.value;

  const int iterations = 100000;
  final stopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    a.value = i;
    final _ = computed.value; // forces recomputation
  }
  stopwatch.stop();

  final timePerOp = stopwatch.elapsedMicroseconds / iterations;
  final opsPerSec = 1000000 / timePerOp;
  print(
      'Update & Recompute: ${timePerOp.toStringAsFixed(3)} µs/op (${opsPerSec.toStringAsFixed(0)} ops/sec)');
}

void _runTransactionBenchmarks() {
  print('\n[Transaction Overhead]');
  final signals = List.generate(100, (i) => StateSignal(0));
  var totalRebuilds = 0;

  final computed = ComputedSignal(() {
    int sum = 0;
    for (final s in signals) {
      sum += s.value;
    }
    return sum;
  });

  final effect = Effect(() {
    computed.value;
    totalRebuilds++;
  });

  const int iterations = 1000;

  // Without transaction
  totalRebuilds = 0;
  final stopwatch = Stopwatch()..start();
  for (int i = 0; i < iterations; i++) {
    for (int j = 0; j < 100; j++) {
      signals[j].value++;
    }
  }
  stopwatch.stop();
  print(
      'Individual Updates: ${stopwatch.elapsedMicroseconds / 1000.0} ms (Total rebuilds: $totalRebuilds)');

  // With transaction
  totalRebuilds = 0;
  stopwatch.reset();
  stopwatch.start();
  for (int i = 0; i < iterations; i++) {
    runTransaction(() {
      for (int j = 0; j < 100; j++) {
        signals[j].value++;
      }
    });
  }
  stopwatch.stop();
  print(
      'Transaction Updates: ${stopwatch.elapsedMicroseconds / 1000.0} ms (Total rebuilds: $totalRebuilds)');

  effect.dispose();
}

void _runFanOutBenchmarks() {
  print('\n[Listener Fan-out]');
  final signal = StateSignal(0);
  final counts = [1, 10, 100, 1000];

  for (final count in counts) {
    final effects = <Effect>[];
    for (int i = 0; i < count; i++) {
      effects.add(Effect(() => signal.value));
    }

    final stopwatch = Stopwatch()..start();
    for (int i = 0; i < 1000; i++) {
      signal.value = i;
    }
    stopwatch.stop();

    final timePerOp = stopwatch.elapsedMicroseconds / 1000.0;
    print('$count Listeners: ${timePerOp.toStringAsFixed(3)} µs/update');

    for (final e in effects) {
      e.dispose();
    }
  }
}

void _runFormBenchmarks() {
  print('\n[Form Validation Performance]');

  final fields = <String, CubeField>{};
  for (int i = 0; i < 50; i++) {
    fields['field_$i'] = CubeField<String>(
      initialValue: '',
      validators: [
        (v) => v.isEmpty ? FieldError('Required') : null,
        (v) => !v.contains('@') ? FieldError('Invalid') : null, // fake regex
      ],
    );
  }

  final form = CubeForm(fields);

  const int iterations = 10000;
  final stopwatch = Stopwatch()..start();

  for (int i = 0; i < iterations; i++) {
    fields['field_0']!.setValue('test_$i@example.com');
    form.validate();
  }

  stopwatch.stop();

  final timePerOp = stopwatch.elapsedMicroseconds / iterations;
  final opsPerSec = 1000000 / timePerOp;
  print(
      '50-Field Validate: ${timePerOp.toStringAsFixed(3)} µs/op (${opsPerSec.toStringAsFixed(0)} ops/sec)');
}

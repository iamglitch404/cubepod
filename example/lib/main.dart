import 'dart:async';

import 'package:cubepod_async/cubepod_async.dart';
import 'package:cubepod_core/cubepod_core.dart';
import 'package:cubepod_events/cubepod_events.dart';
import 'package:cubepod_state/cubepod_state.dart';

import 'di.dart';

Future<void> main() async {
  print('\n=== CubePod Manual Test Suite ===\n');

  await testDI();
  await testState();
  await testAsync();
  await testEvents();

  print('✅ All tests passed.\n');
}

// ─── 1. Dependency Injection ──────────────────────────────────────────────────

Future<void> testDI() async {
  print('--- [1] Dependency Injection ---');

  setup(); // runs $initCubePod()

  final auth = CubePod.get<AuthRepo>();
  final result = await auth.login('user@example.com');
  print('  login result: $result');

  // Factory scope — new instance on every get()
  final client1 = CubePod.get<ApiClient>();
  final client2 = CubePod.get<ApiClient>();
  assert(
      !identical(client1, client2), 'factory should give different instances');
  print('  factory scope: ✓ (different instances)');

  // Singleton scope — same instance every time
  final db1 = CubePod.get<DatabaseService>();
  final db2 = CubePod.get<DatabaseService>();
  assert(identical(db1, db2), 'singleton should give same instance');
  print('  singleton scope: ✓ (same instance)');

  print('  DI: PASS\n');
}

// ─── 2. Reactive State ────────────────────────────────────────────────────────

Future<void> testState() async {
  print('--- [2] Reactive State ---');

  final counter = StateSignal(0);
  final changes = <int>[];

  // addListener is the actual API on StateSignal
  counter.addListener(() => changes.add(counter.value));

  counter.value = 1;
  counter.value = 2;
  counter.value = 3;

  assert(changes.length == 3, 'should have 3 notifications');
  assert(changes.last == 3, 'last value should be 3');
  print('  addListener: ✓ (${changes.length} updates received)');

  // Time-travel: undo/redo
  final text = StateSignal('hello', enableHistory: true);
  text.value = 'world';
  text.undo();
  assert(text.value == 'hello', 'undo should restore previous value');
  text.redo();
  assert(text.value == 'world', 'redo should reapply value');
  print('  undo/redo: ✓');

  print('  State: PASS\n');
}

// ─── 3. Async Utilities ───────────────────────────────────────────────────────

Future<void> testAsync() async {
  print('--- [3] Async Utilities ---');

  // Cancellation token
  final token = CancellationToken();
  var detected = false;

  final task = Future(() async {
    await Future.delayed(Duration(milliseconds: 50));
    if (token.isCancelled) {
      detected = true;
    }
  });

  token.cancel();
  await task;
  assert(detected, 'cancellation should be detected');
  print('  CancellationToken: ✓');

  // Retry policy
  var attempts = 0;
  final policy =
      LinearRetryPolicy(maxRetries: 3, delay: Duration(milliseconds: 5));

  Future<void> runWithRetry() async {
    for (var i = 0; i <= policy.maxRetries; i++) {
      try {
        attempts++;
        throw Exception('fail (attempt $attempts)');
      } catch (_) {
        if (i == policy.maxRetries) rethrow;
        await Future.delayed(policy.getDelay(i));
      }
    }
  }

  try {
    await runWithRetry();
  } catch (_) {}

  assert(attempts == 4, 'should try 4 times (1 + 3 retries), got $attempts');
  print('  LinearRetryPolicy: ✓ ($attempts attempts)');

  print('  Async: PASS\n');
}

// ─── 4. Event Bus ─────────────────────────────────────────────────────────────

Future<void> testEvents() async {
  print('--- [4] Event Bus ---');

  final bus = CubeEventBus();
  final received = <String>[];
  final sub = bus.on<String>((msg) => received.add(msg));

  bus.emit('hello');
  bus.emit('world');

  // Let stream handlers run
  await Future.delayed(Duration(milliseconds: 10));

  assert(
      received.length == 2, 'should receive 2 events, got ${received.length}');
  assert(received[0] == 'hello' && received[1] == 'world');
  print('  CubeEventBus: ✓ (received: $received)');

  await sub.cancel();
  print('  Events: PASS\n');
}

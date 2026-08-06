import "package:cubepod_state/cubepod_state.dart";
import 'package:cubepod_async/cubepod_async.dart';
import 'package:test/test.dart';

void main() {
  group('AsyncSignal', () {
    test('starts in initial state', () {
      final s = AsyncSignal<int>();
      expect(s.value.isLoading, isFalse);
      expect(s.value.hasError, isFalse);
      expect(s.value.data, isNull);
    });

    test('execute() transitions through loading → success', () async {
      final s = AsyncSignal<int>();
      final states = <AsyncState<int>>[];
      s.addListener(() => states.add(s.value));

      await s.execute((_) async => 42);

      expect(states.length, 2);
      expect(states[0].isLoading, isTrue);
      expect(states[1].hasData, isTrue);
      expect(states[1].data, 42);
    });

    test('execute() transitions to error on failure', () async {
      final s = AsyncSignal<int>();
      await s.execute((_) async => throw Exception('fail'));
      expect(s.value.hasError, isTrue);
    });

    test('execute() retries with ExponentialRetryPolicy', () async {
      int attempts = 0;
      final s = AsyncSignal<int>();
      await s.execute(
        (_) async {
          attempts++;
          if (attempts < 3) throw Exception('not yet');
          return 99;
        },
        retryPolicy: ExponentialRetryPolicy(
          maxRetries: 3,
          initialDelay: const Duration(milliseconds: 1),
        ),
      );
      expect(s.value.data, 99);
      expect(attempts, 3);
    });

    test('reset() returns to initial state', () async {
      final s = AsyncSignal<int>();
      await s.execute((_) async => 1);
      expect(s.value.hasData, isTrue);
      s.reset();
      expect(s.value.isLoading, isFalse);
      expect(s.value.data, isNull);
    });

    test('execute() respects cancellation', () async {
      final s = AsyncSignal<int>();
      final token = CancellationToken();
      token.cancel();
      await s.execute(
        (_) async {
          _.throwIfCancelled();
          return 1;
        },
        token: token,
      );
      expect(s.value.hasError, isTrue);
      expect(s.value.error, isA<CancelledException>());
    });

    test('execute() ignores stale tasks that resolve late', () async {
      final s = AsyncSignal<String>();

      final slowTask = s.execute((token) async {
        await Future.delayed(const Duration(milliseconds: 50));
        return 'stale_data';
      });

      final fastTask = s.execute((token) async {
        await Future.delayed(const Duration(milliseconds: 10));
        return 'fresh_data';
      });

      await Future.wait([fastTask, slowTask]);

      expect(s.value.data, 'fresh_data',
          reason:
              'The last requested task should win, not the last to resolve.');
    });
  });

  group('ExponentialRetryPolicy', () {
    test('delay grows exponentially', () {
      final policy = ExponentialRetryPolicy(
        maxRetries: 3,
        initialDelay: const Duration(seconds: 1),
        multiplier: 2.0,
      );
      expect(policy.getDelay(1), const Duration(seconds: 2));
      expect(policy.getDelay(2), const Duration(seconds: 4));
    });

    test('constructor validates arguments', () {
      expect(() => ExponentialRetryPolicy(maxRetries: -1), throwsArgumentError);
      expect(
          () =>
              ExponentialRetryPolicy(initialDelay: const Duration(seconds: -1)),
          throwsArgumentError);
      expect(
          () => ExponentialRetryPolicy(multiplier: 0.5), throwsArgumentError);
    });
  });

  group('SignalDebounceExt', () {
    test(
        'debounce() disposes its internal effect when the returned signal is disposed',
        () async {
      final source = StateSignal<int>(0);
      final debounced = source.debounce(const Duration(milliseconds: 10));

      debounced.dispose(); // Should dispose the internal effect

      // If the effect wasn't disposed, changing the source will trigger it,
      // and it will crash when trying to assign to the disposed debounced signal.
      expect(() {
        source.value = 1;
      }, returnsNormally);

      await Future.delayed(const Duration(milliseconds: 20));
    });
  });
}

import 'package:test/test.dart';
import 'package:cubepod_state/cubepod_state.dart';

void main() {
  test('Transactions batch notifications and prevent tearing', () {
    final a = StateSignal(0);
    final b = StateSignal(0);
    int effectRuns = 0;
    bool observedTear = false;

    final e = Effect(() {
      effectRuns++;
      if (a.value == 1 && b.value == 0) {
        observedTear = true;
      }
    });

    expect(effectRuns, 1);

    runTransaction(() {
      a.value = 1;
      b.value = 1;
    });

    expect(observedTear, isFalse,
        reason: 'Effect should not observe partial state');
    expect(effectRuns, 2,
        reason: 'Effect should only run once after transaction commits');
    e.dispose();
  });

  test('Nested transactions batch to the outermost commit', () {
    final a = StateSignal(0);
    int effectRuns = 0;

    final e = Effect(() {
      effectRuns++;
      // Just read to track
      final _ = a.value;
    });

    expect(effectRuns, 1);

    runTransaction(() {
      a.value = 1;

      runTransaction(() {
        a.value = 2;
      });

      expect(effectRuns, 1, reason: 'Effect should not run after inner commit');
    });

    expect(effectRuns, 2,
        reason: 'Effect should run exactly once after outer commit');
    expect(a.value, 2);
    e.dispose();
  });

  test('Rollback restores state on exception', () {
    final a = StateSignal(0);

    try {
      runTransaction(() {
        a.value = 1;
        throw Exception('abort');
      });
    } catch (_) {}

    expect(a.value, 0, reason: 'State should be restored');
  });

  test('Reads inside transaction observe latest values immediately', () {
    final a = StateSignal(0);
    final computed = ComputedSignal(() => a.value * 2);

    // warm up
    expect(computed.value, 0);

    runTransaction(() {
      a.value = 1;
      expect(computed.value, 2,
          reason:
              'ComputedSignal should invalidate immediately inside transaction');
    });

    expect(computed.value, 2);
  });
}

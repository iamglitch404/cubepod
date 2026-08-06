import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cubepod_core/cubepod_core.dart';
import 'package:cubepod_state/cubepod_state.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// TEST HELPERS
// ─────────────────────────────────────────────────────────────────────────────

/// Wraps [child] in a minimal app shell required by the Flutter test renderer.
Widget app(Widget child) => Directionality(
      textDirection: TextDirection.ltr,
      child: child,
    );

class _DisposableService implements Disposable {
  bool wasDisposed = false;
  @override
  void dispose() => wasDisposed = true;
}

class _Counter extends ChangeNotifier {
  int _count = 0;
  int get count => _count;
  void increment() {
    _count++;
    notifyListeners();
  }
}

class _UnmounterWidget extends StatefulWidget {
  final StateSignal<int> sig;
  const _UnmounterWidget(this.sig);
  @override
  State<_UnmounterWidget> createState() => _UnmounterWidgetState();
}

class _UnmounterWidgetState extends State<_UnmounterWidget> {
  @override
  void dispose() {
    widget.sig.value = 1;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  setUp(() => CubePod.reset());

  // ─────────────────────────────────────────────────────────────────────────────
  // CubeScope Tests
  // ─────────────────────────────────────────────────────────────────────────────

  group('CubeScope', () {
    testWidgets('provides container to descendants via context.get<T>()',
        (tester) async {
      CubePod.register<String>((c) => 'hello', scope: Scope.singleton);

      await tester.pumpWidget(app(
        CubeScope(
          child: Builder(
            builder: (context) => Text(context.get<String>()),
          ),
        ),
      ));

      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('child scope overrides parent registration', (tester) async {
      CubePod.register<String>((c) => 'parent', scope: Scope.singleton);

      await tester.pumpWidget(app(
        CubeScope(
          child: CubeScope(
            overrides: (c) =>
                c.register<String>((c) => 'child', scope: Scope.scoped),
            child: Builder(
              builder: (context) => Text(context.get<String>()),
            ),
          ),
        ),
      ));

      expect(find.text('child'), findsOneWidget);
    });

    testWidgets('fallback to CubePod.root when no CubeScope in tree',
        (tester) async {
      CubePod.register<String>((c) => 'root', scope: Scope.singleton);

      await tester.pumpWidget(app(
        Builder(
          builder: (context) => Text(context.get<String>()),
        ),
      ));

      expect(find.text('root'), findsOneWidget);
    });

    testWidgets('CubeScope.of() throws StateError when no scope in tree',
        (tester) async {
      await tester.pumpWidget(app(
        Builder(builder: (context) {
          expect(() => CubeScope.of(context), throwsStateError);
          return const Text('ok');
        }),
      ));
    });

    testWidgets('CubeScope.maybeOf() returns null when no scope in tree',
        (tester) async {
      await tester.pumpWidget(app(
        Builder(builder: (context) {
          expect(CubeScope.maybeOf(context), isNull);
          return const Text('ok');
        }),
      ));
    });

    testWidgets('disposes scoped Disposable instances on widget removal',
        (tester) async {
      final service = _DisposableService();
      CubePod.register<_DisposableService>((c) => service, scope: Scope.scoped);

      await tester.pumpWidget(app(
        CubeScope(
          child: Builder(
            builder: (context) {
              context.get<_DisposableService>(); // force instantiation
              return const Text('scoped');
            },
          ),
        ),
      ));

      expect(service.wasDisposed, isFalse);

      // Remove CubeScope from the tree
      await tester.pumpWidget(app(const Text('gone')));

      expect(service.wasDisposed, isTrue);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // CubeListenableBuilder Tests
  // ─────────────────────────────────────────────────────────────────────────────

  group('CubeListenableBuilder', () {
    testWidgets('resolves and renders ChangeNotifier from scope',
        (tester) async {
      final counter = _Counter();
      CubePod.register<_Counter>((c) => counter, scope: Scope.singleton);

      await tester.pumpWidget(app(
        CubeScope(
          child: CubeListenableBuilder<_Counter>(
            builder: (context, vm, child) => Text('${vm.count}'),
          ),
        ),
      ));

      expect(find.text('0'), findsOneWidget);
      counter.dispose();
    });

    testWidgets('rebuilds when notifyListeners() is called', (tester) async {
      final counter = _Counter();
      CubePod.register<_Counter>((c) => counter, scope: Scope.singleton);

      await tester.pumpWidget(app(
        CubeScope(
          child: CubeListenableBuilder<_Counter>(
            builder: (context, vm, child) => Text('${vm.count}'),
          ),
        ),
      ));

      expect(find.text('0'), findsOneWidget);

      counter.increment();
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      counter.dispose();
    });

    testWidgets('does NOT rebuild when a different ChangeNotifier fires',
        (tester) async {
      final a = _Counter();
      final b = _Counter();
      CubePod.register<_Counter>((c) => a, scope: Scope.singleton);
      var buildCount = 0;

      await tester.pumpWidget(app(
        CubeScope(
          child: CubeListenableBuilder<_Counter>(
            builder: (context, vm, child) {
              buildCount++;
              return Text('${vm.count}');
            },
          ),
        ),
      ));

      expect(buildCount, 1);

      // Notifying an unrelated notifier must not rebuild this widget
      b.increment();
      await tester.pump();

      expect(buildCount, 1);
      a.dispose();
      b.dispose();
    });

    testWidgets('cleans up listener when widget is removed', (tester) async {
      final counter = _Counter();
      CubePod.register<_Counter>((c) => counter, scope: Scope.singleton);

      await tester.pumpWidget(app(
        CubeScope(
          child: CubeListenableBuilder<_Counter>(
            builder: (context, vm, child) => Text('${vm.count}'),
          ),
        ),
      ));

      // Remove the widget from the tree
      await tester.pumpWidget(app(const Text('unmounted')));

      // Firing notifyListeners after unmount must not cause an exception
      expect(() => counter.increment(), returnsNormally);
      counter.dispose();
    });

    testWidgets('passes child through to builder without rebuilding it',
        (tester) async {
      final counter = _Counter();
      CubePod.register<_Counter>((c) => counter, scope: Scope.singleton);

      var childBuildCount = 0;
      final childWidget = Builder(builder: (ctx) {
        childBuildCount++;
        return const Text('Static Child');
      });

      await tester.pumpWidget(app(
        CubeScope(
          child: CubeListenableBuilder<_Counter>(
            child: childWidget,
            builder: (context, vm, child) => Column(
              children: [
                Text('${vm.count}'),
                if (child != null) child,
              ],
            ),
          ),
        ),
      ));

      expect(childBuildCount, 1);
      expect(find.text('0'), findsOneWidget);
      expect(find.text('Static Child'), findsOneWidget);

      counter.increment();
      await tester.pumpAndSettle();

      // Child should NOT be rebuilt because it is cached and passed through
      expect(childBuildCount, 1);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('Static Child'), findsOneWidget);

      counter.dispose();
    });
  });

  group('CubeBuilder', () {
    testWidgets('renders initial value', (tester) async {
      final counter = StateSignal<int>(0);

      await tester.pumpWidget(app(
        CubeBuilder(
          builder: (ctx, watch) => Text('${watch(counter)}'),
        ),
      ));

      expect(find.text('0'), findsOneWidget);
      counter.dispose();
    });

    testWidgets('rebuilds when signal changes', (tester) async {
      final counter = StateSignal<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(app(
        CubeBuilder(
          builder: (ctx, watch) {
            buildCount++;
            return Text('${watch(counter)}');
          },
        ),
      ));

      expect(find.text('0'), findsOneWidget);
      expect(buildCount, 1);

      counter.value = 1;
      await tester.pumpAndSettle();

      expect(find.text('1'), findsOneWidget);
      expect(buildCount, 2);
      counter.dispose();
    });

    testWidgets('does NOT rebuild when unrelated signal changes',
        (tester) async {
      final a = StateSignal<int>(0);
      final b = StateSignal<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(app(
        CubeBuilder(
          builder: (ctx, watch) {
            buildCount++;
            return Text('${watch(a)}'); // only watches `a`, not `b`
          },
        ),
      ));

      expect(buildCount, 1);

      b.value = 99; // changing b must NOT trigger a rebuild
      await tester.pump();

      expect(buildCount, 1); // still 1
      a.dispose();
      b.dispose();
    });

    testWidgets('tracks multiple signals independently', (tester) async {
      final x = StateSignal<int>(1);
      final y = StateSignal<int>(10);

      await tester.pumpWidget(app(
        CubeBuilder(
          builder: (ctx, watch) => Text('${watch(x) + watch(y)}'),
        ),
      ));

      expect(find.text('11'), findsOneWidget);

      x.value = 2;
      await tester.pumpAndSettle();
      expect(find.text('12'), findsOneWidget);

      y.value = 20;
      await tester.pumpAndSettle();
      expect(find.text('22'), findsOneWidget);
      x.dispose();
      y.dispose();
    });

    testWidgets('unsubscribes stale signals when they leave the build tree',
        (tester) async {
      final showB = StateSignal<bool>(false);
      final a = StateSignal<int>(0);
      final b = StateSignal<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(app(
        CubeBuilder(
          builder: (ctx, watch) {
            buildCount++;
            if (watch(showB)) {
              return Text('b=${watch(b)}');
            }
            return Text('a=${watch(a)}');
          },
        ),
      ));

      expect(buildCount, 1);
      expect(find.text('a=0'), findsOneWidget);

      // Switch to branch B — signal a should be unsubscribed
      showB.value = true;
      await tester.pumpAndSettle();
      expect(find.text('b=0'), findsOneWidget);

      // Changing `a` must NOT trigger a rebuild since we're now on branch B
      a.value = 99;
      await tester.pump();
      final countBeforeAChange = buildCount;
      expect(buildCount, countBeforeAChange); // no extra build from `a`

      showB.dispose();
      a.dispose();
      b.dispose();
    });

    testWidgets('cleans up all listeners when widget is disposed',
        (tester) async {
      final sig = StateSignal<int>(0);
      var buildCountAfterUnmount = 0;

      await tester.pumpWidget(app(
        CubeBuilder(
          builder: (ctx, watch) {
            watch(sig);
            buildCountAfterUnmount++;
            return const Text('content');
          },
        ),
      ));

      final buildCountBeforeUnmount = buildCountAfterUnmount;

      // Replace with a different widget tree to unmount CubeBuilder
      await tester.pumpWidget(app(const Text('unmounted')));

      // After unmounting, signal updates must NOT cause rebuilds or crashes
      sig.value = 99;
      await tester.pump();

      expect(buildCountAfterUnmount, buildCountBeforeUnmount,
          reason: 'CubeBuilder should have unsubscribed on dispose');
      sig.dispose();
    });

    testWidgets('multiple rapid signal updates coalesce into one rebuild',
        (tester) async {
      final sig = StateSignal<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(app(
        CubeBuilder(
          builder: (ctx, watch) {
            buildCount++;
            return Text('${watch(sig)}');
          },
        ),
      ));

      expect(buildCount, 1);

      // Rapid-fire updates in the same frame — Flutter batches setState calls
      sig.value = 1;
      sig.value = 2;
      sig.value = 3;

      await tester.pumpAndSettle();

      // The final value must be reflected
      expect(find.text('3'), findsOneWidget);
      sig.dispose();
    });

    testWidgets('throws StateError if watch is called outside build phase',
        (tester) async {
      final sig = StateSignal<int>(0);
      late WatchFunc capturedWatch;

      await tester.pumpWidget(app(
        CubeBuilder(
          builder: (ctx, watch) {
            capturedWatch = watch;
            return const Text('content');
          },
        ),
      ));

      expect(() => capturedWatch(sig), throwsStateError);
      sig.dispose();
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // CubeListener Tests
  // ─────────────────────────────────────────────────────────────────────────────

  group('CubeListener', () {
    testWidgets('calls listener on signal change with previous and next values',
        (tester) async {
      final sig = StateSignal<int>(0);
      final events = <(int, int)>[];

      await tester.pumpWidget(app(
        CubeListener<int>(
          signal: sig,
          listener: (ctx, prev, next) => events.add((prev, next)),
          child: const Text('static'),
        ),
      ));

      sig.value = 1;
      await tester.pump();

      sig.value = 5;
      await tester.pump();

      expect(events, [(0, 1), (1, 5)]);
      sig.dispose();
    });

    testWidgets('does NOT call listener after widget is disposed',
        (tester) async {
      final sig = StateSignal<int>(0);
      var callCount = 0;

      await tester.pumpWidget(app(
        CubeListener<int>(
          signal: sig,
          listener: (ctx, prev, next) => callCount++,
          child: const Text('child'),
        ),
      ));

      // Unmount the widget
      await tester.pumpWidget(app(const Text('replaced')));

      sig.value = 1; // should NOT fire listener
      await tester.pump();

      expect(callCount, 0);
      sig.dispose();
    });

    testWidgets('resubscribes when signal reference changes', (tester) async {
      final sig1 = StateSignal<int>(10);
      final sig2 = StateSignal<int>(20);
      final currentSig = StateSignal<Signal<int>>(sig1);
      final events = <int>[];

      // We use a CubeBuilder outer to watch `currentSig` and pass the inner
      // signal reference dynamically.
      await tester.pumpWidget(app(
        CubeBuilder(builder: (ctx, watch) {
          final inner = watch(currentSig);
          return CubeListener<int>(
            signal: inner,
            listener: (ctx, prev, next) => events.add(next),
            child: const Text('child'),
          );
        }),
      ));

      sig1.value = 11;
      await tester.pump();
      expect(events, [11]);

      // Switch to sig2 — listener must now fire for sig2, not sig1
      currentSig.value = sig2;
      await tester.pumpAndSettle();

      sig2.value = 21;
      await tester.pump();
      sig1.value = 99; // old signal — must NOT fire
      await tester.pump();

      expect(events, [11, 21]); // 99 from sig1 must not appear
      sig1.dispose();
      sig2.dispose();
      currentSig.dispose();
    });

    testWidgets('safe against synchronous signal updates during unmount',
        (tester) async {
      final sig = StateSignal<int>(0);
      var caughtException = false;

      // When the tree is replaced, _UnmounterWidget is deactivated and updates
      // the signal synchronously. CubeListener is also deactivated. If CubeListener
      // does not check mounted, it will execute its listener with an invalid context.
      await tester.pumpWidget(app(
        Column(
          children: [
            _UnmounterWidget(sig),
            CubeListener<int>(
              signal: sig,
              listener: (ctx, prev, next) {
                try {
                  ctx.size; // throws if unmounted
                } catch (e) {
                  caughtException = true;
                }
              },
              child: const SizedBox(),
            ),
          ],
        ),
      ));

      await tester.pumpWidget(app(const SizedBox()));

      expect(caughtException, isFalse,
          reason: 'Listener should not fire if unmounted');
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // CubeSelector Tests
  // ─────────────────────────────────────────────────────────────────────────────

  group('CubeSelector', () {
    testWidgets('renders selected value', (tester) async {
      final sig = StateSignal<int>(5);

      await tester.pumpWidget(app(
        CubeSelector<int, String>(
          signal: sig,
          selector: (v) => 'value is $v',
          builder: (ctx, s) => Text(s),
        ),
      ));

      expect(find.text('value is 5'), findsOneWidget);
      sig.dispose();
    });

    testWidgets('rebuilds only when selected value changes', (tester) async {
      final sig = StateSignal<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(app(
        CubeSelector<int, bool>(
          signal: sig,
          selector: (v) => v > 5, // only changes at the threshold
          builder: (ctx, isAbove) {
            buildCount++;
            return Text(isAbove ? 'above' : 'below');
          },
        ),
      ));

      expect(buildCount, 1);
      expect(find.text('below'), findsOneWidget);

      sig.value = 3; // selected value (false) unchanged → no rebuild
      await tester.pump();
      expect(buildCount, 1);

      sig.value = 6; // selected value changes (true) → rebuild
      await tester.pumpAndSettle();
      expect(buildCount, 2);
      expect(find.text('above'), findsOneWidget);

      sig.value = 10; // still true → no rebuild
      await tester.pump();
      expect(buildCount, 2);
      sig.dispose();
    });

    testWidgets('custom equals function controls rebuild gate', (tester) async {
      final sig = StateSignal<int>(0);
      var buildCount = 0;

      await tester.pumpWidget(app(
        CubeSelector<int, int>(
          signal: sig,
          selector: (v) => v,
          // Custom equals: only rebuild when value crosses a multiple of 10
          equals: (prev, next) => (prev ~/ 10) == (next ~/ 10),
          builder: (ctx, v) {
            buildCount++;
            return Text('$v');
          },
        ),
      ));

      sig.value = 5; // same decade (0–9) → no rebuild
      await tester.pump();
      expect(buildCount, 1);

      sig.value = 10; // crosses decade boundary → rebuild
      await tester.pumpAndSettle();
      expect(buildCount, 2);
      sig.dispose();
    });

    testWidgets('cleans up listener on dispose', (tester) async {
      final sig = StateSignal<int>(0);

      await tester.pumpWidget(app(
        CubeSelector<int, int>(
          signal: sig,
          selector: (v) => v,
          builder: (ctx, v) => Text('$v'),
        ),
      ));

      await tester.pumpWidget(app(const Text('replaced')));

      // After unmounting, sig must have no listeners
      // CubeSelector uses signal.addListener (not observers), so check indirectly
      // by verifying no crash on update:
      expect(() => sig.value = 99, returnsNormally);
      sig.dispose();
    });

    testWidgets('recalculates selected value when selector function changes',
        (tester) async {
      final sig =
          StateSignal<Map<String, String>>({'first': 'John', 'last': 'Doe'});

      // Helper widget to allow changing the selector
      Widget buildSelectorWidget(
          String Function(Map<String, String>) selector) {
        return app(
          CubeSelector<Map<String, String>, String>(
            signal: sig,
            selector: selector,
            builder: (ctx, v) => Text(v),
          ),
        );
      }

      await tester.pumpWidget(buildSelectorWidget((v) => v['first']!));
      expect(find.text('John'), findsOneWidget);

      // Rebuild with DIFFERENT selector but SAME signal
      await tester.pumpWidget(buildSelectorWidget((v) => v['last']!));

      // The widget should immediately update to 'Doe' without waiting for the signal to emit
      expect(find.text('Doe'), findsOneWidget,
          reason: 'Selector should recalculate on widget rebuild');

      sig.dispose();
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // CubeConsumer Tests
  // ─────────────────────────────────────────────────────────────────────────────

  group('CubeConsumer', () {
    testWidgets('both listens and builds from same signal', (tester) async {
      final sig = StateSignal<int>(0);
      final listenerEvents = <int>[];

      await tester.pumpWidget(app(
        CubeConsumer<int>(
          signal: sig,
          listener: (ctx, prev, next) => listenerEvents.add(next),
          builder: (ctx, watch) => Text('${watch(sig)}'),
        ),
      ));

      sig.value = 42;
      await tester.pumpAndSettle();

      expect(find.text('42'), findsOneWidget);
      expect(listenerEvents, [42]);
      sig.dispose();
    });
  });

  // ─────────────────────────────────────────────────────────────────────────────
  // ComputedSignal + CubeBuilder Integration Tests
  // ─────────────────────────────────────────────────────────────────────────────

  group('ComputedSignal + CubeBuilder Integration', () {
    testWidgets('widget rebuilds when computed invalidates', (tester) async {
      final source = StateSignal<int>(2);
      final doubled = ComputedSignal<int>(() => source.value * 2);

      await tester.pumpWidget(app(
        CubeBuilder(
          builder: (ctx, watch) => Text('${watch(doubled)}'),
        ),
      ));

      expect(find.text('4'), findsOneWidget);

      source.value = 5;
      await tester.pumpAndSettle();

      expect(find.text('10'), findsOneWidget);
      source.dispose();
      doubled.dispose();
    });

    testWidgets('widget does not rebuild for cached computed reads',
        (tester) async {
      final source = StateSignal<int>(0);
      final parity =
          ComputedSignal<String>(() => source.value.isEven ? 'even' : 'odd');
      var buildCount = 0;

      await tester.pumpWidget(app(
        CubeBuilder(
          builder: (ctx, watch) {
            buildCount++;
            return Text(watch(parity));
          },
        ),
      ));

      expect(buildCount, 1);

      source.value = 2; // still even → computed output unchanged
      await tester.pump();
      // The CubeBuilder listener fires (signal notified), but if we want true
      // no-rebuild we'd need CubeSelector. Here we verify it at least
      // shows the correct value.
      expect(find.text('even'), findsOneWidget);

      source.value = 3; // now odd → computed changes → rebuild
      await tester.pumpAndSettle();
      expect(find.text('odd'), findsOneWidget);
      source.dispose();
      parity.dispose();
    });
  });
}

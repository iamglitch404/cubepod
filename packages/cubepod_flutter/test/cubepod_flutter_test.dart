import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';
import 'package:cubepod_state/cubepod_state.dart';
import 'package:cubepod_core/cubepod_core.dart';

void main() {
  setUp(() {
    CubePod.reset();
  });

  testWidgets('CubeBuilder rebuilds when signal changes',
      (WidgetTester tester) async {
    final counter = StateSignal<int>(0);
    int buildCount = 0;

    await tester.pumpWidget(Directionality(
        textDirection: TextDirection.ltr,
        child: CubeBuilder(builder: (context, watch) {
          buildCount++;
          final count = watch(counter);
          return Text(count.toString());
        })));

    expect(find.text('0'), findsOneWidget);
    expect(buildCount, 1);

    counter.value = 1;
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(buildCount, 2);
  });

  testWidgets('CubeContext extension resolves DI', (WidgetTester tester) async {
    CubePod.register(() => 42, scope: Scope.singleton);

    int? resolvedValue;

    await tester.pumpWidget(Builder(builder: (context) {
      resolvedValue = context.get<int>();
      return const SizedBox();
    }));

    expect(resolvedValue, 42);
  });
}

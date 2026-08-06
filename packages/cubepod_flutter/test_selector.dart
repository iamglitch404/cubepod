import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:cubepod_state/cubepod_state.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';

void main() {
  testWidgets('CubeSelector recalculates when selector changes',
      (WidgetTester tester) async {
    final signal =
        StateSignal<Map<String, String>>({'name': 'John', 'last': 'Doe'});

    // Initial build with first selector
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CubeSelector<Map<String, String>, String>(
          signal: signal,
          selector: (v) => v['name']!,
          builder: (context, value) => Text(value),
        ),
      ),
    );

    expect(find.text('John'), findsOneWidget);

    // Rebuild with DIFFERENT selector but SAME signal
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: CubeSelector<Map<String, String>, String>(
          signal: signal,
          selector: (v) => v['last']!,
          builder: (context, value) => Text(value),
        ),
      ),
    );

    // If the bug exists, it will still render 'John' because _selectedValue didn't update!
    expect(find.text('Doe'), findsOneWidget,
        reason: 'Selector should recalculate on widget rebuild');
  });
}

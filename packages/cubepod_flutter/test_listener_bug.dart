import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cubepod_state/cubepod_state.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';

class _UnmounterWidget extends StatefulWidget {
  final StateSignal<int> sig;
  const _UnmounterWidget(this.sig);
  @override
  State<_UnmounterWidget> createState() => _UnmounterWidgetState();
}

class _UnmounterWidgetState extends State<_UnmounterWidget> {
  @override
  void deactivate() {
    widget.sig.value = 1;
    super.deactivate();
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}

void main() {
  testWidgets(
      'CubeListener is safe against synchronous signal updates during unmount',
      (tester) async {
    final sig = StateSignal<int>(0);
    var caughtException = false;

    // Flutter unmounts children. We want _UnmounterWidget.deactivate to fire
    // before CubeListener is fully disposed, but after CubeListener's context is invalid.
    await tester.pumpWidget(
      Directionality(
        textDirection: TextDirection.ltr,
        child: Column(
          children: [
            _UnmounterWidget(sig),
            CubeListener<int>(
              signal: sig,
              listener: (ctx, prev, next) {
                try {
                  // This will throw if ctx is unmounted
                  ctx.size;
                } catch (e) {
                  caughtException = true;
                }
              },
              child: const SizedBox(),
            ),
          ],
        ),
      ),
    );

    // Unmount both widgets by replacing the tree
    await tester.pumpWidget(
      const Directionality(
        textDirection: TextDirection.ltr,
        child: SizedBox(),
      ),
    );

    expect(caughtException, isFalse,
        reason: 'CubeListener fired its listener while unmounted');
  });
}

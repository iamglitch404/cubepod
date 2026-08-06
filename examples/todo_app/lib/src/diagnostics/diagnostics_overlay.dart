import 'package:flutter/material.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';
import 'diagnostics_service.dart';

class DiagnosticsOverlay extends StatelessWidget {
  final Widget child;

  const DiagnosticsOverlay({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        Positioned(
          bottom: 20,
          right: 20,
          child: IgnorePointer(
            child: Material(
              color: Colors.transparent,
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CubeBuilder(builder: (context, watch) {
                  final diag = context.get<DiagnosticsService>();
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Diagnostics',
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold)),
                      Text(
                          'Allocations: ${watch(diag.allocationsSignal).length}',
                          style: const TextStyle(color: Colors.white70)),
                      Text('Logs: ${watch(diag.logsSignal).length}',
                          style: const TextStyle(color: Colors.white70)),
                    ],
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

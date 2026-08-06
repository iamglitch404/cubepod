import 'package:flutter/material.dart';
import 'package:cubepod_core/cubepod_core.dart';
import 'package:cubepod_flutter/cubepod_flutter.dart';
import 'package:cubepod_state/cubepod_state.dart';
import 'package:cubepod_storage/cubepod_storage.dart';

import 'src/core/router.dart';
import 'src/diagnostics/diagnostics_overlay.dart';
import 'src/diagnostics/diagnostics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize global storage before app startup
  final globalStorage = SharedPreferencesStorage();
  await globalStorage.init();
  CubePod.register<StorageService>((c) => globalStorage,
      scope: Scope.singleton);

  // Register global diagnostic services
  final diagnosticsService = DiagnosticsService();
  CubePod.register<DiagnosticsService>((c) => diagnosticsService,
      scope: Scope.singleton);

  // Hook global errors
  SignalConfig.errorHandler = (error, stack) {
    diagnosticsService.logError(error, stack);
  };

  // Hook DevTools
  CubeDevToolsObserver.instance = diagnosticsService;

  runApp(const ShowcaseApp());
}

class ShowcaseApp extends StatelessWidget {
  const ShowcaseApp({super.key});

  @override
  Widget build(BuildContext context) {
    return CubeScope(
      child: MaterialApp(
        title: 'CubePod v0.1.5 Integration Showcase',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.deepPurple,
            brightness: Brightness.dark,
          ),
        ),
        onGenerateRoute: showcaseRouter.onGenerateRoute,
        builder: (context, child) {
          return DiagnosticsOverlay(
            child: child ?? const SizedBox(),
          );
        },
      ),
    );
  }
}

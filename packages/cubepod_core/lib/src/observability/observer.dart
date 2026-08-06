// Abstract observer interface for the CubePod observability layer.
//
// Set [CubeDevToolsObserver.instance] to a concrete implementation to receive
// lifecycle events from the DI container and signal engine. Use this to build
// DevTools integrations, logging, or analytics pipelines.
abstract class CubeObserver {
  void onSignalCreated(String id, dynamic value);
  void onSignalUpdated(String id, dynamic value, dynamic previousValue);
  void onDependencyRegistered(Type type, dynamic instance);
  void onDependencyResolved(Type type, dynamic instance);
  void onDependencyDisposed(Type type, dynamic instance);
}

/// Global hook for CubePod lifecycle events.
///
/// Set [instance] to any [CubeObserver] implementation before calling
/// [CubePod.register] or resolving dependencies. All container and signal
/// events will be forwarded to your observer.
///
/// ```dart
/// // In main(), before runApp():
/// CubeDevToolsObserver.instance = MyCrashReporter();
/// ```
///
/// Set [instance] to `null` to disable all observations (the default).
class CubeDevToolsObserver {
  CubeDevToolsObserver._();

  /// The active observer. Defaults to `null` (no-op).
  static CubeObserver? instance;
}

part of 'signal.dart';

// Provides a pluggable error handler so host apps can route signal exceptions
// to Sentry, Firebase Crashlytics, or a custom logger.

/// Global configuration for the CubePod state engine.
///
/// Set [errorHandler] to intercept and log errors that occur inside listener
/// callbacks or effect bodies without crashing the application.
///
/// ```dart
/// SignalConfig.errorHandler = (error, stack) {
///   Sentry.captureException(error, stackTrace: stack);
/// };
/// ```
class SignalConfig {
  SignalConfig._();

  /// Called whenever an exception occurs inside a listener callback, observer
  /// notification, or effect body. Defaults to forwarding to the current
  /// [Zone]'s uncaught error handler (same as `FlutterError.onError` in a
  /// running Flutter app).
  static void Function(Object error, StackTrace stack) errorHandler =
      (error, stack) => Zone.current.handleUncaughtError(error, stack);
}

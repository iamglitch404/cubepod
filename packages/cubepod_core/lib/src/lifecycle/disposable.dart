/// Implement this interface to participate in CubePod's disposal lifecycle.
///
/// When a `CubeContainer` is disposed, all registered instances that implement
/// [Disposable] will have their [dispose] method called automatically in
/// reverse registration order (LIFO).
///
/// ```dart
/// class ApiService implements Disposable {
///   @override
///   void dispose() => _httpClient.close();
/// }
/// ```
abstract class Disposable {
  void dispose();
}

## 0.1.5

- Added `CubeListenableBuilder<T extends Listenable>` — resolves a `ChangeNotifier` or `Listenable` from the nearest `CubeScope` and rebuilds on `notifyListeners()`. This eliminates the repetitive `context.get<T>()` + `ListenableBuilder` boilerplate confirmed across two reference applications.
- Added comprehensive `///` doc comments to `CubeScope`, `CubeBuilder`, `CubeListenableBuilder`, and the `context.get<T>()` extension.
- Improved `CubeScope.of()` error message to include a remediation hint.
- Added `publish_to: none` to `pubspec.yaml`.
- Added widget tests for `CubeScope` lifecycle and `CubeListenableBuilder` rebuilds.

## 0.1.4


Added a full widget test suite — 20 tests in total covering `CubeBuilder`, `CubeListener`, `CubeSelector`, and `CubeConsumer`. Tests include widget mount/unmount lifecycle, stale subscription pruning, multi-signal tracking, listener re-subscription when the signal reference changes, and the `CubeSelector` custom equals gate.

`CubeBuilder` now correctly prunes subscriptions to signals that leave the build tree mid-session (e.g., when a conditional branch switches and the previous branch's signals are no longer watched). Previously those signals would keep the widget alive in their listener lists.

`CubeListener` handles `didUpdateWidget` correctly — if the parent passes a new signal reference, it unsubscribes from the old one and subscribes to the new one atomically.

## 0.1.2

Added `CubeConsumer` (combines `CubeListener` + `CubeBuilder` in one widget), `CubeSelector` for derived value rebuilds with optional custom equals, and `extensions.dart` for context-based signal access helpers.

## 0.1.0

Initial release with `CubeBuilder` and `CubeListener`.

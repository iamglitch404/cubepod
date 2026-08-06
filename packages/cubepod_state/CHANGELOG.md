## 0.1.5

- Added `publish_to: none` to `pubspec.yaml`.
- Added unit tests for `runTransaction` rollback, `StreamSignal`, and `CubeForm`.
- No API changes.

## 0.1.4

This was a big one. After a thorough community audit, several critical engine bugs were found and fixed.

**Exception isolation.** An exception thrown inside a listener callback used to permanently kill the signal — no downstream listeners would ever receive that update again. This is now fixed. All listener invocations are wrapped in individual try/catch blocks. Errors are forwarded to a new `SignalConfig.errorHandler` that you can replace with your own Sentry or Crashlytics handler.

**Re-entrant writes.** Writing to a signal from inside one of its own listener callbacks used to silently drop the new value. It now queues the write in a `_deferredUpdates` list and processes it immediately after the current notification pass finishes. No dropped updates, no infinite loops.

**RangeError on self-unsubscription.** Removing a listener from a signal while that signal was mid-notification used to crash with a `RangeError`. The notify loop now iterates a `.toList()` snapshot of the listener array, so removals during iteration are completely safe.

**Memory leaks in Effects and ComputedSignals.** Calling `.dispose()` on an `Effect` or `ComputedSignal` now proactively removes the node from every upstream signal's observer list. Previously, disposed effects would linger in memory indefinitely. I verified this by running 10,000 create+dispose cycles and asserting that the source signal retains exactly 0 observers afterwards.

**New API.** Added `SignalConfig.errorHandler` — a static callback you can set to intercept all signal/effect errors globally.

## 0.1.2

Added `Effect` and `ComputedSignal` primitives, `StateSignal` history with `enableHistory`, and `StreamSignal` for bridging Dart streams into the reactive graph.

## 0.1.0

Initial release with `StateSignal` and basic addListener/removeListener model.

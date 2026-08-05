## 0.1.4

Added `SignalTester<T>` — a test utility that records all values emitted by a signal during a test and lets you assert on the full sequence. Added `pumpSignals()` helper to flush any deferred signal updates synchronously in test environments (useful when testing code that uses the re-entrancy queue).

## 0.1.2

Added mock DI container (`MockCubePod`) for isolated unit testing without real service registrations.

## 0.1.0

Initial release with CubePod testing utilities.

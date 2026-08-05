## 0.1.4

`CubeEventBus.emit()` benchmarked at 10M+ ops/sec on real hardware. Fixed a type-unsafe wildcard subscription edge case where `bus.on<dynamic>()` would intercept events meant for typed subscribers.

## 0.1.2

Added type-safe wildcard subscriptions via `bus.on<dynamic>()`. Added `removeAllListeners()` utility.

## 0.1.0

Initial release with `CubeEventBus`.

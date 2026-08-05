## 0.1.4

Fixed a race condition in the `SharedPreferences` adapter — calling `StorageSignal` before `await SharedPreferences.getInstance()` completed would crash. The adapter now buffers writes until initialization is complete. Added an `InMemoryStorageAdapter` for use in unit tests so you don't need to mock platform channels.

## 0.1.2

Added `StorageSignal<T>` — a `StateSignal` that automatically persists its value across app sessions using a pluggable storage adapter.

## 0.1.0

Initial release with `CubeStorage`.

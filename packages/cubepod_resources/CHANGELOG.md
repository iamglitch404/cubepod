## 0.1.5

- Synchronized version to 0.1.5 for Alpha release preparation.

## 0.1.4

`Resource.dispose()` now emits a DevTools observer event so you can trace resource lifecycle in the DevTools timeline. Fixed the `ResourcePool` FIFO eviction policy — it was accidentally evicting in LIFO order.

## 0.1.2

Added `ResourcePool<T>` for managing bounded pools of disposable resources (connections, heavy objects). Added configurable eviction policies.

## 0.1.0

Initial release with `Resource` and `ManagedResource` primitives.

## 0.1.5

- Fixed `CubeDevToolsObserver`: removed the self-delegating `implements CubeObserver` implementation that could cause a `StackOverflowError`. It is now a clean static holder (`CubeDevToolsObserver.instance`) for the active observer.
- Fixed `CircularDependencyError` message grammar: "dep" → "dependency".
- Improved `CubeScope.of()` error message to include a remediation hint.
- Added comprehensive `///` doc comments to all public APIs: `CubeContainer`, `CubePod`, `Scope`, `FactoryFunc`, `Disposable`.
- Added `CircularDependencyError` detection test.
- Added `ResourcePool` unit tests.

## 0.1.4

Finally got around to fixing a few things that were bugging me.

Singleton resolution is now O(1) — singletons live in their own separate map so cached lookups never share a bucket with factory registrations. The hot-path for `CubePod.get<T>()` no longer touches the factory map at all once a singleton is cached.

Also cleaned up the scoped container teardown. Calling `CubePod.popScope()` now correctly calls `dispose()` on all scoped instances that implement `Disposable`.

Added DevTools observer hooks for dependency registration and resolution events. Useful for debugging DI graphs in development.

## 0.1.2

First stable release of the DI container and observability layer. Includes cycle detection, factory/singleton/scoped lifetimes, and named registrations.

## 0.1.0

Initial release.

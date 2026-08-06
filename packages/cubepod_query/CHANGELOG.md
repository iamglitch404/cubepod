## 0.1.5

- Synchronized version to 0.1.5 for Alpha release preparation.

## 0.1.4

Benchmarked `CubeQuery.fetch()` cache-hit path at 11.5M ops/sec against real Flutter SDK baselines. Fixed stale-time comparison logic — previously the stale check used wall-clock `DateTime.now()` which could behave unexpectedly during clock adjustments. Switched to `Stopwatch`-based elapsed tracking.

## 0.1.2

Added `force: true` flag to `CubeQuery.fetch()` to bypass the cache. Added configurable `staleTime` and `cacheTime` durations. Added query key support for cache namespacing.

## 0.1.0

Initial release with `CubeQuery` data fetching primitive.

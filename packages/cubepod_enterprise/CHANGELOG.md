## 0.1.5

- Synchronized version to 0.1.5 for Alpha release preparation.

## 0.1.4

`InMemoryFeatureFlagService.isEnabled()` benchmarked at 31M+ ops/sec — safe to call inside hot build loops. Added A/B variant assignment with deterministic hashing (same user always gets the same variant).

## 0.1.2

Added `MultiTenantRegistry` for scoping entire DI containers per tenant. Added `FeatureFlagService` interface with a remote config adapter.

## 0.1.0

Initial release with enterprise-grade extensions.

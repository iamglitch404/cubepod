# CubePod Architecture Philosophy

## Why build another framework?

Flutter developers are forced to stitch together 5-10 different libraries to build a production app. You need `provider` or `riverpod` for state, `get_it` for DI, `go_router` for navigation, `dio` for networking, and `sqflite` for local caching.

When these libraries update independently, they often break each other. Worse, debugging a memory leak across 4 different third-party boundaries is a nightmare.

**CubePod was built to be the unified Application Runtime.** 

By designing the State layer, DI container, Network layer, and Router to be explicitly aware of each other, CubePod delivers:
1. **Zero Fragmentation:** All parts of your app speak the same language.
2. **Predictable Performance:** Signals rebuild exactly one widget in O(1) time.
3. **Enterprise Scalability:** Built-in tools for multi-tenancy, audit logging, and dead-letter offline sync queues.

## The Modules

### 🧊 cubepod_core
The heart of the framework. It handles the `CubePod` dependency injection container. It is strict about circular dependencies and prevents app crashes at startup.

### ⚡ cubepod_state
The reactive engine. Powered by `StateSignal`, `ComputedSignal`, and `Effect`. It uses a `Set<VoidCallback>` for nanosecond-level subscription tracking.

### 🌐 cubepod_network & cubepod_sync
An offline-first network layer. If a user tries to submit data without an internet connection, `cubepod_sync` automatically queues the request in SQLite, applies an exponential backoff retry policy, and eventually pushes unrecoverable errors to a Dead Letter Queue.

### 🏢 cubepod_enterprise
Built for Fortune 500 apps. Includes `TenantConfig` for white-labeling the app dynamically, `FeatureFlagService` for phased rollouts, and `AuditLogger` to track state changes for compliance.

---
*Built by Qubix Tech Nepal. Designed for the next generation of Flutter engineers.*

# CubePod Monorepo — CHANGELOG

All notable changes to the CubePod framework are documented here.
Per-package changelogs are in their respective `CHANGELOG.md` files.

---

## v0.1.5 — Alpha Release Preparation

This release finalizes the architecture for the first external alpha. It includes a few minor API adjustments for performance, DX (Developer Experience) improvements, and extensive fixes to the showcase example applications to properly demonstrate the framework's lifecycle guardrails.

### Bug Fixes & API Adjustments
- **`CubeListenableBuilder` API**: Added a `child` parameter to the builder signature (`(context, vm, child)`) to allow caching expensive widget subtrees and prevent unnecessary rebuilds.
- **`CubePod.debugDump()` API**: Changed return type from `void` to `String`. It now returns the formatted registration tree instead of printing it directly to stdout, allowing custom developer tooling/overlays to render the dump.
- **`CubeDevToolsObserver`**: Fixed a self-delegation loop where every observer method delegated back to `instance`, causing a potential `StackOverflowError`. The class is now a clean static holder for the active `CubeObserver`.
- **`CircularDependencyError`**: Fixed grammar — "circular dep detected" → "circular dependency detected".
- **`CubeScope.of()` error message**: Improved to tell developers what to do, not just what went wrong.

### Showcase Integrations (`examples/todo_app`)
- **DI Lifecycle**: Updated `core_showcase.dart` to properly catch and handle expected duplicate registration `StateError`s. Added an explicit `CubePod.createScope()` lifecycle test to demonstrate scope disposal.
- **Storage Bootstrapping**: Fixed initialization ordering in `storage_showcase.dart`. Storage is now correctly initialized globally in `main.dart` and resolved via DI.
- **Diagnostics Overlay**: Built a bounded in-app logger (max 50 lines) to visualize dependency graphs and signal mutations directly on-screen without lagging the UI.

### Documentation
- README: Completely rewritten. Removed references to unimplemented packages (`cubepod_query`, `cubepod_sync`, `cubepod_network`, etc.). Rewrote value proposition around what CubePod actually provides today. All code examples compile.
- `GETTING_STARTED.md`: Rewrote entirely. Fixed version to `^0.1.5`. Removed `CubeQuery` example. Added `CubeListenableBuilder` section with a before/after comparison.
- `ARCHITECTURE.md`: Removed references to unimplemented packages. Fixed branding inconsistency. Added container hierarchy diagram and design decision rationale. Added honest "What's Coming" section.
- Added this root-level `CHANGELOG.md`.

### API Documentation
- Added `///` doc comments to all public APIs in `cubepod_core`: `CubeContainer`, `CubePod`, `Scope` enum (each value), `FactoryFunc`, `Disposable`, and all public methods.
- Added `///` doc comments to all public APIs in `cubepod_flutter`: `CubeScope`, `CubeBuilder`, `CubeListenableBuilder`, `context.get<T>()` extension.

### Tests
- Added widget test suite for `cubepod_flutter` (`CubeScope`, `CubeListenableBuilder`, `CubeBuilder`).
- Added `CircularDependencyError` and `ResourcePool` tests to `cubepod_core`.
- Added `StreamSignal` and `CubeForm` tests to `cubepod_state`.
- Added synchronous, batched transaction tests with rollback guarantees.

**Migration Note:** `runTransaction` has been changed from `async` to strictly synchronous (`void runTransaction(void Function())`) to guarantee atomic batching and prevent UI tearing. If you previously had `await` calls inside a transaction, you must move them before the transaction block.
```dart
// Before (v0.1.4)
await runTransaction(() async {
  final data = await fetch();
  sig.value = data;
});

// Now (v0.1.5)
final data = await fetch();
runTransaction(() {
  sig.value = data;
});
```
- Added `MockContainer.overrideWith` test to `cubepod_testing`.

### Package Metadata & Repository Polish
- Added `publish_to: none` to `cubepod_state/pubspec.yaml` (matching `cubepod_flutter`).
- Rewrote all auto-generated placeholder `description` fields across 13 packages for pub.dev readiness.
- Removed unused `*_base.dart` boilerplate files across the monorepo.
- Removed duplicate `example/` directory in favor of the correct `examples/` directory.
- Added OSS community standards: `CODE_OF_CONDUCT.md`, `SECURITY.md`, and `.github/ISSUE_TEMPLATE`.
- Split large internal files (`cubepod.dart` and `signal.dart`) into logical components without breaking the public API exports.

---

## v0.1.4

Initial development milestone. See per-package changelogs for details.

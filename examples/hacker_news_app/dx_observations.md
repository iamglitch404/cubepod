# CubePod DX Observations

This document logs framework pain points, boilerplate, and proposed API improvements discovered while building the Hacker News reference application.

## Observations

## Hypotheses for DX Improvements

*Note: These are currently hypotheses derived from a single application (Hacker News Client). They will not be implemented until validated across at least three different real-world applications.*

### Hypothesis 1: Route-Scoped Dependency Boilerplate
**Observation:**
Injecting a View Model that should be scoped to a specific screen (e.g., `HomeViewModel` for the Home route) is incredibly verbose. In the router, for every single route, we have to:
1. Call `CubePod.createScope(parent: ...)`
2. Manually register the view model on that child container.
3. Wrap the route's widget in a `CubeScope(container: child, child: ...)` widget.
**Proposed Improvement:**
Create a wrapper widget, e.g., `CubeRouteProvider`, or integrate with `go_router` specifically so developers can just declare `CubeProvider((c) => HomeViewModel(...), child: HomeScreen())` which automatically manages the container lifecycle for that subtree.

### Hypothesis 2: Consuming UI State (ChangeNotifier / ValueNotifier)
**Observation:**
CubePod is great at resolving dependencies, but Flutter UI state is inherently reactive. Right now, to consume a `HomeViewModel` which extends `ChangeNotifier`, developers have to do:
```dart
final viewModel = context.get<HomeViewModel>();
return ListenableBuilder(
  listenable: viewModel,
  builder: (context, _) { ... }
);
```
This is two steps and feels clunky compared to Riverpod or Provider. 
**Proposed Improvement:**
Add a `context.watch<T>()` extension to `CubeScope`. If `T` is a `ChangeNotifier` or `ValueNotifier`, `CubeScope` (or a specialized `CubeBuilder` widget) should automatically subscribe to it and trigger a rebuild of the calling widget when it changes.

### Hypothesis 3: Root Application Scope
**Observation:**
Wrapping the `MaterialApp` in a `CubeScope(container: CubePod.root)` is necessary for `context.get<T>()` to work if no other scope is above it. It's slightly repetitive and easy to forget.
**Proposed Improvement:**
Consider adding a `CubePodProvider` top-level widget that defaults to `CubePod.root`, making the API more semantically similar to established Flutter libraries.

# CubePod Architecture

## Philosophy

Flutter developers typically assemble apps from 5–10 independent packages: one for state, one for DI, one for routing, one for networking. These libraries evolve independently and break each other at upgrade time. Debugging a lifecycle issue that spans two libraries is significantly harder than debugging one.

CubePod is built on a different premise: **the DI container, the reactive engine, and the Flutter integration layer should be designed to work together from the start.** That shared design makes the whole more predictable than the sum of its parts.

---

## Core Concepts

### The Container Hierarchy

The `CubeContainer` is the heart of the framework. Every registration and resolution goes through a container.

```
CubePod.root  (singleton — lives for the app lifetime)
│
├── Screen A scope  (scoped — lives for the screen lifetime)
│   └── Feature X scope  (scoped — nested override)
│
└── Screen B scope  (scoped)
```

- **Root registrations** are shared across the entire app.
- **Scoped registrations** override or extend root registrations for a bounded context.
- **Child containers** inherit from parents but cannot pollute them.

This hierarchy is what makes testing clean: a test can create a fresh child scope with fakes registered, and the parent root is unaffected.

### The Three Lifetimes

| Lifetime | Created | Destroyed | Use for |
|---|---|---|---|
| `Scope.singleton` | First resolution | App shutdown / `CubePod.reset()` | `ApiService`, `AuthManager`, `Logger` |
| `Scope.scoped` | First resolution in scope | Scope disposal | `HomeViewModel`, `CartService` |
| `Scope.factory` | Every `get()` call | Immediately (caller owns it) | Lightweight value objects |

### The Signal Engine

The reactive layer (`cubepod_state`) is built on three primitives:

- **`StateSignal<T>`** — a writable value that notifies listeners on change.
- **`ComputedSignal<T>`** — a lazily-evaluated, memoized derived value. Recomputes only when its upstream signals change.
- **`Effect`** — a side effect that re-runs whenever any signal it reads changes.

These three primitives compose into a push-based reactive graph. Updates propagate automatically; nothing needs to be told to refresh.

### Flutter Integration

`cubepod_flutter` connects the DI container to the widget tree:

- **`CubeScope`** — creates and owns a `CubeContainer` for its subtree.
- **`context.get<T>()`** — resolves from the nearest `CubeScope`, falling back to `CubePod.root`.
- **`CubeBuilder`** — subscribes to Signals with automatic dependency tracking.
- **`CubeListenableBuilder<T>`** — resolves a `ChangeNotifier` from the DI container and rebuilds on `notifyListeners()`.

---

## Design Decisions

### Why not use InheritedWidget for DI?

Standard `InheritedWidget` couples one type to one widget node in the tree. CubePod's container model allows many types to live in one scope node, and child scopes to selectively override any of them. This is closer to how real app modules are structured.

### Why not force ChangeNotifier everywhere?

`ChangeNotifier.notifyListeners()` rebuilds all subscribers, regardless of what changed. Signals rebuild only the widgets that read the changed value. Both models coexist in CubePod: use Signals when you want fine-grained reactivity, use `ChangeNotifier` ViewModels with `CubeListenableBuilder` when you prefer the familiar Flutter pattern.

### Why is everything explicit?

Hidden state is the primary source of Flutter bugs that are hard to reproduce. CubePod requires every dependency to be registered and every lifetime to be declared. This verbosity is intentional: it makes the application's dependency graph readable, testable, and refactorable without relying on reflection or code generation.

---

## What's Coming

The following packages are planned and will be added once the core is validated through external use:

- `cubepod_query` — async data fetching with caching and pagination
- `cubepod_network` — typed HTTP client with interceptors
- `cubepod_sync` — offline-first sync queue
- `cubepod_router` — declarative routing integrated with the DI container

---

*Built by [iamglitch404](https://github.com/iamglitch404).*

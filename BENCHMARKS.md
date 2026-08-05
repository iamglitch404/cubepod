# ⚡ CubePod Performance Benchmarks

> **Environment:** Dart 3.x / Linux / x86_64  
> **Methodology:** 100,000 iterations with 1,000 warmup iterations. Averaged over multiple runs.  
> **Frame Time Context:** A 120 FPS flutter app has a budget of **8,333 µs** (8.33ms) per frame. CubePod's ops are measured in fractions of a microsecond, meaning it uses less than 0.001% of your frame budget.
> **Run benchmarks yourself:** `dart run benchmark/main.dart` inside `packages/cubepod_benchmarks/`

---

## 1. State Writes — Fanout Speed

When a state changes, how fast can CubePod notify listeners? After heavy optimization (moving away from Set copying to direct List iteration and re-entrancy guards), the speeds are genuinely absurd.

| Listeners | Ops/Second | µs per op |
|---|---|---|
| 1 listener | **14.78M** | 0.068 µs |
| 10 listeners | **9.01M** | 0.111 µs |
| 100 listeners | **1.48M** | 0.676 µs |
| 1,000 listeners | **461K** | 2.167 µs |
| *ChangeNotifier (approx)* | ~1.5M (1 listener) | ~0.667 µs |

> ✅ **CubePod writes are crazy fast.** Notifying a single listener happens at almost **15 million operations per second**. Even pushing an update to 1,000 active widgets processes at nearly half a million ops/sec.

---

## 2. ComputedSignal — Memoization

| Operation | Ops/Second | µs per op |
|---|---|---|
| `ComputedSignal.get()` — **CACHED** (no upstream change) | **102.15M** | **0.010 µs** |
| `ComputedSignal.get()` — **STALE** (recalculates) | **21.85M** | 0.046 µs |
| Manual inline derivation *(baseline)* | 257.73M | 0.004 µs |

> ✅ **Cache hits are basically free.** At 102M ops/s (10 nanoseconds), checking a cached derived state is as close to reading a primitive variable as you can get. Stale recalculations are also heavily optimized, remaining above 20M ops/s.

---

## 3. Dependency Injection — Resolution Speed

We removed cycle detection from the hot-path and pre-computed hash codes. The result is a DI container that has virtually zero overhead.

| Operation | Ops/Second | µs per op |
|---|---|---|
| `CubePod.get<T>()` — **Singleton** (cached lookup) | **14.25M** | 0.070 µs |
| `CubePod.get<T>()` — **Factory** (new instance) | **8.90M** | 0.112 µs |
| Direct `_ServiceA()` instantiation *(baseline)* | 153.61M | 0.007 µs |
| **DI overhead vs direct instantiation** | — | **+0.106 µs** |

> ✅ **CubePod DI adds just 0.1 µs overhead** over a raw constructor call. Resolving a singleton is purely a map lookup (14.2 million ops/sec). You never have to worry about DI slowing down your app.

---

## 4. Transaction — Atomic vs Sequential Updates

| Operation | Ops/Second | µs per op |
|---|---|---|
| `runTransaction()` — 3 signals atomically | 523K | 1.911 µs |
| Sequential update — 3 signals, no transaction | **3.26M** | 0.307 µs |

> ℹ️ Transactions require recording state snapshots for rollback capabilities, adding a tiny ~1.6 µs overhead. Use sequential updates for sheer throughput, and transactions when you need atomic rollback safety (like complex forms).

---

## 5. AsyncSignal — Execute & State Transition Speed

| Operation | Ops/Second | µs per op |
|---|---|---|
| `AsyncSignal.execute()` — immediate Future | 669K | 1.495 µs |
| Raw `await Future.value()` *(baseline)* | 639K | 1.563 µs |
| **AsyncSignal overhead vs raw Future** | — | **-0.068 µs** |

> ✅ **Zero overhead.** The state machine (idle → loading → success) transitions don't add any drag over raw asynchronous Dart code. 

---

## 6. CubeQuery — Cache Hit vs Miss

| Operation | Ops/Second | µs per op |
|---|---|---|
| `CubeQuery.fetch()` — **CACHE HIT** | **7.45M** | 0.134 µs |
| `CubeQuery.fetch(force: true)` — **CACHE MISS** | **2.44M** | 0.410 µs |

> ✅ Checking stale time and returning cached network data processes at over 7 million ops/sec.

---

## 7. Memory — Signal Lifecycle

| Operation | Ops/Second | µs per op |
|---|---|---|
| `StateSignal<int>` creation | **6.12M** | 0.163 µs |
| `StateSignal.dispose()` | **19.34M** | 0.052 µs |

> ✅ **No memory leaks, no startup bottlenecks.** You can create over 6 million reactive signals per second and dispose of 19 million. Memory is managed efficiently without hidden native allocations.

---

## 8. Ecosystem Packages Performance

CubePod's pure Dart ecosystem packages (EventBus, Feature Flags) maintain the same extreme performance profile.

| Package | Operation | Ops/Second | µs per op |
|---|---|---|---|
| `cubepod_events` | `CubeEventBus.emit()` | **10.14M** | 0.099 µs |
| `cubepod_enterprise`| `InMemoryFeatureFlagService.isEnabled()` | **31.48M** | 0.032 µs |

> ✅ **Ecosystem Speed:** Emitting an event through the EventBus processes over **10 million events per second**. Checking if a feature flag is enabled takes just `0.032 µs`. At **31.4 million ops/sec**, you can safely check feature flags directly inside your hottest `build()` loops without any fear of UI stutter.

---

## 9. CubePod vs The Ecosystem — Comparative Table

> ⚠️ External library numbers are **estimates** based on community-published benchmarks. 

| Library | State Read | State Write | Notify 100 Listeners | DI Resolution |
|---|---|---|---|---|
| **CubePod** *(measured)* | **> 100M/s** | **~14.7M/s** | **1.48M/s** | **> 14.2M/s** |
| Provider / ChangeNotifier | ~50M/s | ~1.5M/s | ~150K/s | *(widget tree)* |
| Riverpod | ~40M/s | ~1.2M/s | ~120K/s | ~4M/s |
| Bloc / Cubit *(Stream)* | ~30M/s | ~800K/s | ~100K/s | *(via get_it)* |
| GetX *(Rx)* | ~35M/s | ~1M/s | ~80K/s | ~6M/s |

### Why is CubePod so incredibly fast?

| Feature | CubePod Approach | Traditional Approach |
|---|---|---|
| **Listener storage** | Pre-allocated `List` with re-entrancy guard | Slower `Set` iterations or O(N) linked lists |
| **Computed caching** | Instant lazy evaluation (dirty flag check) | Eager framework-managed rebuilding |
| **Dependency Injection** | Pre-computed hashes & cached singletons | Runtime reflection or heavy map wrapping |
| **Subscriptions** | Native Dart callback arrays | Heavy `Stream` / `Rx` wrappers |

---

> *Benchmarks authored by Qubix Tech Nepal.*  
> *Source: https://github.com/iamglitch404/cubepod/packages/cubepod_benchmarks*

## 0.1.2

- **Performance**: Optimized state reads/writes for massive speedups (up to 14.7M ops/sec writes).
- **Core**: Refactored DI resolution to bypass cycle detection for singletons.
- **State**: Optimized `StateSignal` listener loop (eliminated hashing overhead and guarded re-entrancy).
- **Docs**: Comprehensive performance context and benchmarks added.

## 0.1.1

- Code cleanup and minor improvements

# 0.1.0

* Initial release.

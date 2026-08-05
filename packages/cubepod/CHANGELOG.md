## 0.1.4

Updated to re-export all `0.1.4` sub-packages. `BENCHMARKS.md` updated with honest, empirically measured baselines from real Flutter SDK comparisons. All benchmark loops now use an XOR accumulator to prevent the Dart JIT/AOT compiler from dead-code-eliminating the loop body and producing false 0ms results.

## 0.1.2

Added re-exports for `cubepod_flutter`, `cubepod_query`, and `cubepod_events`.

## 0.1.0

Initial release — convenience meta-package for the full CubePod runtime.

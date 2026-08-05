## 0.1.4

Fixed a bug where starting a new `AsyncSignal.execute()` while a previous execution was still in-flight would not cancel the previous future's state transitions. The in-flight future would still resolve and overwrite the state of the new execution. Added a generation counter to gate stale resolutions.

Also fixed a subtle issue where calling `execute()` after a previous error didn't reset the error field before transitioning to loading, so the old error was briefly visible alongside the new loading state.

## 0.1.2

Added configurable retry logic to `AsyncSignal`. Added `cancelOnNewExecution` option.

## 0.1.0

Initial release with `AsyncSignal` state machine (idle → loading → data/error).

## 0.1.4

Fixed a race condition in task cancellation — if a task completed in the same microtask as `cancel()`, the completion callback would still fire. Added a priority queue so higher-priority tasks are always scheduled ahead of lower-priority ones in the same tick.

## 0.1.2

Added recurring task scheduling with configurable intervals. Added `CubeScheduler.runAfterDelay()`.

## 0.1.0

Initial release with `CubeScheduler`.

## 0.1.5

- Synchronized version to 0.1.5 for Alpha release preparation.

## 0.1.4

Fixed a memory leak in the navigation guard system — when a guard returned `false` and the route was never pushed, the associated route state object was not cleaned up. Also added typed route parameter extraction helpers.

## 0.1.2

Added navigation guards (async predicates that can block or redirect navigation). Added route middleware for cross-cutting concerns.

## 0.1.0

Initial release with `CubeRouter`.

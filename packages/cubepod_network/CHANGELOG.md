## 0.1.4

Fixed error state propagation — network errors are now forwarded through the reactive signal pipeline correctly instead of being swallowed at the HTTP adapter layer. Added request deduplication: concurrent identical GET requests share a single in-flight future.

## 0.1.2

Added request/response interceptor support to the HTTP client. Added timeout configuration.

## 0.1.0

Initial release with CubePod networking layer.

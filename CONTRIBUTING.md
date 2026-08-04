# Contributing to CubePod

Thank you for your interest in contributing to **CubePod — The Operating System for Flutter Applications**!

## 📋 Before You Start

1. **Search for existing issues** before opening a new one.
2. **Discuss large changes** in a GitHub Discussion or issue before submitting a PR.
3. **One PR per feature** — keep changes focused.

## 🏗 Project Structure

```
cubepod/
├── packages/
│   ├── cubepod_core/           # DI, Scopes, Lifecycle
│   ├── cubepod_state/          # Signals, Forms, Transactions
│   ├── cubepod_flutter/        # CubeBuilder, CubeSelector, CubeListener
│   ├── cubepod_async/          # AsyncSignal, StreamSignal, Retry
│   ├── cubepod_query/          # CubeQuery, CubePaginatedQuery
│   ├── cubepod_events/         # EventBus, StateMachine, Actor
│   ├── cubepod_network/        # HttpApiClient, Interceptors
│   ├── cubepod_storage/        # MemoryStorage, PersistedSignal
│   ├── cubepod_sync/           # Offline SyncQueue
│   ├── cubepod_router/         # Typed routing
│   ├── cubepod_testing/        # MockContainer, TestObserver
│   ├── cubepod_enterprise/     # TenantConfig, FeatureFlags
│   ├── cubepod_resources/      # Resource lifecycle
│   └── cubepod_scheduler/      # Task scheduling
└── examples/
```

## 🔧 Setup

```bash
# Clone the repo
git clone https://github.com/iamglitch404/cubepod.git
cd cubepod

# Install Melos globally
dart pub global activate melos

# Bootstrap all packages
melos bootstrap
```

## 🧪 Running Tests

```bash
# Run all tests across all packages
melos run test

# Run tests for a specific package
cd packages/cubepod_state && dart test
cd packages/cubepod_flutter && flutter test
```

## 📐 Code Style

- Follow official [Dart style guide](https://dart.dev/guides/language/effective-dart/style).
- Run `dart format .` before committing.
- Run `dart analyze` and fix all warnings/errors.
- All public APIs **must have doc comments**.
- All new features **must have unit tests**.

## 🚀 Submitting a Pull Request

1. Fork the repository.
2. Create a feature branch: `git checkout -b feat/my-feature`.
3. Write tests for your changes.
4. Run `dart format .` and `dart analyze`.
5. Commit with a clear message: `feat(cubepod_state): add batch signal updates`.
6. Push to your fork and open a PR against `main`.

## 📦 Publishing

Only maintainers from **Qubix Tech Nepal** can publish packages to `pub.dev`.
To publish all packages:
```bash
melos publish
```

## ❤️ Code of Conduct

Be kind and respectful. We welcome contributors of all experience levels.

# cubepod_query

Async data fetching for CubePod — like TanStack Query but for Flutter. Handles caching, background refresh, pagination, and optimistic updates automatically.

## What's inside

- **`CubeQuery<T>`** — fetches and caches a single resource
- **`CubePaginatedQuery<T>`** — paginated data with `fetchNextPage()` support
- **Automatic cache invalidation** — stale-while-revalidate by default

## Install

```yaml
dependencies:
  cubepod_query: ^0.1.1
```

## Usage

```dart
import 'package:cubepod_query/cubepod_query.dart';

final userQuery = CubeQuery<User>(
  key: 'user-profile',
  fetcher: () => api.getUser(),
  staleTime: Duration(minutes: 5),
);

// In your widget
CubeBuilder<QueryState<User>>(
  signal: userQuery.state,
  builder: (context, state) {
    if (state.isLoading) return CircularProgressIndicator();
    if (state.hasError) return Text('Error: ${state.error}');
    return Text(state.data!.name);
  },
);
```

See [cubepod](https://pub.dev/packages/cubepod) for the full docs.

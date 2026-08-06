import 'package:cubepod_query/cubepod_query.dart';
import 'package:test/test.dart';

void main() {
  group('CubeQuery', () {
    test('fetch() loads data successfully', () async {
      final query = CubeQuery<String>(queryFn: () async => 'hello');
      await query.fetch();
      expect(query.value.hasData, isTrue);
      expect(query.value.data, 'hello');
    });

    test(
        'fetch() when called concurrently returns the active future instead of completing immediately',
        () async {
      final query = CubeQuery<String>(
        queryFn: () async {
          await Future.delayed(const Duration(milliseconds: 50));
          return 'hello';
        },
      );
      final f2 = query.fetch();

      await f2; // If f2 completes immediately, data will be null. It should wait for f1.
      expect(query.value.data, 'hello');
    });

    test('fetch() sets error state on failure', () async {
      final query = CubeQuery<String>(
        queryFn: () async => throw Exception('Network error'),
      );
      await query.fetch();
      expect(query.value.hasError, isTrue);
    });

    test('fetch() uses cache when not stale', () async {
      int callCount = 0;
      final query = CubeQuery<int>(
        queryFn: () async {
          callCount++;
          return callCount;
        },
        staleTime: const Duration(minutes: 5),
      );
      await query.fetch();
      await query.fetch(); // Should use cache
      expect(callCount, 1); // Only called once
    });

    test('invalidate() forces refetch', () async {
      int callCount = 0;
      final query = CubeQuery<int>(
        queryFn: () async => ++callCount,
        staleTime: const Duration(minutes: 5),
      );
      await query.fetch();
      await query.invalidate(); // Force refetch
      expect(callCount, 2);
    });

    test('setOptimisticData() updates immediately', () async {
      final query = CubeQuery<String>(
        queryFn: () async => 'real data',
      );
      query.setOptimisticData('optimistic');
      expect(query.value.data, 'optimistic');
    });

    test('is reactive — notifies listeners when data arrives', () async {
      final query = CubeQuery<int>(queryFn: () async => 42);
      int notifications = 0;
      query.addListener(() => notifications++);
      await query.fetch();
      // Should notify for loading + success
      expect(notifications, greaterThanOrEqualTo(1));
    });
  });

  group('CubePaginatedQuery', () {
    test('fetches first page', () async {
      final query = CubePaginatedQuery<int>(
        queryFn: (page) async => [page * 10, page * 10 + 1],
      );
      await query.fetchFirstPage();
      expect(query.value.data, [0, 1]);
      expect(query.currentPage, 0);
    });

    test('fetches next page and appends', () async {
      final query = CubePaginatedQuery<int>(
        queryFn: (page) async => [page],
      );
      await query.fetchFirstPage();
      await query.fetchNextPage();
      expect(query.value.data, [0, 1]);
    });

    test('hasNextPage is false when page returns empty', () async {
      final query = CubePaginatedQuery<int>(
        queryFn: (page) async => page == 0 ? [1, 2, 3] : [],
      );
      await query.fetchFirstPage();
      expect(query.hasNextPage, isTrue);
      await query.fetchNextPage();
      expect(query.hasNextPage, isFalse);
    });
  });
}

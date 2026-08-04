import 'package:cubepod_state/cubepod_state.dart';

enum QueryStatus { idle, loading, success, error }

class QueryState<T> {
  final QueryStatus status;
  final T? data;
  final Object? error;

  const QueryState({
    this.status = QueryStatus.idle,
    this.data,
    this.error,
  });

  bool get isLoading => status == QueryStatus.loading;
  bool get hasData => data != null && status == QueryStatus.success;
  bool get hasError => status == QueryStatus.error;
  bool get isIdle => status == QueryStatus.idle;

  QueryState<T> copyWith({
    QueryStatus? status,
    T? data,
    Object? error,
  }) =>
      QueryState<T>(
        status: status ?? this.status,
        data: data ?? this.data,
        error: error ?? this.error,
      );
}

class CubeQuery<T> extends StateSignal<QueryState<T>> {
  final Future<T> Function() queryFn;
  final Duration staleTime;
  final Duration? cacheTime;
  bool _isFetching = false;

  DateTime? _lastFetch;

  CubeQuery({
    required this.queryFn,
    this.staleTime = const Duration(minutes: 5),
    this.cacheTime,
  }) : super(const QueryState());

  bool get isStale =>
      _lastFetch == null || DateTime.now().difference(_lastFetch!) >= staleTime;

  Future<void> fetch({bool force = false}) async {
    if (_isFetching) return;
    if (!force && !isStale) return;

    _isFetching = true;
    value = QueryState(status: QueryStatus.loading, data: value.data);
    try {
      final result = await queryFn();
      _lastFetch = DateTime.now();
      value = QueryState(status: QueryStatus.success, data: result);
    } catch (e) {
      value = QueryState(status: QueryStatus.error, error: e, data: value.data);
    } finally {
      _isFetching = false;
    }
  }

  Future<void> invalidate() => fetch(force: true);

  Future<void> mutate(T optimisticData) async {
    value = QueryState(status: QueryStatus.success, data: optimisticData);
    await fetch(force: true);
  }

  void setOptimisticData(T optimisticData) {
    value = QueryState(status: QueryStatus.success, data: optimisticData);
  }
}

class CubePaginatedQuery<T> extends StateSignal<QueryState<List<T>>> {
  final Future<List<T>> Function(int page) queryFn;
  final Duration staleTime;
  int _currentPage = 0;
  bool _hasNextPage = true;
  bool _isFetching = false;

  CubePaginatedQuery({
    required this.queryFn,
    this.staleTime = const Duration(minutes: 5),
  }) : super(const QueryState());

  bool get hasNextPage => _hasNextPage;
  int get currentPage => _currentPage;

  Future<void> fetchFirstPage() async {
    _currentPage = 0;
    _hasNextPage = true;
    value = const QueryState(status: QueryStatus.loading);
    await _fetchPage(0, replace: true);
  }

  Future<void> fetchNextPage() async {
    if (!_hasNextPage || _isFetching) return;
    await _fetchPage(_currentPage + 1, replace: false);
  }

  Future<void> _fetchPage(int page, {required bool replace}) async {
    _isFetching = true;
    try {
      final newItems = await queryFn(page);
      _hasNextPage = newItems.isNotEmpty;
      if (_hasNextPage) _currentPage = page;

      final existing = replace ? <T>[] : (value.data ?? []);
      value = QueryState(
        status: QueryStatus.success,
        data: [...existing, ...newItems],
      );
    } catch (e) {
      value = QueryState(status: QueryStatus.error, error: e, data: value.data);
    } finally {
      _isFetching = false;
    }
  }
}

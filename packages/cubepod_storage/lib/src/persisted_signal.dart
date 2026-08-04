import 'package:cubepod_state/cubepod_state.dart';
import 'storage_service.dart';

class PersistedSignal<T> extends StateSignal<T> {
  final String key;
  final StorageService _storage;
  final String Function(T) _serialize;
  final T Function(String) _deserialize;
  Effect? _persistEffect;

  PersistedSignal({
    required this.key,
    required T initialValue,
    required StorageService storage,
    String Function(T value)? serialize,
    T Function(String stored)? deserialize,
  })  : _storage = storage,
        _serialize = serialize ?? ((v) => v.toString()),
        _deserialize = deserialize ?? ((s) => s as T),
        super(initialValue);

  Future<void> hydrate() async {
    final stored = _storage.getString(key);
    if (stored != null) {
      try {
        setValueWithoutRecording(_deserialize(stored));
      } catch (_) {
        // If deserialization fails, keep initial value
      }
    }
    // Start auto-persisting on every change (and dispose the effect properly)
    _persistEffect?.dispose();
    _persistEffect = effect(() {
      _storage.setString(key, _serialize(value));
    });
  }

  @override
  void dispose() {
    _persistEffect?.dispose();
    _persistEffect = null;
    super.dispose();
  }
}

/// A key-value storage abstraction for persisting data locally.
abstract class StorageService {
  Future<void> init();
  Future<void> setString(String key, String value);
  String? getString(String key);
  Future<void> remove(String key);
  Future<void> clear();
}

class MemoryStorage implements StorageService {
  final Map<String, String> _data = {};

  @override
  Future<void> init() async {}

  @override
  Future<void> setString(String key, String value) async {
    _data[key] = value;
  }

  @override
  String? getString(String key) => _data[key];

  @override
  Future<void> remove(String key) async {
    _data.remove(key);
  }

  @override
  Future<void> clear() async {
    _data.clear();
  }
}

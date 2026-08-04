import 'package:shared_preferences/shared_preferences.dart';
import 'storage_service.dart';

class SharedPreferencesStorage implements StorageService {
  SharedPreferences? _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  void _checkInit() {
    if (_prefs == null) {
      throw StateError(
          'SharedPreferencesStorage must be initialized before use. Call init().');
    }
  }

  @override
  Future<void> setString(String key, String value) async {
    _checkInit();
    await _prefs!.setString(key, value);
  }

  @override
  String? getString(String key) {
    _checkInit();
    return _prefs!.getString(key);
  }

  @override
  Future<void> remove(String key) async {
    _checkInit();
    await _prefs!.remove(key);
  }

  @override
  Future<void> clear() async {
    _checkInit();
    await _prefs!.clear();
  }
}

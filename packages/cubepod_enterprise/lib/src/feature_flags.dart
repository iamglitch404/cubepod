/// An enterprise abstraction for resolving remote feature flags.
abstract class FeatureFlagService {
  bool isEnabled(String featureKey, {bool defaultValue = false});
  Future<void> fetchFlags();
}

class InMemoryFeatureFlagService implements FeatureFlagService {
  final Map<String, bool> _flags = {};

  void setFlag(String key, bool value) {
    _flags[key] = value;
  }

  @override
  bool isEnabled(String featureKey, {bool defaultValue = false}) {
    return _flags[featureKey] ?? defaultValue;
  }

  @override
  Future<void> fetchFlags() async {
    // Enterprise implementations would fetch from LaunchDarkly etc.
  }
}

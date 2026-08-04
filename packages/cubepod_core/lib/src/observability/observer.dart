abstract class CubeObserver {
  void onSignalCreated(String id, dynamic value);
  void onSignalUpdated(String id, dynamic value, dynamic previousValue);
  void onDependencyRegistered(Type type, dynamic instance);
  void onDependencyResolved(Type type, dynamic instance);
  void onDependencyDisposed(Type type, dynamic instance);
}

class CubeDevToolsObserver implements CubeObserver {
  static CubeObserver? instance;

  @override
  void onDependencyDisposed(Type type, dynamic instance) {
    CubeDevToolsObserver.instance?.onDependencyDisposed(type, instance);
  }

  @override
  void onDependencyRegistered(Type type, dynamic instance) {
    CubeDevToolsObserver.instance?.onDependencyRegistered(type, instance);
  }

  @override
  void onDependencyResolved(Type type, dynamic instance) {
    CubeDevToolsObserver.instance?.onDependencyResolved(type, instance);
  }

  @override
  void onSignalCreated(String id, dynamic value) {
    CubeDevToolsObserver.instance?.onSignalCreated(id, value);
  }

  @override
  void onSignalUpdated(String id, dynamic value, dynamic previousValue) {
    CubeDevToolsObserver.instance?.onSignalUpdated(id, value, previousValue);
  }
}

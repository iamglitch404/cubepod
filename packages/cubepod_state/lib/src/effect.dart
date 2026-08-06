part of 'signal.dart';

/// Runs [fn] immediately and re-runs it whenever any of its tracked signal
/// dependencies change.
///
/// Call [dispose] to stop all re-runs and release all upstream references.
class Effect implements SignalObserver {
  final void Function() _effect;
  bool _isDisposed = false;

  // Every signal accessed during the last run is tracked here. On each re-run,
  // the set is cleared and rebuilt from scratch so stale dependencies are
  // automatically pruned (avoids phantom subscriptions).
  final Set<Signal<dynamic>> _dependencies = {};

  Effect(this._effect) {
    _run();
  }

  @override
  bool get requiresImmediateInvalidation => false;

  @override
  String toString() => 'Effect(dependencies: ${_dependencies.length})';

  void _run() {
    if (_isDisposed) return;

    // Unregister from all previous dependencies before re-tracking.
    // This prunes signals that are no longer accessed in the new run.
    for (final dep in _dependencies) {
      dep.removeObserver(this);
    }
    _dependencies.clear();

    final prevObserver = _currentObserver;
    _currentObserver = this;
    try {
      _effect();
    } catch (e, stack) {
      // Forward to the configurable handler — exceptions in effects should
      // never be silent, and should never prevent future re-runs.
      SignalConfig.errorHandler(e, stack);
    } finally {
      // Always restore outer observer, even on exception.
      _currentObserver = prevObserver;
    }
  }

  @override
  void trackDependency(Signal<dynamic> signal) {
    _dependencies.add(signal);
  }

  @override
  void onDependencyChanged() {
    if (!_isDisposed) _run();
  }

  void dispose() {
    if (_isDisposed) return;
    _isDisposed = true;
    // Proactively remove this effect from every upstream signal's observer list
    // so the effect is immediately eligible for garbage collection.
    for (final dep in _dependencies) {
      dep.removeObserver(this);
    }
    _dependencies.clear();
  }
}

/// Convenience constructor for creating an [Effect].
///
/// Returns the [Effect] instance so it can be disposed later.
Effect effect(void Function() fn) => Effect(fn);

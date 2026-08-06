/// The dependency lifetime for a registered type.
///
/// Pass [scope] to [CubeContainer.register] or [CubePod.register] to control
/// how many instances are created and how long they live.
enum Scope {
  /// A single instance shared across the entire application.
  ///
  /// The instance is created on the first [CubeContainer.get] call and
  /// reused for every subsequent call, regardless of which container or
  /// scope performs the resolution. Singletons are disposed when the root
  /// container is disposed (i.e., on [CubePod.reset]).
  singleton,

  /// A new instance created on every [CubeContainer.get] call.
  ///
  /// Instances are never cached. Use this for lightweight, stateless objects
  /// or when you need a fresh instance for each consumer.
  ///
  /// This is the default scope.
  factory,

  /// One instance per [CubeContainer] scope.
  ///
  /// All calls to [CubeContainer.get] within the same container return the
  /// same instance, but different containers each receive their own instance.
  /// The instance is disposed when the container is disposed.
  ///
  /// Ideal for screen-level or feature-level state that should be shared
  /// within a bounded context but isolated from sibling contexts.
  scoped,
}

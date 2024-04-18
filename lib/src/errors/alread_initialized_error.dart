/// An error indicating that an attempt was made to initialize an object that has already been initialized.
///
/// This error is typically thrown in singleton or other similar design patterns where an object's initialization
/// is meant to occur only once during the application lifecycle. It prevents multiple initializations
/// which could lead to inconsistent states or overwrite important setup configurations.
///
/// Example usage:
/// ```dart
/// if (_isInitialized) {
///   throw AlreadyInitializedError();
/// }
/// ```
class AlreadyInitializedError extends Error {
  /// Creates an instance of `AlreadyInitializedError`.
  ///
  /// This constructor can be invoked when an object is being initialized for the second time,
  /// violating the initialization rules typically enforced in singletons or similar patterns.
  AlreadyInitializedError();

  @override
  String toString() {
    return 'Attempted to initialize an object that has already been initialized.';
  }
}

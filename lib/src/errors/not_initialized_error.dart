/// An error indicating that an attempt was made to use an object that has not yet been initialized.
///
/// This error is thrown in scenarios where certain methods or properties of an object are accessed
/// before the object has gone through its necessary initialization process. This ensures that
/// all components are properly set up before use, preventing runtime failures due to uninitialized state.
///
/// Example usage:
/// ```dart
/// if (!_isInitialized) {
///   throw NotInitializedError();
/// }
/// ```
class NotInitializedError extends Error {
  /// Creates an instance of `NotInitializedError`.
  ///
  /// This constructor can be invoked when an object's methods or properties are accessed before
  /// the object has been properly initialized, typically in a scenario where initialization is required
  /// before usage.
  NotInitializedError();

  @override
  String toString() {
    return 'Attempted to use an object that has not been initialized.';
  }
}

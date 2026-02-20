/// Validates that a numeric field is at least [value].
///
/// ```dart
/// @Min(0)
/// final int quantity;
///
/// @Min(18, message: 'Must be 18 or older')
/// final int age;
/// ```
class Min {
  /// The minimum allowed value.
  final num value;

  /// Custom error message. If null, a default message is used.
  final String? message;

  /// Creates a [Min] annotation requiring at least [value].
  const Min(this.value, {this.message});
}

/// Validates that a numeric field is at most [value].
///
/// ```dart
/// @Max(100)
/// final int percentage;
///
/// @Max(150, message: 'Weight cannot exceed 150 kg')
/// final double weight;
/// ```
class Max {
  /// The maximum allowed value.
  final num value;

  /// Custom error message. If null, a default message is used.
  final String? message;

  /// Creates a [Max] annotation allowing at most [value].
  const Max(this.value, {this.message});
}

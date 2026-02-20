/// Validates that a string field has at most [length] characters.
///
/// ```dart
/// @MaxLength(100)
/// final String bio;
///
/// @MaxLength(50, message: 'Name is too long')
/// final String name;
/// ```
class MaxLength {
  /// The maximum number of characters allowed.
  final int length;

  /// Custom error message. If null, a default message is used.
  final String? message;

  /// Creates a [MaxLength] annotation allowing at most [length] characters.
  const MaxLength(this.length, {this.message});
}

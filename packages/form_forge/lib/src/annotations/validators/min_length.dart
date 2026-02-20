/// Validates that a string field has at least [length] characters.
///
/// ```dart
/// @MinLength(8)
/// final String password;
///
/// @MinLength(2, message: 'Name must be at least 2 characters')
/// final String name;
/// ```
class MinLength {
  /// The minimum number of characters required.
  final int length;

  /// Custom error message. If null, a default message is used.
  final String? message;

  /// Creates a [MinLength] annotation requiring at least [length] characters.
  const MinLength(this.length, {this.message});
}

/// Validates that a string field matches the given regular expression [pattern].
///
/// ```dart
/// @PatternValidator(r'^[a-zA-Z]+$')
/// final String name;
///
/// @PatternValidator(r'^\d{5}$', message: 'Must be a 5-digit zip code')
/// final String zipCode;
/// ```
class PatternValidator {
  /// The regular expression pattern to match against.
  final String pattern;

  /// Custom error message. If null, a default message is used.
  final String? message;

  /// Creates a [PatternValidator] annotation matching [pattern].
  const PatternValidator(this.pattern, {this.message});
}

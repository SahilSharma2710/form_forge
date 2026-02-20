/// Validates that this field's value matches another field's value.
///
/// Used for cross-field validation such as confirm-password checks.
///
/// ```dart
/// @IsRequired()
/// final String password;
///
/// @IsRequired()
/// @MustMatch('password')
/// final String confirmPassword;
/// ```
class MustMatch {
  /// The name of the other field that this field must match.
  final String field;

  /// Custom error message. If null, a default message is used.
  final String? message;

  /// Creates a [MustMatch] annotation referencing [field].
  const MustMatch(this.field, {this.message});
}

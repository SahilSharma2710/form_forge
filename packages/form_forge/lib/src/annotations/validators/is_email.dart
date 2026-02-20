/// Validates that a field contains a valid email address.
///
/// ```dart
/// @IsEmail()
/// final String email;
///
/// @IsEmail(message: 'Please enter a valid email')
/// final String contactEmail;
/// ```
class IsEmail {
  /// Custom error message. If null, a default message is used.
  final String? message;

  /// Creates an [IsEmail] annotation with an optional custom [message].
  const IsEmail({this.message});
}

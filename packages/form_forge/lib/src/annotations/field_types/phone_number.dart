/// Marks a field as a phone number input.
///
/// The generated form will render a phone number input with appropriate
/// keyboard type, formatting, and optional validation.
///
/// ```dart
/// @PhoneNumber()
/// late final String phone;
///
/// @PhoneNumber(message: 'Please enter a valid phone number')
/// late final String mobile;
/// ```
class PhoneNumber {
  /// Custom error message for invalid phone numbers.
  final String? message;

  /// Creates a [PhoneNumber] annotation with optional custom [message].
  const PhoneNumber({this.message});
}

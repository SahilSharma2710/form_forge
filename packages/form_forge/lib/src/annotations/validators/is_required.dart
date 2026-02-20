/// Marks a field as required.
///
/// When applied, the generated form will validate that this field
/// has a non-null, non-empty value.
///
/// ```dart
/// @IsRequired()
/// final String name;
///
/// @IsRequired(message: 'Email is required')
/// final String email;
/// ```
class IsRequired {
  /// Custom error message. If null, a default message is used.
  final String? message;

  /// Creates an [IsRequired] annotation with an optional custom [message].
  const IsRequired({this.message});
}

/// Interface for creating custom validators that integrate with
/// form_forge's validation pipeline.
///
/// Implement this class to create domain-specific validators that
/// can be used as annotations on form fields.
///
/// ```dart
/// class IsPhoneNumber extends FormForgeValidator {
///   const IsPhoneNumber();
///
///   @override
///   String? validate(dynamic value) {
///     if (value is! String) return 'Invalid type';
///     final pattern = RegExp(r'^\+?[\d\s-]{10,}$');
///     return pattern.hasMatch(value) ? null : 'Invalid phone number';
///   }
/// }
///
/// // Usage:
/// @IsPhoneNumber()
/// final String phone;
/// ```
abstract class FormForgeValidator {
  /// Creates a [FormForgeValidator]. Must be const-constructible
  /// for use as an annotation.
  const FormForgeValidator();

  /// Validates the given [value] and returns `null` if valid,
  /// or an error message string if invalid.
  String? validate(dynamic value);
}

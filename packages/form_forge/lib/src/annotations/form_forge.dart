/// Annotation that marks a Dart class as a form definition.
///
/// When applied to a class, the form_forge code generator will produce
/// a `FormController` and `FormWidget` for that class.
///
/// ```dart
/// @FormForge()
/// class LoginForm {
///   @IsRequired()
///   @IsEmail()
///   final String email;
///
///   @IsRequired()
///   @MinLength(8)
///   final String password;
/// }
/// ```
///
/// To enable form state persistence to SharedPreferences, provide a
/// [persistKey]:
///
/// ```dart
/// @FormForge(persistKey: 'user_registration')
/// class RegistrationForm {
///   // Fields will be automatically saved and restored
/// }
/// ```
class FormForge {
  /// Optional key for SharedPreferences persistence.
  ///
  /// When provided, the form state will be automatically saved to
  /// SharedPreferences and restored when the form is rebuilt.
  final String? persistKey;

  /// Creates a [FormForge] annotation with optional [persistKey] for persistence.
  const FormForge({this.persistKey});
}

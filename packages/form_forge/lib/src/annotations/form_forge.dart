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
class FormForge {
  /// Creates a [FormForge] annotation.
  const FormForge();
}

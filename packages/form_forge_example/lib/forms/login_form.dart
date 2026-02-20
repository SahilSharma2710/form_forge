import 'package:form_forge/form_forge.dart';

/// Simple login form demonstrating basic validation.
///
/// Run `dart run build_runner build` to generate:
/// - `LoginFormFormController` — manages field state and validation
/// - `LoginFormFormWidget` — renders the form UI
/// - `LoginFormFormData` — typed submission data
@FormForge()
class LoginForm {
  @IsRequired()
  @IsEmail()
  late final String email;

  @IsRequired()
  @MinLength(8)
  late final String password;
}

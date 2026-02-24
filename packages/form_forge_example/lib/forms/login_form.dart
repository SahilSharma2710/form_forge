import 'package:form_forge/form_forge.dart';

part 'login_form.g.dart';

/// Simple login form demonstrating basic validation.
///
/// Run `dart run build_runner build` to generate:
/// - `LoginFormController` — manages field state and validation
/// - `LoginFormWidget` — renders the form UI
/// - `LoginFormData` — typed submission data
@FormForge()
class LoginForm {
  @IsRequired()
  @IsEmail()
  late final String email;

  @IsRequired()
  @MinLength(8)
  late final String password;
}

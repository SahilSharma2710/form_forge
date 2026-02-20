import 'package:form_forge/form_forge.dart';

/// Signup form demonstrating cross-field and async validation.
///
/// Features:
/// - `@MustMatch` for confirm password
/// - `@AsyncValidate` for server-side email uniqueness check
/// - Multiple validators per field
@FormForge()
class SignUpForm {
  @IsRequired(message: 'Please enter your name')
  @MinLength(2)
  late final String name;

  @IsRequired()
  @IsEmail()
  @AsyncValidate()
  late final String email;

  @IsRequired()
  @MinLength(8, message: 'Password must be at least 8 characters')
  late final String password;

  @IsRequired()
  @MustMatch('password', message: 'Passwords do not match')
  late final String confirmPassword;
}

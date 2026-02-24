// ignore_for_file: unused_local_variable
import 'package:form_forge/form_forge.dart';

// ──────────────────────────────────────────────
// 1. Define your form with annotations
// ──────────────────────────────────────────────

@FormForge()
class LoginForm {
  @IsRequired()
  @IsEmail()
  late final String email;

  @IsRequired()
  @MinLength(8)
  late final String password;
}

// ──────────────────────────────────────────────
// 2. Run code generation
//
//    dart run build_runner build
//
// This generates:
//   - LoginFormController (typed fields, validation, submission)
//   - LoginFormWidget     (drop-in widget with error display)
//   - LoginFormData       (typed data class for submission)
// ──────────────────────────────────────────────

// ──────────────────────────────────────────────
// 3. Advanced example — signup with cross-field
//    and async validation
// ──────────────────────────────────────────────

@FormForge()
class SignUpForm {
  @IsRequired(message: 'Please enter your name')
  @MinLength(2)
  late final String name;

  @IsRequired()
  @IsEmail()
  @AsyncValidate(debounceMs: 500)
  late final String email;

  @IsRequired()
  @MinLength(8, message: 'Password must be at least 8 characters')
  late final String password;

  @IsRequired()
  @MustMatch('password', message: 'Passwords do not match')
  late final String confirmPassword;

  @Min(18, message: 'Must be at least 18')
  @Max(120)
  late final int age;
}

// ──────────────────────────────────────────────
// 4. Use the generated code
// ──────────────────────────────────────────────

/// Example showing how to use the generated controller.
///
/// ```dart
/// final controller = LoginFormController();
///
/// // Drop-in widget
/// LoginFormWidget(controller: controller)
///
/// // Programmatic access
/// controller.email.value = 'user@example.com';
/// controller.password.value = 'secret123';
/// controller.validateAll();
/// print(controller.isValid); // true
///
/// // Submit with typed data
/// await controller.submit((data) async {
///   print(data.email);
///   print(data.password);
/// });
///
/// // Register async validators at runtime
/// final signUpController = SignUpFormController();
/// signUpController.registerAsyncValidator('email', (value) async {
///   final exists = await checkEmailOnServer(value as String);
///   return exists ? 'Email already taken' : null;
/// });
/// ```
void example() {}

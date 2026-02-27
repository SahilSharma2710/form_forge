// Add form_forge and form_forge_generator to your pubspec.yaml:
//
// dependencies:
//   form_forge: ^1.0.0
//
// dev_dependencies:
//   form_forge_generator: ^1.0.0
//   build_runner: ^2.4.0
//
// Then annotate your form class:

import 'package:form_forge/form_forge.dart';

part 'example.g.dart';

@FormForge()
class LoginForm {
  @IsRequired(message: 'Email is required')
  @IsEmail()
  late final String email;

  @IsRequired()
  @MinLength(8)
  late final String password;
}

// Run: dart run build_runner build
// This generates LoginFormWidget and LoginFormController in example.g.dart

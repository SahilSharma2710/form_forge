# form_forge

Code-generation powered form engine for Flutter. Define your model, annotate, and let form_forge generate type-safe forms with validation, async checks, and cross-field rules. **The freezed of forms.**

## Before & After

**Without form_forge** — 87 lines for a login form:

```dart
class LoginPage extends StatefulWidget { /* ... */ }
class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  String? _emailError;
  String? _passwordError;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _emailError = _emailController.text.isEmpty ? 'Required' : null;
      if (_emailError == null && !_emailController.text.contains('@')) {
        _emailError = 'Invalid email';
      }
      _passwordError = _passwordController.text.length < 8
          ? 'Must be at least 8 characters' : null;
    });
  }

  // ... build method with Form, TextFormField, error handling, submission ...
}
```

**With form_forge** — 12 lines:

```dart
@FormForge()
class LoginForm {
  @IsRequired()
  @IsEmail()
  final String email;

  @IsRequired()
  @MinLength(8)
  final String password;
}
```

Run `dart run build_runner build` and you get:
- `LoginFormController` — typed field access, validation, submission
- `LoginFormWidget` — drop-in widget with error display
- `LoginFormData` — typed data class for submission

## Installation

```yaml
dependencies:
  form_forge: ^0.1.1

dev_dependencies:
  form_forge_generator: ^0.1.1
  build_runner: ^2.4.0
```

## Quick Start

### 1. Define your form

```dart
import 'package:form_forge/form_forge.dart';

@FormForge()
class SignUpForm {
  @IsRequired()
  @IsEmail()
  final String email;

  @IsRequired()
  @MinLength(8)
  final String password;

  @IsRequired()
  @MustMatch('password')
  final String confirmPassword;
}
```

### 2. Generate

```bash
dart run build_runner build
```

### 3. Use

```dart
final controller = SignUpFormController();

// Drop-in widget
SignUpFormWidget(controller: controller)

// Or programmatic access
controller.email.value = 'user@example.com';
controller.validateAll();
print(controller.isValid);

// Submit with typed data
await controller.submit((data) async {
  print(data.email);
  print(data.password);
});
```

## Available Validators

| Annotation | Purpose | Example |
|---|---|---|
| `@IsRequired()` | Field must have a value | `@IsRequired(message: 'Name required')` |
| `@IsEmail()` | Valid email format | `@IsEmail()` |
| `@MinLength(n)` | Minimum string length | `@MinLength(8)` |
| `@MaxLength(n)` | Maximum string length | `@MaxLength(100)` |
| `@PatternValidator(regex)` | Regex pattern match | `@PatternValidator(r'^\d{5}$')` |
| `@Min(n)` | Minimum numeric value | `@Min(0)` |
| `@Max(n)` | Maximum numeric value | `@Max(150)` |
| `@MustMatch('field')` | Cross-field equality | `@MustMatch('password')` |
| `@AsyncValidate()` | Server-side validation | `@AsyncValidate(debounceMs: 500)` |

All validators accept an optional `message` parameter for custom error messages.

## Async Validation

Mark a field for async validation, then register the validator at runtime:

```dart
@FormForge()
class MyForm {
  @AsyncValidate()
  final String username;
}

// In your widget:
final controller = MyFormController();
controller.registerAsyncValidator('username', (value) async {
  final exists = await api.checkUsername(value as String);
  return exists ? 'Username taken' : null;
});
```

## Custom Widgets

Override the default widget for any field:

```dart
@FormForge()
class MyForm {
  @FieldWidget(MyCustomTextField)
  final String phone;
}
```

## Custom Validators

Create domain-specific validators:

```dart
class IsPhoneNumber extends FormForgeValidator {
  const IsPhoneNumber();

  @override
  String? validate(dynamic value) {
    if (value is! String) return 'Invalid';
    return RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)
        ? null
        : 'Invalid phone number';
  }
}
```

## Supported Field Types

| Dart Type | Flutter Widget |
|---|---|
| `String` | `TextFormField` |
| `int`, `double` | `TextFormField` (number keyboard) |
| `bool` | `CheckboxListTile` |
| `DateTime` | Date picker + text display |
| `enum` | `DropdownButtonFormField` |
| Nullable (`String?`) | Optional field (no required check) |

## State Management

form_forge is state-management agnostic. The generated controller uses `ChangeNotifier`, which works with:

- **Provider** — `ChangeNotifierProvider(create: (_) => MyFormController())`
- **Riverpod** — `ChangeNotifierProvider((ref) => MyFormController())`
- **Bloc** — Listen to controller changes in your Bloc
- **Vanilla** — `ListenableBuilder(listenable: controller, builder: ...)`

## License

MIT

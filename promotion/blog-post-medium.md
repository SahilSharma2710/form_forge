# I Built the "freezed of Forms" for Flutter — Here's Why

Every Flutter developer knows the pain. You need a login form. Simple, right? Email and password. Two fields.

**87 lines later**, you've got TextEditingControllers, dispose methods, validators, setState calls, error text logic, and a GlobalKey. For two fields.

Now multiply that by every form in your app — signup, profile edit, checkout, settings, feedback. That's 40% of your UI code just managing form boilerplate.

I got tired of it. So I built **form_forge**.

## The Idea

What if forms worked like `freezed` works for data classes? You define a class, annotate it, run `build_runner`, and everything is generated for you.

`freezed` proved this model works — 1.67 million downloads on pub.dev. But nobody had applied it to forms. The gap was wide open.

## Before & After

**Before form_forge** — a login form:

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
  // ... 50+ more lines of build method, TextFormFields, error handling...
}
```

**After form_forge** — the same login form:

```dart
@FormForge()
class LoginForm {
  @IsRequired()
  @IsEmail()
  late final String email;

  @IsRequired()
  @MinLength(8)
  late final String password;
}
```

Run `dart run build_runner build`. Done. You get:
- `LoginFormController` — typed field access, validation, submission
- `LoginFormWidget` — drop-in widget with error display
- `LoginFormData` — typed data class for submission

**12 lines instead of 87. That's an 86% reduction.**

## What It Supports

### 9 Built-in Validators

| Annotation | What It Does |
|---|---|
| `@IsRequired()` | Field must have a value |
| `@IsEmail()` | Valid email format |
| `@MinLength(n)` | Minimum string length |
| `@MaxLength(n)` | Maximum string length |
| `@PatternValidator(regex)` | Regex pattern match |
| `@Min(n)` | Minimum numeric value |
| `@Max(n)` | Maximum numeric value |
| `@MustMatch('field')` | Cross-field equality (confirm password) |
| `@AsyncValidate()` | Server-side validation with debounce |

Every validator accepts a custom `message` parameter.

### Cross-Field Validation

Confirm password? One line:

```dart
@MustMatch('password', message: 'Passwords do not match')
late final String confirmPassword;
```

### Async Validation

Check if an email exists on the server? Mark it and register at runtime:

```dart
@AsyncValidate()
late final String email;

// Then:
controller.registerAsyncValidator('email', (value) async {
  final exists = await api.checkEmail(value as String);
  return exists ? 'Email already taken' : null;
});
```

Built-in debouncing with real-time validation on every keystroke. Loading state per field. No manual async code.

### Multiple Field Types

| Dart Type | Generated Widget |
|---|---|
| `String` | `TextFormField` |
| `int`, `double` | `TextFormField` (number keyboard) |
| `bool` | `CheckboxListTile` |
| `DateTime` | Date picker with text display |
| `enum` | `DropdownButtonFormField` |
| Nullable (`String?`) | Optional field |

### State Management Agnostic

The generated controller uses `ChangeNotifier`. Works with Provider, Riverpod, Bloc, or vanilla `ListenableBuilder`. No opinions forced.

## How I Built It

form_forge is a `source_gen` code generator that runs via `build_runner`. The architecture:

1. **form_forge** — annotations + runtime types (zero dependencies beyond Flutter SDK)
2. **form_forge_generator** — processes annotations and emits Dart code (dev dependency only)

The generator pipeline:
- `FieldResolver` reads class fields and their annotations
- `ValidatorCollector` groups validators per field
- `ControllerEmitter` generates the FormController
- `WidgetEmitter` generates the FormWidget
- `DataClassEmitter` generates the FormData class

Three-phase validation: sync → cross-field → async. Each phase completes before the next starts.

## Try It

```yaml
dependencies:
  form_forge: ^0.1.1

dev_dependencies:
  form_forge_generator: ^0.1.1
  build_runner: ^2.4.0
```

GitHub: https://github.com/SahilSharma2710/form_forge
pub.dev: https://pub.dev/packages/form_forge

## What's Next

- Multi-step form wizards (`@FormStep`)
- Dynamic field visibility (`@ShowWhen`)
- Auto-save / draft support
- Localization for validation messages
- Dart macros support (when stable)

If forms in Flutter have ever frustrated you, give form_forge a try. Star the repo if it saves you time.

---

*form_forge is MIT licensed and open for contributions. Check the CONTRIBUTING.md for how to add new validators.*

---
title: "Stop Writing Form Boilerplate in Flutter — I Built form_forge"
published: true
tags: flutter, dart, opensource, codegen
---

Every Flutter developer has written this code a hundred times:

```dart
final _emailController = TextEditingController();
final _passwordController = TextEditingController();

@override
void dispose() {
  _emailController.dispose();
  _passwordController.dispose();
  super.dispose();
}
```

Controllers. Dispose. Validators. setState. Error text. For every. Single. Form.

I built **form_forge** to make this go away forever.

## What It Does

You write this:

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

Run `dart run build_runner build`.

You get:
- `LoginFormController` — typed fields, validation, submission handling
- `LoginFormWidget` — drop-in widget with error display
- `LoginFormData` — typed data for your submit callback

**12 lines. Not 87.**

## The Cool Parts

**Cross-field validation in one line:**
```dart
@MustMatch('password', message: 'Passwords do not match')
late final String confirmPassword;
```

**Async validation (check email uniqueness):**
```dart
@AsyncValidate()
late final String email;

// Register at runtime:
controller.registerAsyncValidator('email', (value) async {
  return await api.emailExists(value) ? 'Already taken' : null;
});
```

**Auto widget mapping:**
- `String` → TextFormField
- `int`, `double` → TextFormField with number keyboard
- `bool` → CheckboxListTile
- `DateTime` → Date picker
- `enum` → DropdownButtonFormField

**Works with any state management** — Provider, Riverpod, Bloc, or vanilla setState.

## Install

```yaml
dependencies:
  form_forge: ^0.1.1

dev_dependencies:
  form_forge_generator: ^0.1.1
  build_runner: ^2.4.0
```

## Links

- [pub.dev](https://pub.dev/packages/form_forge)
- [GitHub](https://github.com/SahilSharma2710/form_forge)
- [form_forge_generator](https://pub.dev/packages/form_forge_generator)

It's v0.1.1 — stars and feedback welcome!

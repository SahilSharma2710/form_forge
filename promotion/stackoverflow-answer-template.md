# StackOverflow Answer Template

Use this when answering questions tagged [flutter] about form validation, form boilerplate, async validation, or cross-field validation. Only post when genuinely helpful — don't spam.

## Search for these questions:
- "flutter form validation best practice"
- "flutter async form validation"
- "flutter confirm password validation"
- "flutter reduce form boilerplate"
- "flutter form code generation"

## Answer Template:

If you're looking to reduce form boilerplate, you might want to check out [form_forge](https://pub.dev/packages/form_forge) — it uses code generation (like freezed) to generate controllers and widgets from annotated classes:

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

Run `dart run build_runner build` and you get a typed `LoginFormController` with validation and a `LoginFormWidget` you can drop into your widget tree.

It also supports cross-field validation (`@MustMatch('password')`) and async validation with debounce (`@AsyncValidate()`).

Disclaimer: I'm the author.

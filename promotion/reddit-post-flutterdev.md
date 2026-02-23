# Title: I built form_forge — a code-generation form engine for Flutter (the "freezed of forms")

Hey r/FlutterDev!

I just published **form_forge** on pub.dev — a code-generation powered form engine that eliminates form boilerplate.

**The problem:** Every form in Flutter means TextEditingControllers, dispose methods, validators, setState, error display logic. A simple login form is 87 lines. Multiply by every form in your app.

**The solution:** Annotate a Dart class, run build_runner, get a fully functional form:

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

Run `dart run build_runner build` → generates `LoginFormController`, `LoginFormWidget`, and `LoginFormData`. 12 lines instead of 87.

**What it supports:**
- 9 built-in validators (required, email, min/max length, pattern, min/max value, cross-field match, async)
- Cross-field validation (`@MustMatch('password')` for confirm password)
- Async validation with real-time debounce on every keystroke (server-side email checks)
- Auto type-to-widget mapping (String→TextFormField, bool→Checkbox, int→number keyboard, DateTime→DatePicker, enum→Dropdown)
- State management agnostic (ChangeNotifier — works with Provider, Riverpod, Bloc)
- Custom widget overrides and custom validators

**Links:**
- pub.dev: https://pub.dev/packages/form_forge
- GitHub: https://github.com/SahilSharma2710/form_forge

It's v0.1.1 — early but functional with 109 tests passing. Would love feedback on the API design. What validators would you want to see added?

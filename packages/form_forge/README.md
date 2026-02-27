# form_forge

Code-generation powered form engine for Flutter. Define your model, annotate, and let form_forge generate type-safe forms with validation, multi-step wizards, conditional fields, theming, and persistence. **The freezed of forms.**

## Features

- **Type-safe forms** — Define your form as a class, get typed controllers and data
- **Rich validation** — Required, email, length, numeric ranges, regex, cross-field, and async
- **Multi-step wizards** — `@FormStep` for stepper-based forms
- **Conditional fields** — `@ShowWhen` to show/hide fields based on other values
- **Field grouping** — `@FieldGroup` for visual sections with headers
- **Advanced field types** — Rating stars, sliders, chips, color pickers, date ranges, rich text
- **Theming** — `FormForgeTheme` for consistent styling across forms
- **Persistence** — Auto-save to SharedPreferences with `persistKey`
- **JSON serialization** — `toJson()` and `fromJson()` for API integration
- **Focus management** — Automatic FocusNode handling and next-field navigation

## Installation

```yaml
dependencies:
  form_forge: ^1.0.0

dev_dependencies:
  form_forge_generator: ^1.0.0
  build_runner: ^2.4.0
```

## Quick Start

### 1. Define your form

```dart
import 'package:form_forge/form_forge.dart';

part 'login_form.g.dart';

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

### 2. Generate

```bash
dart run build_runner build
```

### 3. Use

```dart
final controller = LoginFormController();

// Drop-in widget
LoginFormWidget(controller: controller)

// Or programmatic access
controller.email.value = 'user@example.com';
controller.validateAll();
print(controller.isValid);

// Submit with typed data
await controller.submit((data) async {
  print(data.email); // Typed as String
  await api.login(data.email, data.password);
});
```

## Validators

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
| `@AsyncValidate()` | Server-side validation | `@AsyncValidate(debounce: Duration(seconds: 1))` |
| `@PhoneNumber()` | Phone number validation | `@PhoneNumber()` |

## Multi-Step Wizard Forms

Create wizard-style forms with the `@FormStep` annotation:

```dart
@FormForge()
class RegistrationForm {
  @FormStep(0, title: 'Personal Info')
  @IsRequired()
  late final String name;

  @FormStep(0, title: 'Personal Info')
  @IsRequired()
  @IsEmail()
  late final String email;

  @FormStep(1, title: 'Address')
  @IsRequired()
  late final String street;

  @FormStep(1, title: 'Address')
  late final String city;

  @FormStep(2, title: 'Confirmation')
  late final bool agreeToTerms;
}
```

The generated widget renders a `Stepper` with step navigation:

```dart
// Navigation methods on controller:
controller.nextStep();     // Validates current step, advances if valid
controller.previousStep(); // Goes back
controller.currentStep;    // Current step index
controller.totalSteps;     // Total number of steps
```

## Conditional Fields

Show or hide fields based on other field values:

```dart
@FormForge()
class PaymentForm {
  late final String paymentMethod;

  @ShowWhen('paymentMethod', equals: 'credit_card')
  @IsRequired()
  late final String cardNumber;

  @ShowWhen('paymentMethod', equals: 'bank_transfer')
  @IsRequired()
  late final String accountNumber;
}
```

## Field Groups

Organize fields into visual sections:

```dart
@FormForge()
class ProfileForm {
  @FieldGroup('Personal Information')
  @IsRequired()
  late final String name;

  @FieldGroup('Personal Information')
  @IsEmail()
  late final String email;

  @FieldGroup('Preferences')
  late final bool newsletter;
}
```

## Advanced Field Types

```dart
@FormForge()
class SurveyForm {
  @RatingInput(maxStars: 5)
  late final int satisfaction;

  @Slider(min: 0, max: 100, divisions: 10)
  late final double likelihood;

  @ChipsInput(maxChips: 5)
  late final List<String> interests;

  @ColorPicker()
  late final Color favoriteColor;

  @DateRange(firstDate: 2020, lastDate: 2030)
  late final DateTimeRange? availability;

  @RichText(minLines: 3, maxLines: 10)
  late final String feedback;
}
```

## Theming

Apply consistent styling across all forms:

```dart
FormForgeThemeProvider(
  theme: FormForgeTheme(
    fieldSpacing: 20.0,
    formPadding: EdgeInsets.all(16),
    inputDecoration: InputDecoration(
      border: OutlineInputBorder(),
      filled: true,
    ),
    labelStyle: TextStyle(fontWeight: FontWeight.bold),
    groupHeaderStyle: TextStyle(fontSize: 18),
  ),
  child: MyApp(),
)
```

## Persistence

Auto-save form state to SharedPreferences:

```dart
@FormForge(persistKey: 'draft_form')
class DraftForm {
  late final String title;
  late final String content;
}
```

Form state persists across app restarts. Users can continue where they left off.

## JSON Serialization

```dart
final controller = MyFormController();

// Export to JSON
final json = controller.toJson();
await api.saveDraft(json);

// Import from JSON
controller.fromJson(savedData);

// Data class also has toJson/fromJson
await controller.submit((data) async {
  await api.post('/forms', body: data.toJson());
});
```

## Async Validation

```dart
@FormForge()
class MyForm {
  @AsyncValidate(debounce: Duration(milliseconds: 500))
  late final String username;
}

// Register validator
controller.registerAsyncValidator('username', (value) async {
  final exists = await api.checkUsername(value as String);
  return exists ? 'Username taken' : null;
});
```

A loading indicator appears while validation is in progress.

## Controller Features

```dart
final controller = MyFormController();

// Field access
controller.email.value = 'new@email.com';
controller.email.error;      // Current error message
controller.email.isValid;    // Whether field is valid
controller.email.isEnabled;  // Enable/disable field

// Form-level
controller.isValid;          // All fields valid?
controller.isSubmitting;     // Currently submitting?
controller.isValidating;     // Async validation in progress?
controller.isEnabled = false; // Disable entire form

// Actions
controller.reset();          // Reset all fields
controller.clearErrors();    // Clear all errors
controller.validateAll();    // Run all validators

// Serialization
controller.toJson();
controller.fromJson(json);
controller.copyWith(email: 'new@email.com');
controller.populateFrom(formData);

// Focus management
controller.focusNextField('email'); // Move to next field
```

## Supported Field Types

| Dart Type | Flutter Widget |
|---|---|
| `String` | `TextFormField` |
| `int`, `double` | `TextFormField` (number keyboard) |
| `bool` | `SwitchListTile` |
| `DateTime` | Date picker |
| `DateTimeRange` | Date range picker |
| `Color` | Color picker dialog |
| `List<String>` | Chips input |
| `enum` | `DropdownButtonFormField` |
| Nullable (`String?`) | Optional field |

## State Management

form_forge is state-management agnostic. The generated controller uses `ChangeNotifier`:

- **Provider** — `ChangeNotifierProvider(create: (_) => MyFormController())`
- **Riverpod** — `ChangeNotifierProvider((ref) => MyFormController())`
- **Bloc** — Listen to controller changes
- **Vanilla** — `AnimatedBuilder(animation: controller, builder: ...)`

## License

MIT

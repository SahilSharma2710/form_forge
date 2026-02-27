# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-02-27

### Added

- **Multi-step wizard forms**: `@FormStep(step, title:)` annotation for wizard-style forms with stepper navigation
- **Conditional field visibility**: `@ShowWhen('field', equals: value)` to show/hide fields based on other field values
- **Field grouping**: `@FieldGroup('name')` for organizing fields into visual sections with headers
- **New field type annotations**:
  - `@PhoneNumber()` - phone number input with validation
  - `@SearchableDropdown()` - searchable dropdown with autocomplete
  - `@DateRange()` - date range picker
  - `@SliderInput(min, max)` - slider input for numeric values
  - `@RatingInput(maxStars:)` - star rating widget
  - `@ChipsInput(maxChips:)` - tag/chip input for lists
  - `@ColorPicker()` - color selection widget
  - `@RichTextInput(minLines, maxLines)` - multiline text editor
- **Serialization**: `toJson()` and `fromJson()` on generated controllers and data classes
- **Theming**: `FormForgeTheme` and `FormForgeThemeProvider` for customizing form appearance
- **Persistence**: `@FormForge(persistKey:)` for automatic SharedPreferences persistence
- **Focus management**: Auto-generated `FocusNode` per field with `focusNextField()` for keyboard navigation
- **Async validation loading indicator**: Visual feedback during async validation
- **Enabled/disabled state**: `isEnabled` on both controller and individual fields
- **`copyWith()`** on both controller and data classes
- **`populateFrom()`** to load data into controller from data class
- `@AsyncValidate(debounce: Duration)` - Duration-based debounce (in addition to `debounceMs`)

### Changed

- `ForgeFieldState<T>` now includes `isEnabled` and `isValidating` properties
- `FormForgeController` now includes `isEnabled` setter and `clearErrors()` method
- Generated widgets now respect `FormForgeTheme` from context

## [0.1.4] - 2026-02-24

### Fixed

- Re-export `package:flutter/material.dart` so generated `.g.dart` widget code compiles with a single `import 'package:form_forge/form_forge.dart'`
- Updated all README examples to use `late final` fields to avoid uninitialized field errors

## [0.1.3] - 2026-02-24

### Added

- Added `example/example.dart` for pub.dev Example tab (+10 pub points)

## [0.1.2] - 2026-02-23

### Fixed

- Fixed double-"Form" naming bug in README examples (e.g. `LoginFormFormController` → `LoginFormController`)
- Updated install versions in README to `^0.1.1`

## [0.1.1] - 2026-02-23

### Changed

- Bumped version for compatibility with form_forge_generator 0.1.1

## [0.1.0] - 2026-02-21

### Added

- `@FormForge()` class annotation to mark form definitions
- Built-in validators: `@IsRequired`, `@IsEmail`, `@MinLength`, `@MaxLength`, `@PatternValidator`, `@Min`, `@Max`
- Cross-field validation via `@MustMatch('otherField')`
- Async validation marker via `@AsyncValidate()`
- Custom widget override via `@FieldWidget(Type)`
- `FormForgeController` base class with ChangeNotifier
- `ForgeFieldState<T>` for per-field state management
- `FormForgeValidator` interface for custom validators
- Default validation error messages

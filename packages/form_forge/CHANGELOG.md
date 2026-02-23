# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

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

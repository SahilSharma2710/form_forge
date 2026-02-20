# Contributing to form_forge

Thank you for considering contributing to form_forge!

## Getting Started

1. Fork the repository
2. Clone your fork
3. Run `dart pub get` from the root to resolve all workspace dependencies
4. Make your changes
5. Run tests (see below)
6. Submit a PR

## Project Structure

```
packages/
  form_forge/           # Annotations + runtime types (what users import)
  form_forge_generator/ # Code generation logic (dev dependency)
  form_forge_example/   # Example Flutter app
```

## Running Tests

```bash
# Annotation package tests (requires Flutter)
cd packages/form_forge && flutter test

# Generator package tests (pure Dart)
cd packages/form_forge_generator && dart test
```

## Adding a New Validator

1. **Create the annotation** in `packages/form_forge/lib/src/annotations/validators/`

```dart
class MyValidator {
  final String? message;
  const MyValidator({this.message});
}
```

2. **Export it** in `packages/form_forge/lib/form_forge.dart`

3. **Add TypeChecker** in `packages/form_forge_generator/lib/src/resolvers/field_resolver.dart`

4. **Add field to ResolvedField** in `resolved_field.dart`

5. **Add generation logic** in `form_forge_generator.dart` inside `_generateFieldValidator`

6. **Write tests** — both annotation unit tests and generator integration tests

7. **Add default message** in `packages/form_forge/lib/src/constants/defaults.dart`

## Code Style

- Follow Dart effective style guide
- Use barrel exports — never import from `lib/src/` directly
- Every source file must have a corresponding test file
- Generated code must pass `dart analyze` with zero warnings

## PR Process

1. Ensure all tests pass
2. Run `dart analyze` — zero issues required
3. Run `dart format --set-exit-if-changed .` — formatting must be consistent
4. Update CHANGELOG.md with your changes
5. Submit PR against `main` branch

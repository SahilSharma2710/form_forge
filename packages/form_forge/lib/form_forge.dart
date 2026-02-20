/// Code-generation powered form engine for Flutter.
///
/// Annotate your Dart class with `@FormForge()`, add field validators like
/// `@IsRequired()` and `@IsEmail()`, run `build_runner`, and get a fully
/// functional form with validation, error handling, and state management.
library;

// Annotations
export 'src/annotations/form_forge.dart';
export 'src/annotations/field_widget.dart';
export 'src/annotations/validators/is_required.dart';
export 'src/annotations/validators/is_email.dart';
export 'src/annotations/validators/min_length.dart';
export 'src/annotations/validators/max_length.dart';
export 'src/annotations/validators/pattern.dart';
export 'src/annotations/validators/min.dart';
export 'src/annotations/validators/max.dart';
export 'src/annotations/validators/must_match.dart';
export 'src/annotations/validators/async_validator.dart';
// Keep AsyncValidator as alias for backward compatibility
// Users use @AsyncValidate() annotation

// Types
export 'src/types/form_field_state.dart';
export 'src/types/form_forge_controller.dart';
export 'src/types/form_forge_validator.dart';

// Constants
export 'src/constants/defaults.dart';

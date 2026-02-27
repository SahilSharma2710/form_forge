/// Code-generation powered form engine for Flutter.
///
/// Annotate your Dart class with `@FormForge()`, add field validators like
/// `@IsRequired()` and `@IsEmail()`, run `build_runner`, and get a fully
/// functional form with validation, error handling, and state management.
library;

// Dart core — re-export dart:async for Timer used in debounced async validation.
export 'dart:async' show Timer;

// Flutter — re-exported so generated .g.dart part files have access to
// StatefulWidget, TextFormField, etc. via a single form_forge import.
export 'package:flutter/material.dart';

// Core Annotations
export 'src/annotations/form_forge.dart';
export 'src/annotations/field_widget.dart';
export 'src/annotations/form_step.dart';
export 'src/annotations/show_when.dart';
export 'src/annotations/field_group.dart';

// Validators
export 'src/annotations/validators/is_required.dart';
export 'src/annotations/validators/is_email.dart';
export 'src/annotations/validators/min_length.dart';
export 'src/annotations/validators/max_length.dart';
export 'src/annotations/validators/pattern.dart';
export 'src/annotations/validators/min.dart';
export 'src/annotations/validators/max.dart';
export 'src/annotations/validators/must_match.dart';
export 'src/annotations/validators/async_validator.dart';

// Field Type Annotations
export 'src/annotations/field_types/phone_number.dart';
export 'src/annotations/field_types/searchable_dropdown.dart';
export 'src/annotations/field_types/date_range.dart';
export 'src/annotations/field_types/slider_input.dart';
export 'src/annotations/field_types/rating_input.dart';
export 'src/annotations/field_types/chips_input.dart';
export 'src/annotations/field_types/color_picker.dart';
export 'src/annotations/field_types/rich_text_input.dart';

// Types
export 'src/types/form_field_state.dart';
export 'src/types/form_forge_controller.dart';
export 'src/types/form_forge_validator.dart';

// Theme
export 'src/theme/form_forge_theme.dart';

// Constants
export 'src/constants/defaults.dart';

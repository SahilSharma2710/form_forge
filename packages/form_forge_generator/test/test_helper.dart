import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:form_forge_generator/builder.dart';

/// Shared form_forge source definitions for testing.
final formForgeSources = <String, String>{
  'form_forge|lib/form_forge.dart': '''
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
    export 'src/types/form_forge_validator.dart';
    export 'src/constants/defaults.dart';
  ''',
  'form_forge|lib/src/annotations/form_forge.dart':
      'class FormForge { final String? persistKey; const FormForge({this.persistKey}); }',
  'form_forge|lib/src/annotations/field_widget.dart':
      'class FieldWidget { final Type widgetType; const FieldWidget(this.widgetType); }',
  'form_forge|lib/src/annotations/validators/is_required.dart':
      'class IsRequired { final String? message; const IsRequired({this.message}); }',
  'form_forge|lib/src/annotations/validators/is_email.dart':
      'class IsEmail { final String? message; const IsEmail({this.message}); }',
  'form_forge|lib/src/annotations/validators/min_length.dart':
      'class MinLength { final int length; final String? message; const MinLength(this.length, {this.message}); }',
  'form_forge|lib/src/annotations/validators/max_length.dart':
      'class MaxLength { final int length; final String? message; const MaxLength(this.length, {this.message}); }',
  'form_forge|lib/src/annotations/validators/pattern.dart':
      'class PatternValidator { final String pattern; final String? message; const PatternValidator(this.pattern, {this.message}); }',
  'form_forge|lib/src/annotations/validators/min.dart':
      'class Min { final num value; final String? message; const Min(this.value, {this.message}); }',
  'form_forge|lib/src/annotations/validators/max.dart':
      'class Max { final num value; final String? message; const Max(this.value, {this.message}); }',
  'form_forge|lib/src/annotations/validators/must_match.dart':
      'class MustMatch { final String field; final String? message; const MustMatch(this.field, {this.message}); }',
  'form_forge|lib/src/annotations/validators/async_validator.dart':
      'class AsyncValidate { final int debounceMs; final Duration? debounce; const AsyncValidate({this.debounceMs = 500, this.debounce}); }',
  'form_forge|lib/src/types/form_forge_validator.dart':
      'abstract class FormForgeValidator { const FormForgeValidator(); String? validate(dynamic value); }',
  'form_forge|lib/src/constants/defaults.dart':
      'class FormForgeDefaults { static const int asyncDebounceMs = 500; }',
};

/// Generates code from the given source string using the form_forge builder.
Future<String> generate(String source) async {
  final srcs = <String, String>{
    ...formForgeSources,
    'a|lib/input.dart': source,
  };
  final builder = formForgeBuilder(BuilderOptions.empty);
  final writer = InMemoryAssetWriter();

  await testBuilder(
    builder,
    srcs,
    rootPackage: 'a',
    writer: writer,
  );

  // Find the generated output
  for (final entry in writer.assets.entries) {
    if (entry.key.package == 'a' && entry.key.path.endsWith('.g.dart')) {
      return String.fromCharCodes(entry.value);
    }
  }

  return '';
}

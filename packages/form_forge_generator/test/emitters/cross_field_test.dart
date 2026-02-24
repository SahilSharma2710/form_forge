import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:form_forge_generator/builder.dart';
import 'package:test/test.dart';

final _formForgeSources = <String, String>{
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
      'class FormForge { const FormForge(); }',
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
  'form_forge|lib/src/annotations/validators/async_validator.dart': '''
    typedef AsyncValidatorFn = Future<String?> Function(dynamic value);
    class AsyncValidate { final int debounceMs; const AsyncValidate({this.debounceMs = 500}); }
  ''',
  'form_forge|lib/src/types/form_forge_validator.dart':
      'abstract class FormForgeValidator { const FormForgeValidator(); String? validate(dynamic value); }',
  'form_forge|lib/src/constants/defaults.dart':
      'class FormForgeDefaults { static const int asyncDebounceMs = 500; }',
};

Future<String> generate(String source) async {
  final srcs = <String, String>{
    ..._formForgeSources,
    'a|lib/input.dart': source,
  };
  final builder = formForgeBuilder(BuilderOptions.empty);
  final result = await testBuilder(
    builder,
    srcs,
    rootPackage: 'a',
    flattenOutput: true,
  );
  for (final output in result.outputs) {
    if (output.package == 'a') {
      final content = result.readerWriter.testing.readString(output);
      if (content.trim().isNotEmpty) return content;
    }
  }
  return '';
}

void main() {
  group('Cross-Field Validation (@MustMatch)', () {
    test('generates cross-field validation method', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class PasswordForm {
          @IsRequired()
          final String password;

          @IsRequired()
          @MustMatch('password')
          final String confirmPassword;
        }
      ''');

      expect(result, contains('validateCrossFields'));
      expect(result, contains('confirmPassword'));
      expect(result, contains('password'));
    });

    test('generates default must match error message', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          final String password;

          @MustMatch('password')
          final String confirm;
        }
      ''');

      expect(result, contains('Must match password'));
    });

    test('generates custom must match error message', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          final String password;

          @MustMatch('password', message: 'Passwords do not match')
          final String confirm;
        }
      ''');

      expect(result, contains('Passwords do not match'));
    });

    test('validateAll calls cross-field validation', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @IsRequired()
          final String password;

          @MustMatch('password')
          final String confirm;
        }
      ''');

      expect(result, contains('validateAll'));
      expect(result, contains('validateCrossFields'));
    });

    test('cross-field validation compares field values', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          final String password;

          @MustMatch('password')
          final String confirm;
        }
      ''');

      // Should compare confirm.value to password.value
      expect(result, contains('confirm.value'));
      expect(result, contains('password.value'));
    });
  });
}

import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:form_forge_generator/builder.dart';
import 'package:test/test.dart';

void main() {
  group('FormForgeGenerator', () {
    test('generates controller for simple class with String fields', () async {
      final result = await _generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class LoginForm {
          @IsRequired()
          final String email;

          @IsRequired()
          final String password;
        }
      ''');

      expect(result, contains('class LoginFormController'));
      expect(result, contains('extends FormForgeController'));
      expect(result, contains('ForgeFieldState<String> email'));
      expect(result, contains('ForgeFieldState<String> password'));
      expect(result, contains('initializeFields()'));
    });

    test('generates fields list override', () async {
      final result = await _generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class SimpleForm {
          final String name;
        }
      ''');

      expect(result, contains('get fields'));
      expect(result, contains('name'));
    });

    test('generates errors map override', () async {
      final result = await _generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class SimpleForm {
          final String name;
          final String email;
        }
      ''');

      expect(result, contains("'name': name.error"));
      expect(result, contains("'email': email.error"));
    });

    test('handles nullable fields', () async {
      final result = await _generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class OptionalForm {
          final String? bio;
        }
      ''');

      expect(result, contains('ForgeFieldState<String?>'));
      expect(result, contains('initialValue: null'));
    });

    test('handles int fields with default value 0', () async {
      final result = await _generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class NumericForm {
          final int age;
        }
      ''');

      expect(result, contains('ForgeFieldState<int>'));
      expect(result, contains('initialValue: 0'));
    });

    test('handles bool fields with default value false', () async {
      final result = await _generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class BoolForm {
          final bool agreeToTerms;
        }
      ''');

      expect(result, contains('ForgeFieldState<bool>'));
      expect(result, contains('initialValue: false'));
    });

    test('handles multiple field types', () async {
      final result = await _generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class MultiTypeForm {
          final String name;
          final int age;
          final double weight;
          final bool active;
        }
      ''');

      expect(result, contains('ForgeFieldState<String> name'));
      expect(result, contains('ForgeFieldState<int> age'));
      expect(result, contains('ForgeFieldState<double> weight'));
      expect(result, contains('ForgeFieldState<bool> active'));
      expect(result, contains("initialValue: ''"));
      expect(result, contains('initialValue: 0)'));
      expect(result, contains('initialValue: 0.0'));
      expect(result, contains('initialValue: false'));
    });

    test('generates controller class name from source class name', () async {
      final result = await _generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class MyCustomForm {
          final String field;
        }
      ''');

      expect(result, contains('class MyCustomFormController'));
    });
  });
}

Future<String> _generate(String source) async {
  final srcs = <String, String>{
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
    'a|lib/input.dart': source,
  };

  final builder = formForgeBuilder(BuilderOptions.empty);
  final writer = InMemoryAssetWriter();

  await testBuilder(
    builder,
    srcs,
    rootPackage: 'a',
    writer: writer,
    reader: await PackageAssetReader.currentIsolate(),
  );

  for (final entry in writer.assets.entries) {
    if (entry.key.package == 'a') {
      final content = String.fromCharCodes(entry.value);
      if (content.trim().isNotEmpty) {
        return content;
      }
    }
  }

  return '';
}

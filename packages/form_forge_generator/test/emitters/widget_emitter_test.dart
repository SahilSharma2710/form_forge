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
  'form_forge|lib/src/annotations/validators/async_validator.dart':
      'class AsyncValidate { final int debounceMs; const AsyncValidate({this.debounceMs = 500}); }',
  'form_forge|lib/src/types/form_forge_validator.dart':
      'abstract class FormForgeValidator { const FormForgeValidator(); String? validate(dynamic value); }',
  'form_forge|lib/src/constants/defaults.dart':
      'class FormForgeDefaults { static const int asyncDebounceMs = 500; }',
};

Future<String> generate(String source) async {
  final srcs = <String, String>{..._formForgeSources, 'a|lib/input.dart': source};
  final builder = formForgeBuilder(BuilderOptions.empty);
  final result = await testBuilder(builder, srcs, rootPackage: 'a',
      flattenOutput: true);
  for (final output in result.outputs) {
    if (output.package == 'a') {
      final content = result.readerWriter.testing.readString(output);
      if (content.trim().isNotEmpty) return content;
    }
  }
  return '';
}

void main() {
  group('Widget Emitter', () {
    test('generates StatefulWidget class', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class LoginForm {
          final String email;
          final String password;
        }
      ''');

      expect(result, contains('class LoginFormWidget'));
      expect(result, contains('StatefulWidget'));
    });

    test('generates TextFormField for String fields', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class SimpleForm {
          final String name;
        }
      ''');

      expect(result, contains('TextFormField'));
    });

    test('generates number keyboard for int fields', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class NumForm {
          final int age;
        }
      ''');

      expect(result, contains('TextInputType.number'));
    });

    test('generates CheckboxListTile for bool fields', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class BoolForm {
          final bool agree;
        }
      ''');

      expect(result, contains('CheckboxListTile'));
    });

    test('accepts controller as required parameter', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          final String name;
        }
      ''');

      expect(result, contains('TestFormController'));
      expect(result, contains('controller'));
    });

    test('generates build method with Form widget', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          final String name;
        }
      ''');

      expect(result, contains('Widget build'));
      expect(result, contains('Form'));
      expect(result, contains('Column'));
    });

    test('generates per-field builder methods', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          final String name;
          final String email;
        }
      ''');

      expect(result, contains('buildNameField'));
      expect(result, contains('buildEmailField'));
    });
  });
}

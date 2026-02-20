import 'package:build/build.dart';
import 'package:build_test/build_test.dart';
import 'package:form_forge_generator/builder.dart';
import 'package:test/test.dart';

/// Shared mock sources for form_forge package.
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

void main() {
  group('Controller Emitter — Sync Validation', () {
    test('generates validateFieldName method for @IsRequired', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @IsRequired()
          final String name;
        }
      ''');

      expect(result, contains('void validateName'));
      expect(result, contains('This field is required'));
    });

    test('generates validateFieldName with custom message', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @IsRequired(message: 'Name cannot be empty')
          final String name;
        }
      ''');

      expect(result, contains('Name cannot be empty'));
    });

    test('generates email validation', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @IsEmail()
          final String email;
        }
      ''');

      expect(result, contains('void validateEmail'));
      expect(result, contains('RegExp'));
    });

    test('generates minLength validation', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @MinLength(8)
          final String password;
        }
      ''');

      expect(result, contains('void validatePassword'));
      expect(result, contains('.length < 8'));
    });

    test('generates maxLength validation', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @MaxLength(100)
          final String bio;
        }
      ''');

      expect(result, contains('void validateBio'));
      expect(result, contains('.length > 100'));
    });

    test('generates min numeric validation', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @Min(0)
          final int age;
        }
      ''');

      expect(result, contains('void validateAge'));
      expect(result, contains('< 0'));
    });

    test('generates max numeric validation', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @Max(150)
          final int weight;
        }
      ''');

      expect(result, contains('void validateWeight'));
      expect(result, contains('> 150'));
    });

    test('generates pattern validation', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @PatternValidator(r'^[a-z]+\$')
          final String code;
        }
      ''');

      expect(result, contains('void validateCode'));
      expect(result, contains('RegExp'));
    });

    test('generates multiple validators on one field', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @IsRequired()
          @IsEmail()
          final String email;
        }
      ''');

      expect(result, contains('void validateEmail'));
      expect(result, contains('This field is required'));
      expect(result, contains('RegExp'));
    });

    test('generates validateAll method', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @IsRequired()
          final String name;
          @IsRequired()
          final String email;
        }
      ''');

      expect(result, contains('void validateAll'));
      expect(result, contains('validateName'));
      expect(result, contains('validateEmail'));
    });

    test('skips validation for fields with no validators', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          final String name;
          @IsRequired()
          final String email;
        }
      ''');

      // name has no validators, so no validateName method
      expect(result, isNot(contains('void validateName')));
      expect(result, contains('void validateEmail'));
    });
  });
}

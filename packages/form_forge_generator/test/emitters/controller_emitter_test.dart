import 'package:test/test.dart';

import '../test_helper.dart';

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

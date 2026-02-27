import 'package:test/test.dart';

import '../test_helper.dart';

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

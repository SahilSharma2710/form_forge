import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('Form Submission & Data Class', () {
    test('generates FormData class with all fields', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class SignUpForm {
          final String name;
          final String email;
          final int age;
        }
      ''');

      expect(result, contains('class SignUpFormData'));
      expect(result, contains('final String name'));
      expect(result, contains('final String email'));
      expect(result, contains('final int age'));
    });

    test('FormData has const constructor', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class SimpleForm {
          final String name;
        }
      ''');

      expect(result, contains('const SimpleFormData'));
    });

    test('generates submit method on controller', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class LoginForm {
          @IsRequired()
          final String email;
          @IsRequired()
          final String password;
        }
      ''');

      expect(result, contains('Future<void> submit'));
      expect(result, contains('LoginFormData'));
      expect(result, contains('validateAll'));
      expect(result, contains('isValid'));
    });

    test('generates isSubmitting state', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          final String name;
        }
      ''');

      expect(result, contains('bool _isSubmitting'));
      expect(result, contains('bool get isSubmitting'));
    });

    test('handles nullable fields in FormData', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          final String? bio;
          final String name;
        }
      ''');

      expect(result, contains('final String? bio'));
      expect(result, contains('final String name'));
    });
  });
}

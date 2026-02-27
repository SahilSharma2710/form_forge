import 'package:test/test.dart';

import '../test_helper.dart';

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

import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('Async Validation', () {
    test('generates isValidating state for async fields', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @AsyncValidate()
          final String email;
        }
      ''');

      expect(result, contains('isValidating'));
    });

    test('generates async validation method with Timer', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @AsyncValidate()
          final String email;
        }
      ''');

      expect(result, contains('Timer'));
      expect(result, contains('Duration'));
    });

    test('generates debounce with default delay', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @AsyncValidate()
          final String email;
        }
      ''');

      expect(result, contains('500'));
    });

    test('submit runs async validation', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @AsyncValidate()
          final String email;
        }
      ''');

      expect(result, contains('submit'));
      expect(result, contains('validateAsync'));
    });

    test('generates registerAsyncValidator method', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @AsyncValidate()
          final String email;
        }
      ''');

      expect(result, contains('registerAsyncValidator'));
    });
  });
}

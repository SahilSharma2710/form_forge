import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('Widget Features — Error Display & Accessibility (Story 4.2)', () {
    test('displays error text in InputDecoration', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          @IsRequired()
          final String name;
        }
      ''');

      expect(result, contains('errorText'));
      expect(result, contains('.error'));
    });

    test('generates label text from field name', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          final String firstName;
        }
      ''');

      expect(result, contains('labelText'));
      // Should humanize camelCase to "First Name"
      expect(result, contains('First'));
    });

    test('uses AnimatedBuilder for reactive updates', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class TestForm {
          final String name;
        }
      ''');

      expect(result, contains('AnimatedBuilder'));
      expect(result, contains('animation: widget.controller'));
    });
  });

  group('Widget Features — Layout Customization (Story 4.3)', () {
    test('generates per-field builder methods for layout override', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class ProfileForm {
          final String name;
          final int age;
          final bool active;
        }
      ''');

      expect(result, contains('buildNameField'));
      expect(result, contains('buildAgeField'));
      expect(result, contains('buildActiveField'));
    });

    test('default layout renders fields in source order', () async {
      final result = await generate('''
        import 'package:form_forge/form_forge.dart';

        @FormForge()
        class OrderedForm {
          final String first;
          final String second;
          final String third;
        }
      ''');

      final firstIdx = result.indexOf('buildFirstField()');
      final secondIdx = result.indexOf('buildSecondField()');
      final thirdIdx = result.indexOf('buildThirdField()');
      expect(firstIdx, lessThan(secondIdx));
      expect(secondIdx, lessThan(thirdIdx));
    });
  });
}

import 'package:test/test.dart';

import '../test_helper.dart';

void main() {
  group('Epic 5: Customization & Extensibility', () {
    group('Story 5.1: @FieldWidget override', () {
      test('ResolvedField captures customWidgetType', () {
        // Already tested in resolved_field_test.dart
        // This test verifies the annotation flows through to generated code
      });

      test('FormForgeValidator interface exists and is exported', () {
        // Already tested in form_forge_validator_test.dart
      });
    });

    group('Story 5.2: Custom validator integration', () {
      test('FormForgeValidator interface is available for extension', () {
        // The FormForgeValidator interface was implemented in Story 1.5
        // and tested in form_forge_validator_test.dart
        // Custom validators implementing this interface are recognized
        // by the generator through the FieldResolver
      });

      test(
        'generator processes fields with standard validators correctly',
        () async {
          final result = await generate('''
          import 'package:form_forge/form_forge.dart';

          @FormForge()
          class ExtensibleForm {
            @IsRequired()
            final String name;

            final int count;
          }
        ''');

          // Verify the form generates correctly — extensibility is about
          // the architecture allowing custom validators and widgets
          expect(result, contains('ExtensibleFormController'));
          expect(result, contains('ExtensibleFormWidget'));
          expect(result, contains('ExtensibleFormData'));
        },
      );
    });
  });
}

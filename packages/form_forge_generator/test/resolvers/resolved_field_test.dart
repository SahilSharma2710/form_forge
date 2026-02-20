import 'package:test/test.dart';
import 'package:form_forge_generator/src/resolvers/resolved_field.dart';

void main() {
  group('ResolvedField', () {
    test('creates with required fields only', () {
      const field = ResolvedField(name: 'email', typeName: 'String');
      expect(field.name, equals('email'));
      expect(field.typeName, equals('String'));
      expect(field.isNullable, isFalse);
      expect(field.isRequired, isFalse);
      expect(field.hasSyncValidators, isFalse);
      expect(field.hasCrossFieldValidation, isFalse);
      expect(field.hasAsyncValidator, isFalse);
    });

    test('creates with all validators', () {
      const field = ResolvedField(
        name: 'password',
        typeName: 'String',
        isRequired: true,
        requiredMessage: 'Required',
        minLength: 8,
        minLengthMessage: 'Too short',
        maxLength: 100,
      );
      expect(field.hasSyncValidators, isTrue);
      expect(field.isRequired, isTrue);
      expect(field.requiredMessage, equals('Required'));
      expect(field.minLength, equals(8));
      expect(field.maxLength, equals(100));
    });

    test('tracks nullable types', () {
      const field = ResolvedField(
        name: 'bio',
        typeName: 'String',
        isNullable: true,
      );
      expect(field.isNullable, isTrue);
    });

    test('tracks cross-field validation', () {
      const field = ResolvedField(
        name: 'confirmPassword',
        typeName: 'String',
        mustMatchField: 'password',
      );
      expect(field.hasCrossFieldValidation, isTrue);
      expect(field.mustMatchField, equals('password'));
    });

    test('tracks async validator', () {
      const field = ResolvedField(
        name: 'username',
        typeName: 'String',
        hasAsyncValidator: true,
        asyncDebounceMs: 500,
      );
      expect(field.hasAsyncValidator, isTrue);
      expect(field.asyncDebounceMs, equals(500));
    });

    test('tracks custom widget type', () {
      const field = ResolvedField(
        name: 'phone',
        typeName: 'String',
        customWidgetType: 'MaskedTextField',
      );
      expect(field.customWidgetType, equals('MaskedTextField'));
    });

    test('hasSyncValidators returns true for numeric validators', () {
      const field = ResolvedField(
        name: 'age',
        typeName: 'int',
        min: 0,
        max: 150,
      );
      expect(field.hasSyncValidators, isTrue);
    });

    test('hasSyncValidators returns true for pattern', () {
      const field = ResolvedField(
        name: 'code',
        typeName: 'String',
        pattern: r'^\d{6}$',
      );
      expect(field.hasSyncValidators, isTrue);
    });
  });
}

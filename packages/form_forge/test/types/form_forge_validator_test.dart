import 'package:flutter_test/flutter_test.dart';
import 'package:form_forge/form_forge.dart';

class _AlwaysValid extends FormForgeValidator {
  const _AlwaysValid();

  @override
  String? validate(dynamic value) => null;
}

class _AlwaysInvalid extends FormForgeValidator {
  const _AlwaysInvalid();

  @override
  String? validate(dynamic value) => 'Invalid';
}

void main() {
  group('FormForgeValidator interface', () {
    test('can create a custom validator that returns null (valid)', () {
      const validator = _AlwaysValid();
      expect(validator.validate('anything'), isNull);
    });

    test('can create a custom validator that returns error (invalid)', () {
      const validator = _AlwaysInvalid();
      expect(validator.validate('anything'), equals('Invalid'));
    });

    test('can be used as an annotation', () {
      // Verifies the class can be used as a const annotation.
      const annotation = _AlwaysValid();
      expect(annotation, isNotNull);
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:form_forge/form_forge.dart';

void main() {
  group('PatternValidator annotation', () {
    test('can be constructed with regex', () {
      const annotation = PatternValidator(r'^[a-z]+$');
      expect(annotation.pattern, equals(r'^[a-z]+$'));
      expect(annotation.message, isNull);
    });

    test('can be constructed with custom message', () {
      const annotation =
          PatternValidator(r'^[a-z]+$', message: 'Lowercase only');
      expect(annotation.pattern, equals(r'^[a-z]+$'));
      expect(annotation.message, equals('Lowercase only'));
    });
  });
}

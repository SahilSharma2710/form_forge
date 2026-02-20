import 'package:flutter_test/flutter_test.dart';
import 'package:form_forge/form_forge.dart';

void main() {
  group('IsRequired annotation', () {
    test('can be constructed with no arguments', () {
      const annotation = IsRequired();
      expect(annotation, isNotNull);
      expect(annotation.message, isNull);
    });

    test('can be constructed with custom message', () {
      const annotation = IsRequired(message: 'Name is required');
      expect(annotation.message, equals('Name is required'));
    });

    test('is a const constructor', () {
      const a = IsRequired();
      const b = IsRequired();
      expect(identical(a, b), isTrue);
    });
  });
}

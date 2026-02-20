import 'package:flutter_test/flutter_test.dart';
import 'package:form_forge/form_forge.dart';

void main() {
  group('IsEmail annotation', () {
    test('can be constructed with no arguments', () {
      const annotation = IsEmail();
      expect(annotation, isNotNull);
      expect(annotation.message, isNull);
    });

    test('can be constructed with custom message', () {
      const annotation = IsEmail(message: 'Invalid email');
      expect(annotation.message, equals('Invalid email'));
    });

    test('is a const constructor', () {
      const a = IsEmail();
      const b = IsEmail();
      expect(identical(a, b), isTrue);
    });
  });
}

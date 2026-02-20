import 'package:flutter_test/flutter_test.dart';
import 'package:form_forge/form_forge.dart';

void main() {
  group('MinLength annotation', () {
    test('can be constructed with length', () {
      const annotation = MinLength(8);
      expect(annotation.length, equals(8));
      expect(annotation.message, isNull);
    });

    test('can be constructed with custom message', () {
      const annotation = MinLength(8, message: 'Too short');
      expect(annotation.length, equals(8));
      expect(annotation.message, equals('Too short'));
    });

    test('is a const constructor', () {
      const a = MinLength(5);
      const b = MinLength(5);
      expect(identical(a, b), isTrue);
    });
  });
}

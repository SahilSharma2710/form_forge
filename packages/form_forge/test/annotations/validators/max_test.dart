import 'package:flutter_test/flutter_test.dart';
import 'package:form_forge/form_forge.dart';

void main() {
  group('Max annotation', () {
    test('can be constructed with value', () {
      const annotation = Max(100);
      expect(annotation.value, equals(100));
      expect(annotation.message, isNull);
    });

    test('can be constructed with double value', () {
      const annotation = Max(99.9);
      expect(annotation.value, equals(99.9));
    });

    test('can be constructed with custom message', () {
      const annotation = Max(150, message: 'Too heavy');
      expect(annotation.value, equals(150));
      expect(annotation.message, equals('Too heavy'));
    });
  });
}

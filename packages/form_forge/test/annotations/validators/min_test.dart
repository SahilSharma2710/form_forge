import 'package:flutter_test/flutter_test.dart';
import 'package:form_forge/form_forge.dart';

void main() {
  group('Min annotation', () {
    test('can be constructed with value', () {
      const annotation = Min(0);
      expect(annotation.value, equals(0));
      expect(annotation.message, isNull);
    });

    test('can be constructed with double value', () {
      const annotation = Min(0.5);
      expect(annotation.value, equals(0.5));
    });

    test('can be constructed with custom message', () {
      const annotation = Min(18, message: 'Must be 18 or older');
      expect(annotation.value, equals(18));
      expect(annotation.message, equals('Must be 18 or older'));
    });
  });
}

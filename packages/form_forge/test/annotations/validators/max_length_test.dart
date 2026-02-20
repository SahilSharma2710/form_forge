import 'package:flutter_test/flutter_test.dart';
import 'package:form_forge/form_forge.dart';

void main() {
  group('MaxLength annotation', () {
    test('can be constructed with length', () {
      const annotation = MaxLength(100);
      expect(annotation.length, equals(100));
      expect(annotation.message, isNull);
    });

    test('can be constructed with custom message', () {
      const annotation = MaxLength(100, message: 'Too long');
      expect(annotation.length, equals(100));
      expect(annotation.message, equals('Too long'));
    });
  });
}

import 'package:flutter_test/flutter_test.dart';
import 'package:form_forge/form_forge.dart';

void main() {
  group('MustMatch annotation', () {
    test('can be constructed with field name', () {
      const annotation = MustMatch('password');
      expect(annotation.field, equals('password'));
      expect(annotation.message, isNull);
    });

    test('can be constructed with custom message', () {
      const annotation =
          MustMatch('password', message: 'Passwords must match');
      expect(annotation.field, equals('password'));
      expect(annotation.message, equals('Passwords must match'));
    });

    test('is a const constructor', () {
      const a = MustMatch('password');
      const b = MustMatch('password');
      expect(identical(a, b), isTrue);
    });
  });
}

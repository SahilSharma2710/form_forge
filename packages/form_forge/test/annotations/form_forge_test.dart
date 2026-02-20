import 'package:flutter_test/flutter_test.dart';
import 'package:form_forge/form_forge.dart';

void main() {
  group('FormForge annotation', () {
    test('can be constructed with no arguments', () {
      const annotation = FormForge();
      expect(annotation, isNotNull);
    });

    test('is a const constructor', () {
      // Verifies const construction works (compile-time constant).
      const a = FormForge();
      const b = FormForge();
      expect(identical(a, b), isTrue);
    });
  });
}

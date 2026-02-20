import 'package:flutter_test/flutter_test.dart';
import 'package:form_forge/form_forge.dart';

void main() {
  group('AsyncValidate annotation', () {
    test('can be constructed with no arguments', () {
      const annotation = AsyncValidate();
      expect(annotation, isNotNull);
      expect(annotation.debounceMs, equals(FormForgeDefaults.asyncDebounceMs));
    });

    test('can be constructed with custom debounce', () {
      const annotation = AsyncValidate(debounceMs: 1000);
      expect(annotation.debounceMs, equals(1000));
    });

    test('is a const constructor', () {
      const a = AsyncValidate();
      const b = AsyncValidate();
      expect(identical(a, b), isTrue);
    });
  });
}

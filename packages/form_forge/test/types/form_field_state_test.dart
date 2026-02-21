import 'package:flutter_test/flutter_test.dart';
import 'package:form_forge/form_forge.dart';

void main() {
  group('ForgeFieldState', () {
    test('has initial value', () {
      final field = ForgeFieldState<String>(initialValue: '');
      expect(field.value, equals(''));
    });

    test('can update value', () {
      final field = ForgeFieldState<String>(initialValue: '');
      field.value = 'hello';
      expect(field.value, equals('hello'));
    });

    test('isValid is true when no error', () {
      final field = ForgeFieldState<String>(initialValue: '');
      expect(field.isValid, isTrue);
    });

    test('isValid is false when error is set', () {
      final field = ForgeFieldState<String>(initialValue: '');
      field.error = 'Required';
      expect(field.isValid, isFalse);
    });

    test('error is null by default', () {
      final field = ForgeFieldState<String>(initialValue: '');
      expect(field.error, isNull);
    });

    test('can clear error', () {
      final field = ForgeFieldState<String>(initialValue: '');
      field.error = 'Required';
      field.error = null;
      expect(field.isValid, isTrue);
    });

    test('notifies listeners on value change', () {
      final field = ForgeFieldState<String>(initialValue: '');
      var notified = false;
      field.addListener(() => notified = true);
      field.value = 'changed';
      expect(notified, isTrue);
    });

    test('notifies listeners on error change', () {
      final field = ForgeFieldState<String>(initialValue: '');
      var notified = false;
      field.addListener(() => notified = true);
      field.error = 'Error';
      expect(notified, isTrue);
    });

    test('supports nullable types', () {
      final field = ForgeFieldState<String?>(initialValue: null);
      expect(field.value, isNull);
      field.value = 'hello';
      expect(field.value, equals('hello'));
    });

    test('supports int type', () {
      final field = ForgeFieldState<int>(initialValue: 0);
      field.value = 42;
      expect(field.value, equals(42));
    });

    test('supports bool type', () {
      final field = ForgeFieldState<bool>(initialValue: false);
      field.value = true;
      expect(field.value, isTrue);
    });

    test('reset restores initial value and clears error', () {
      final field = ForgeFieldState<String>(initialValue: 'initial');
      field.value = 'changed';
      field.error = 'Error';
      field.reset();
      expect(field.value, equals('initial'));
      expect(field.error, isNull);
      expect(field.isValid, isTrue);
    });
  });
}

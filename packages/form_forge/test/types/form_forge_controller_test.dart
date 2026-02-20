import 'package:flutter_test/flutter_test.dart';
import 'package:form_forge/form_forge.dart';

/// Test controller to verify base class behavior.
class _TestFormController extends FormForgeController {
  final FormFieldState<String> name =
      FormFieldState<String>(initialValue: '');
  final FormFieldState<String> email =
      FormFieldState<String>(initialValue: '');

  _TestFormController() {
    initializeFields();
  }

  @override
  List<FormFieldState<Object?>> get fields => [name, email];

  @override
  Map<String, String?> get errors => {
        'name': name.error,
        'email': email.error,
      };
}

void main() {
  group('FormForgeController', () {
    late _TestFormController controller;

    setUp(() {
      controller = _TestFormController();
    });

    tearDown(() {
      controller.dispose();
    });

    test('isValid is true when all fields have no errors', () {
      expect(controller.isValid, isTrue);
    });

    test('isValid is false when any field has an error', () {
      controller.name.error = 'Required';
      expect(controller.isValid, isFalse);
    });

    test('reset clears all field values and errors', () {
      controller.name.value = 'John';
      controller.email.value = 'john@test.com';
      controller.name.error = 'Too short';
      controller.reset();
      expect(controller.name.value, equals(''));
      expect(controller.email.value, equals(''));
      expect(controller.name.error, isNull);
    });

    test('errors returns map of field errors', () {
      controller.name.error = 'Required';
      controller.email.error = null;
      final errors = controller.errors;
      expect(errors['name'], equals('Required'));
      expect(errors['email'], isNull);
    });

    test('fields list contains all registered fields', () {
      expect(controller.fields.length, equals(2));
    });

    test('notifies listeners when field values change', () {
      var notified = false;
      controller.addListener(() => notified = true);
      controller.name.value = 'changed';
      expect(notified, isTrue);
    });
  });
}

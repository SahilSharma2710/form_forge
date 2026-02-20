import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:form_forge/form_forge.dart';

void main() {
  group('FieldWidget annotation', () {
    test('can be constructed with a widget type', () {
      const annotation = FieldWidget(TextField);
      expect(annotation.widgetType, equals(TextField));
    });

    test('is a const constructor', () {
      const a = FieldWidget(TextField);
      const b = FieldWidget(TextField);
      expect(identical(a, b), isTrue);
    });
  });
}

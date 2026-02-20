/// Overrides the default widget used to render a form field.
///
/// By default, form_forge maps Dart types to Flutter widgets
/// (String → TextFormField, bool → CheckboxListTile, etc.).
/// Use this annotation to replace the default widget with a custom one.
///
/// ```dart
/// @FieldWidget(MyCustomTextField)
/// final String name;
///
/// @FieldWidget(MyMaskedInput)
/// final String phoneNumber;
/// ```
class FieldWidget {
  /// The widget type to use for rendering this field.
  final Type widgetType;

  /// Creates a [FieldWidget] annotation with the given [widgetType].
  const FieldWidget(this.widgetType);
}

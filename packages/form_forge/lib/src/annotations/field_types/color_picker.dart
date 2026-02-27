/// Marks a field as a color picker input.
///
/// The generated form will render a color selection widget
/// allowing users to pick a color visually.
///
/// The field type should be `Color` from Flutter's dart:ui library.
///
/// ```dart
/// @ColorPicker()
/// late final Color backgroundColor;
///
/// @ColorPicker(showAlpha: true)
/// late final Color themeColor;
/// ```
class ColorPicker {
  /// Whether to show the alpha (opacity) slider.
  final bool showAlpha;

  /// Creates a [ColorPicker] annotation with optional alpha support.
  const ColorPicker({this.showAlpha = false});
}

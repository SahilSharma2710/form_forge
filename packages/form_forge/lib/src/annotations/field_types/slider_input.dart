/// Marks a field as a slider input.
///
/// The generated form will render a Slider widget for numeric input
/// within a specified range.
///
/// ```dart
/// @SliderInput(min: 0, max: 100)
/// late final double volume;
///
/// @SliderInput(min: 1, max: 10, divisions: 9, label: 'Rating')
/// late final int rating;
/// ```
class SliderInput {
  /// The minimum value of the slider.
  final double min;

  /// The maximum value of the slider.
  final double max;

  /// The number of discrete divisions. If null, the slider is continuous.
  final int? divisions;

  /// Label displayed above the thumb when active.
  final String? label;

  /// Creates a [SliderInput] annotation with required [min] and [max] bounds.
  const SliderInput({
    required this.min,
    required this.max,
    this.divisions,
    this.label,
  });
}

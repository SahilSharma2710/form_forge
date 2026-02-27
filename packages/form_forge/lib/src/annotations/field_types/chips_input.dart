/// Marks a field as a chips/tags input.
///
/// The generated form will render an input that allows users to add
/// multiple tags or chips, ideal for categories, skills, or keywords.
///
/// The field type should be `List<String>`.
///
/// ```dart
/// @ChipsInput()
/// late final List<String> tags;
///
/// @ChipsInput(maxChips: 5, allowCustom: true)
/// late final List<String> skills;
/// ```
class ChipsInput {
  /// Maximum number of chips allowed. If null, unlimited.
  final int? maxChips;

  /// Whether users can add custom values not in the suggestions.
  final bool allowCustom;

  /// Creates a [ChipsInput] annotation with optional constraints.
  const ChipsInput({this.maxChips, this.allowCustom = true});
}

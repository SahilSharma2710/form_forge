/// Marks a field as a rich text editor input.
///
/// The generated form will render a multiline text field for longer content.
///
/// ```dart
/// @RichTextInput()
/// late final String description;
///
/// @RichTextInput(minLines: 5, maxLines: 20)
/// late final String articleContent;
/// ```
class RichTextInput {
  /// Minimum number of visible lines.
  final int minLines;

  /// Maximum number of visible lines before scrolling.
  final int maxLines;

  /// Creates a [RichTextInput] annotation with optional line constraints.
  const RichTextInput({this.minLines = 3, this.maxLines = 10});
}

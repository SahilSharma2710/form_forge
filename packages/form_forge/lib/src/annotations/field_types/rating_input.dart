/// Marks a field as a star rating input.
///
/// The generated form will render a row of tappable star icons
/// for intuitive rating selection.
///
/// ```dart
/// @RatingInput()
/// late final int productRating;
///
/// @RatingInput(maxStars: 10)
/// late final int detailedRating;
/// ```
class RatingInput {
  /// The maximum number of stars to display. Defaults to 5.
  final int maxStars;

  /// Creates a [RatingInput] annotation with optional [maxStars].
  const RatingInput({this.maxStars = 5});
}

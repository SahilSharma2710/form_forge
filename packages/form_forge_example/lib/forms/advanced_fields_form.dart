import 'package:form_forge/form_forge.dart';

part 'advanced_fields_form.g.dart';

/// Demonstrates advanced field types.
@FormForge()
class AdvancedFieldsForm {
  @RatingInput(maxStars: 5)
  late final int productRating;

  @SliderInput(min: 0, max: 100, divisions: 10)
  late final double volume;

  @ChipsInput(maxChips: 5)
  late final List<String> tags;

  @ColorPicker()
  late final Color themeColor;

  @DateRange(firstDate: 2020, lastDate: 2030)
  late final DateTimeRange? vacationDates;

  @RichTextInput(minLines: 3, maxLines: 8)
  late final String description;
}

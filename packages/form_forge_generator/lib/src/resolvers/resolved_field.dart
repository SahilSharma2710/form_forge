/// Data class capturing resolved field information from an annotated class.
///
/// Created by [FieldResolver] after analyzing a field's type, nullability,
/// and all form_forge annotations.
class ResolvedField {
  /// The field name as declared in the source class.
  final String name;

  /// The Dart type name (e.g., 'String', 'int', 'DateTime').
  final String typeName;

  /// Whether the field type is nullable.
  final bool isNullable;

  /// Whether the field has an @IsRequired annotation.
  final bool isRequired;

  /// Custom message for @IsRequired, if provided.
  final String? requiredMessage;

  /// Whether the field has an @IsEmail annotation.
  final bool isEmail;

  /// Custom message for @IsEmail, if provided.
  final String? emailMessage;

  /// Minimum length constraint from @MinLength, if present.
  final int? minLength;

  /// Custom message for @MinLength, if provided.
  final String? minLengthMessage;

  /// Maximum length constraint from @MaxLength, if present.
  final int? maxLength;

  /// Custom message for @MaxLength, if provided.
  final String? maxLengthMessage;

  /// Regex pattern from @PatternValidator, if present.
  final String? pattern;

  /// Custom message for @PatternValidator, if provided.
  final String? patternMessage;

  /// Minimum value constraint from @Min, if present.
  final num? min;

  /// Custom message for @Min, if provided.
  final String? minMessage;

  /// Maximum value constraint from @Max, if present.
  final num? max;

  /// Custom message for @Max, if provided.
  final String? maxMessage;

  /// Field name for @MustMatch cross-field validation, if present.
  final String? mustMatchField;

  /// Custom message for @MustMatch, if provided.
  final String? mustMatchMessage;

  /// Whether the field has an @AsyncValidator annotation.
  final bool hasAsyncValidator;

  /// Debounce milliseconds for async validator.
  final int? asyncDebounceMs;

  /// Custom widget type name from @FieldWidget, if present.
  final String? customWidgetType;

  /// Whether the field type is an enum.
  final bool isEnum;

  /// Enum constant names (e.g., ['male', 'female', 'other']).
  final List<String>? enumValues;

  // ========== NEW v1.0.0 PROPERTIES ==========

  /// Step index from @FormStep, if present.
  final int? formStep;

  /// Step title from @FormStep, if provided.
  final String? formStepTitle;

  /// Field name to observe from @ShowWhen, if present.
  final String? showWhenField;

  /// Value that triggers visibility from @ShowWhen.
  final Object? showWhenEquals;

  /// Group name from @FieldGroup, if present.
  final String? fieldGroup;

  /// Whether the field has @PhoneNumber annotation.
  final bool isPhoneNumber;

  /// Custom message for @PhoneNumber, if provided.
  final String? phoneNumberMessage;

  /// Whether the field has @SearchableDropdown annotation.
  final bool isSearchableDropdown;

  /// Hint text from @SearchableDropdown, if provided.
  final String? searchableDropdownHintText;

  /// Whether the field has @DateRange annotation.
  final bool isDateRange;

  /// First selectable year from @DateRange.
  final int? dateRangeFirstDate;

  /// Last selectable year from @DateRange.
  final int? dateRangeLastDate;

  /// Help text from @DateRange.
  final String? dateRangeHelpText;

  /// Whether the field has @Slider annotation.
  final bool isSlider;

  /// Minimum value from @Slider.
  final double? sliderMin;

  /// Maximum value from @Slider.
  final double? sliderMax;

  /// Divisions from @Slider.
  final int? sliderDivisions;

  /// Label from @Slider.
  final String? sliderLabel;

  /// Whether the field has @RatingInput annotation.
  final bool isRatingInput;

  /// Maximum stars from @RatingInput.
  final int? ratingMaxStars;

  /// Whether the field has @ChipsInput annotation.
  final bool isChipsInput;

  /// Maximum chips from @ChipsInput.
  final int? chipsMaxChips;

  /// Whether custom values are allowed from @ChipsInput.
  final bool? chipsAllowCustom;

  /// Whether the field has @ColorPicker annotation.
  final bool isColorPicker;

  /// Whether to show alpha slider from @ColorPicker.
  final bool? colorPickerShowAlpha;

  /// Whether the field has @RichText annotation.
  final bool isRichText;

  /// Minimum lines from @RichText.
  final int? richTextMinLines;

  /// Maximum lines from @RichText.
  final int? richTextMaxLines;

  /// Creates a [ResolvedField].
  const ResolvedField({
    required this.name,
    required this.typeName,
    this.isNullable = false,
    this.isRequired = false,
    this.requiredMessage,
    this.isEmail = false,
    this.emailMessage,
    this.minLength,
    this.minLengthMessage,
    this.maxLength,
    this.maxLengthMessage,
    this.pattern,
    this.patternMessage,
    this.min,
    this.minMessage,
    this.max,
    this.maxMessage,
    this.mustMatchField,
    this.mustMatchMessage,
    this.hasAsyncValidator = false,
    this.asyncDebounceMs,
    this.customWidgetType,
    this.isEnum = false,
    this.enumValues,
    // New v1.0.0 properties
    this.formStep,
    this.formStepTitle,
    this.showWhenField,
    this.showWhenEquals,
    this.fieldGroup,
    this.isPhoneNumber = false,
    this.phoneNumberMessage,
    this.isSearchableDropdown = false,
    this.searchableDropdownHintText,
    this.isDateRange = false,
    this.dateRangeFirstDate,
    this.dateRangeLastDate,
    this.dateRangeHelpText,
    this.isSlider = false,
    this.sliderMin,
    this.sliderMax,
    this.sliderDivisions,
    this.sliderLabel,
    this.isRatingInput = false,
    this.ratingMaxStars,
    this.isChipsInput = false,
    this.chipsMaxChips,
    this.chipsAllowCustom,
    this.isColorPicker = false,
    this.colorPickerShowAlpha,
    this.isRichText = false,
    this.richTextMinLines,
    this.richTextMaxLines,
  });

  /// Whether this field has any sync validators.
  bool get hasSyncValidators =>
      isRequired ||
      isEmail ||
      minLength != null ||
      maxLength != null ||
      pattern != null ||
      min != null ||
      max != null ||
      isPhoneNumber;

  /// Whether this field has cross-field validation.
  bool get hasCrossFieldValidation => mustMatchField != null;

  /// Whether this field has a step assignment.
  bool get hasFormStep => formStep != null;

  /// Whether this field has conditional visibility.
  bool get hasShowWhen => showWhenField != null;

  /// Whether this field belongs to a group.
  bool get hasFieldGroup => fieldGroup != null;

  /// Whether this field uses a special field type widget.
  bool get hasSpecialFieldType =>
      isPhoneNumber ||
      isSearchableDropdown ||
      isDateRange ||
      isSlider ||
      isRatingInput ||
      isChipsInput ||
      isColorPicker ||
      isRichText;
}

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
  });

  /// Whether this field has any sync validators.
  bool get hasSyncValidators =>
      isRequired ||
      isEmail ||
      minLength != null ||
      maxLength != null ||
      pattern != null ||
      min != null ||
      max != null;

  /// Whether this field has cross-field validation.
  bool get hasCrossFieldValidation => mustMatchField != null;
}

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/nullability_suffix.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:source_gen/source_gen.dart';

import 'resolved_field.dart';

const _pkg = 'package:form_forge';

/// Resolves fields from a class annotated with @FormForge().
///
/// Reads all instance fields, extracts their types, nullability,
/// and all form_forge validator annotations.
class FieldResolver {
  // Validator checkers
  static final _isRequiredChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/validators/is_required.dart#IsRequired',
  );
  static final _isEmailChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/validators/is_email.dart#IsEmail',
  );
  static final _minLengthChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/validators/min_length.dart#MinLength',
  );
  static final _maxLengthChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/validators/max_length.dart#MaxLength',
  );
  static final _patternChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/validators/pattern.dart#PatternValidator',
  );
  static final _minChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/validators/min.dart#Min',
  );
  static final _maxChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/validators/max.dart#Max',
  );
  static final _mustMatchChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/validators/must_match.dart#MustMatch',
  );
  static final _asyncValidateChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/validators/async_validator.dart#AsyncValidate',
  );
  static final _fieldWidgetChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/field_widget.dart#FieldWidget',
  );

  // New v1.0.0 annotation checkers
  static final _formStepChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/form_step.dart#FormStep',
  );
  static final _showWhenChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/show_when.dart#ShowWhen',
  );
  static final _fieldGroupChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/field_group.dart#FieldGroup',
  );

  // Field type annotation checkers
  static final _phoneNumberChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/field_types/phone_number.dart#PhoneNumber',
  );
  static final _searchableDropdownChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/field_types/searchable_dropdown.dart#SearchableDropdown',
  );
  static final _dateRangeChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/field_types/date_range.dart#DateRange',
  );
  static final _sliderChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/field_types/slider_input.dart#SliderInput',
  );
  static final _ratingInputChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/field_types/rating_input.dart#RatingInput',
  );
  static final _chipsInputChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/field_types/chips_input.dart#ChipsInput',
  );
  static final _colorPickerChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/field_types/color_picker.dart#ColorPicker',
  );
  static final _richTextChecker = TypeChecker.fromUrl(
    '$_pkg/src/annotations/field_types/rich_text_input.dart#RichTextInput',
  );

  /// Resolves all instance fields from the given [classElement].
  ///
  /// Returns a list of [ResolvedField] with all annotations extracted.
  List<ResolvedField> resolve(ClassElement classElement) {
    final fields = <ResolvedField>[];

    for (final field in classElement.fields) {
      // Skip static fields and synthetic fields.
      if (field.isStatic || field.isSynthetic) continue;

      fields.add(_resolveField(field));
    }

    return fields;
  }

  ResolvedField _resolveField(FieldElement field) {
    final typeName = _resolveTypeName(field.type);
    final isNullable =
        field.type.nullabilitySuffix == NullabilitySuffix.question;

    // IsRequired
    final isRequiredAnnotation = _isRequiredChecker.firstAnnotationOf(field);
    final isRequired = isRequiredAnnotation != null;
    final requiredMessage =
        isRequiredAnnotation?.getField('message')?.toStringValue();

    // IsEmail
    final isEmailAnnotation = _isEmailChecker.firstAnnotationOf(field);
    final isEmail = isEmailAnnotation != null;
    final emailMessage =
        isEmailAnnotation?.getField('message')?.toStringValue();

    // MinLength
    final minLengthAnnotation = _minLengthChecker.firstAnnotationOf(field);
    final minLength = minLengthAnnotation?.getField('length')?.toIntValue();
    final minLengthMessage =
        minLengthAnnotation?.getField('message')?.toStringValue();

    // MaxLength
    final maxLengthAnnotation = _maxLengthChecker.firstAnnotationOf(field);
    final maxLength = maxLengthAnnotation?.getField('length')?.toIntValue();
    final maxLengthMessage =
        maxLengthAnnotation?.getField('message')?.toStringValue();

    // Pattern
    final patternAnnotation = _patternChecker.firstAnnotationOf(field);
    final pattern = patternAnnotation?.getField('pattern')?.toStringValue();
    final patternMessage =
        patternAnnotation?.getField('message')?.toStringValue();

    // Min
    final minAnnotation = _minChecker.firstAnnotationOf(field);
    final minValue = minAnnotation?.getField('value');
    final num? min = minValue?.toIntValue() ?? minValue?.toDoubleValue();
    final minMessage = minAnnotation?.getField('message')?.toStringValue();

    // Max
    final maxAnnotation = _maxChecker.firstAnnotationOf(field);
    final maxValue = maxAnnotation?.getField('value');
    final num? max = maxValue?.toIntValue() ?? maxValue?.toDoubleValue();
    final maxMessage = maxAnnotation?.getField('message')?.toStringValue();

    // MustMatch
    final mustMatchAnnotation = _mustMatchChecker.firstAnnotationOf(field);
    final mustMatchField =
        mustMatchAnnotation?.getField('field')?.toStringValue();
    final mustMatchMessage =
        mustMatchAnnotation?.getField('message')?.toStringValue();

    // AsyncValidate
    final asyncAnnotation = _asyncValidateChecker.firstAnnotationOf(field);
    final hasAsyncValidator = asyncAnnotation != null;
    int? asyncDebounceMs;
    if (asyncAnnotation != null) {
      // Check for Duration-based debounce first
      final debounceField = asyncAnnotation.getField('debounce');
      if (debounceField != null && !debounceField.isNull) {
        // Duration is stored as microseconds internally
        final microseconds =
            debounceField.getField('_duration')?.toIntValue() ?? 0;
        asyncDebounceMs = microseconds ~/ 1000;
      } else {
        // Fall back to debounceMs
        asyncDebounceMs = asyncAnnotation.getField('debounceMs')?.toIntValue();
      }
    }

    // FieldWidget
    final widgetAnnotation = _fieldWidgetChecker.firstAnnotationOf(field);
    final customWidgetType = widgetAnnotation
        ?.getField('widgetType')
        ?.toTypeValue()
        ?.getDisplayString();

    // Detect enum types
    final baseType =
        field.type is InterfaceType ? (field.type as InterfaceType) : null;
    final isEnum = baseType?.element is EnumElement;
    final enumValues = isEnum
        ? (baseType!.element as EnumElement)
            .fields
            .where((f) => f.isEnumConstant)
            .map((f) => f.name)
            .toList()
        : null;

    // ========== NEW v1.0.0 ANNOTATIONS ==========

    // FormStep
    final formStepAnnotation = _formStepChecker.firstAnnotationOf(field);
    final formStep = formStepAnnotation?.getField('step')?.toIntValue();
    final formStepTitle =
        formStepAnnotation?.getField('title')?.toStringValue();

    // ShowWhen
    final showWhenAnnotation = _showWhenChecker.firstAnnotationOf(field);
    final showWhenField =
        showWhenAnnotation?.getField('field')?.toStringValue();
    Object? showWhenEquals;
    if (showWhenAnnotation != null) {
      final equalsField = showWhenAnnotation.getField('equals');
      if (equalsField != null && !equalsField.isNull) {
        // Try to extract the value - could be bool, String, int, etc.
        showWhenEquals = equalsField.toBoolValue() ??
            equalsField.toStringValue() ??
            equalsField.toIntValue() ??
            equalsField.toDoubleValue();
      }
    }

    // FieldGroup
    final fieldGroupAnnotation = _fieldGroupChecker.firstAnnotationOf(field);
    final fieldGroup = fieldGroupAnnotation?.getField('name')?.toStringValue();

    // PhoneNumber
    final phoneNumberAnnotation = _phoneNumberChecker.firstAnnotationOf(field);
    final isPhoneNumber = phoneNumberAnnotation != null;
    final phoneNumberMessage =
        phoneNumberAnnotation?.getField('message')?.toStringValue();

    // SearchableDropdown
    final searchableDropdownAnnotation =
        _searchableDropdownChecker.firstAnnotationOf(field);
    final isSearchableDropdown = searchableDropdownAnnotation != null;
    final searchableDropdownHintText =
        searchableDropdownAnnotation?.getField('hintText')?.toStringValue();

    // DateRange
    final dateRangeAnnotation = _dateRangeChecker.firstAnnotationOf(field);
    final isDateRange = dateRangeAnnotation != null;
    final dateRangeFirstDate =
        dateRangeAnnotation?.getField('firstDate')?.toIntValue();
    final dateRangeLastDate =
        dateRangeAnnotation?.getField('lastDate')?.toIntValue();
    final dateRangeHelpText =
        dateRangeAnnotation?.getField('helpText')?.toStringValue();

    // Slider
    final sliderAnnotation = _sliderChecker.firstAnnotationOf(field);
    final isSlider = sliderAnnotation != null;
    final sliderMin = sliderAnnotation?.getField('min')?.toDoubleValue();
    final sliderMax = sliderAnnotation?.getField('max')?.toDoubleValue();
    final sliderDivisions =
        sliderAnnotation?.getField('divisions')?.toIntValue();
    final sliderLabel = sliderAnnotation?.getField('label')?.toStringValue();

    // RatingInput
    final ratingInputAnnotation = _ratingInputChecker.firstAnnotationOf(field);
    final isRatingInput = ratingInputAnnotation != null;
    final ratingMaxStars =
        ratingInputAnnotation?.getField('maxStars')?.toIntValue();

    // ChipsInput
    final chipsInputAnnotation = _chipsInputChecker.firstAnnotationOf(field);
    final isChipsInput = chipsInputAnnotation != null;
    final chipsMaxChips =
        chipsInputAnnotation?.getField('maxChips')?.toIntValue();
    final chipsAllowCustom =
        chipsInputAnnotation?.getField('allowCustom')?.toBoolValue();

    // ColorPicker
    final colorPickerAnnotation = _colorPickerChecker.firstAnnotationOf(field);
    final isColorPicker = colorPickerAnnotation != null;
    final colorPickerShowAlpha =
        colorPickerAnnotation?.getField('showAlpha')?.toBoolValue();

    // RichText
    final richTextAnnotation = _richTextChecker.firstAnnotationOf(field);
    final isRichText = richTextAnnotation != null;
    final richTextMinLines =
        richTextAnnotation?.getField('minLines')?.toIntValue();
    final richTextMaxLines =
        richTextAnnotation?.getField('maxLines')?.toIntValue();

    return ResolvedField(
      name: field.name,
      typeName: typeName,
      isNullable: isNullable,
      isEnum: isEnum,
      enumValues: enumValues,
      isRequired: isRequired,
      requiredMessage: requiredMessage,
      isEmail: isEmail,
      emailMessage: emailMessage,
      minLength: minLength,
      minLengthMessage: minLengthMessage,
      maxLength: maxLength,
      maxLengthMessage: maxLengthMessage,
      pattern: pattern,
      patternMessage: patternMessage,
      min: min,
      minMessage: minMessage,
      max: max,
      maxMessage: maxMessage,
      mustMatchField: mustMatchField,
      mustMatchMessage: mustMatchMessage,
      hasAsyncValidator: hasAsyncValidator,
      asyncDebounceMs: asyncDebounceMs,
      customWidgetType: customWidgetType,
      // New v1.0.0 properties
      formStep: formStep,
      formStepTitle: formStepTitle,
      showWhenField: showWhenField,
      showWhenEquals: showWhenEquals,
      fieldGroup: fieldGroup,
      isPhoneNumber: isPhoneNumber,
      phoneNumberMessage: phoneNumberMessage,
      isSearchableDropdown: isSearchableDropdown,
      searchableDropdownHintText: searchableDropdownHintText,
      isDateRange: isDateRange,
      dateRangeFirstDate: dateRangeFirstDate,
      dateRangeLastDate: dateRangeLastDate,
      dateRangeHelpText: dateRangeHelpText,
      isSlider: isSlider,
      sliderMin: sliderMin,
      sliderMax: sliderMax,
      sliderDivisions: sliderDivisions,
      sliderLabel: sliderLabel,
      isRatingInput: isRatingInput,
      ratingMaxStars: ratingMaxStars,
      isChipsInput: isChipsInput,
      chipsMaxChips: chipsMaxChips,
      chipsAllowCustom: chipsAllowCustom,
      isColorPicker: isColorPicker,
      colorPickerShowAlpha: colorPickerShowAlpha,
      isRichText: isRichText,
      richTextMinLines: richTextMinLines,
      richTextMaxLines: richTextMaxLines,
    );
  }

  String _resolveTypeName(DartType type) {
    // Strip nullability for the base type name.
    final displayString = type.getDisplayString();
    if (displayString.endsWith('?')) {
      return displayString.substring(0, displayString.length - 1);
    }
    return displayString;
  }
}

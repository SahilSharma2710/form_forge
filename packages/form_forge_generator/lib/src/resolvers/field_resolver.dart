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
  static final _isRequiredChecker =
      TypeChecker.fromUrl('$_pkg/src/annotations/validators/is_required.dart#IsRequired');
  static final _isEmailChecker =
      TypeChecker.fromUrl('$_pkg/src/annotations/validators/is_email.dart#IsEmail');
  static final _minLengthChecker =
      TypeChecker.fromUrl('$_pkg/src/annotations/validators/min_length.dart#MinLength');
  static final _maxLengthChecker =
      TypeChecker.fromUrl('$_pkg/src/annotations/validators/max_length.dart#MaxLength');
  static final _patternChecker =
      TypeChecker.fromUrl('$_pkg/src/annotations/validators/pattern.dart#PatternValidator');
  static final _minChecker =
      TypeChecker.fromUrl('$_pkg/src/annotations/validators/min.dart#Min');
  static final _maxChecker =
      TypeChecker.fromUrl('$_pkg/src/annotations/validators/max.dart#Max');
  static final _mustMatchChecker =
      TypeChecker.fromUrl('$_pkg/src/annotations/validators/must_match.dart#MustMatch');
  static final _asyncValidateChecker =
      TypeChecker.fromUrl('$_pkg/src/annotations/validators/async_validator.dart#AsyncValidate');
  static final _fieldWidgetChecker =
      TypeChecker.fromUrl('$_pkg/src/annotations/field_widget.dart#FieldWidget');

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
    final minLength =
        minLengthAnnotation?.getField('length')?.toIntValue();
    final minLengthMessage =
        minLengthAnnotation?.getField('message')?.toStringValue();

    // MaxLength
    final maxLengthAnnotation = _maxLengthChecker.firstAnnotationOf(field);
    final maxLength =
        maxLengthAnnotation?.getField('length')?.toIntValue();
    final maxLengthMessage =
        maxLengthAnnotation?.getField('message')?.toStringValue();

    // Pattern
    final patternAnnotation = _patternChecker.firstAnnotationOf(field);
    final pattern =
        patternAnnotation?.getField('pattern')?.toStringValue();
    final patternMessage =
        patternAnnotation?.getField('message')?.toStringValue();

    // Min
    final minAnnotation = _minChecker.firstAnnotationOf(field);
    final minValue = minAnnotation?.getField('value');
    final num? min = minValue?.toIntValue() ??
        minValue?.toDoubleValue();
    final minMessage =
        minAnnotation?.getField('message')?.toStringValue();

    // Max
    final maxAnnotation = _maxChecker.firstAnnotationOf(field);
    final maxValue = maxAnnotation?.getField('value');
    final num? max = maxValue?.toIntValue() ??
        maxValue?.toDoubleValue();
    final maxMessage =
        maxAnnotation?.getField('message')?.toStringValue();

    // MustMatch
    final mustMatchAnnotation = _mustMatchChecker.firstAnnotationOf(field);
    final mustMatchField =
        mustMatchAnnotation?.getField('field')?.toStringValue();
    final mustMatchMessage =
        mustMatchAnnotation?.getField('message')?.toStringValue();

    // AsyncValidate
    final asyncAnnotation = _asyncValidateChecker.firstAnnotationOf(field);
    final hasAsyncValidator = asyncAnnotation != null;
    final asyncDebounceMs =
        asyncAnnotation?.getField('debounceMs')?.toIntValue();

    // FieldWidget
    final widgetAnnotation = _fieldWidgetChecker.firstAnnotationOf(field);
    final customWidgetType = widgetAnnotation
        ?.getField('widgetType')
        ?.toTypeValue()
        ?.getDisplayString();

    return ResolvedField(
      name: field.name,
      typeName: typeName,
      isNullable: isNullable,
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

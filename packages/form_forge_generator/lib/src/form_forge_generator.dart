import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'resolvers/field_resolver.dart';
import 'resolvers/resolved_field.dart';

/// Type checker for @FormForge annotation — matched by URL, not runtime type,
/// so the generator doesn't depend on Flutter's dart:ui.
const _formForgeChecker = TypeChecker.fromUrl(
  'package:form_forge/src/annotations/form_forge.dart#FormForge',
);

/// Code generator for @FormForge() annotated classes.
///
/// Processes each annotated class and generates:
/// - A `FormController` subclass with field state and validation
/// - A `FormWidget` subclass for rendering the form
/// - A `FormData` class for typed submission
class FormForgeGenerator extends Generator {
  final FieldResolver _fieldResolver = FieldResolver();

  @override
  FutureOr<String?> generate(LibraryReader library, BuildStep buildStep) {
    final buffer = StringBuffer();

    for (final annotatedElement
        in library.annotatedWith(_formForgeChecker)) {
      final element = annotatedElement.element;

      if (element is! ClassElement) {
        throw InvalidGenerationSourceError(
          '@FormForge() can only be applied to classes.',
          element: element,
        );
      }

      final className = element.name;
      final fields = _fieldResolver.resolve(element);

      if (fields.isEmpty) {
        throw InvalidGenerationSourceError(
          '@FormForge() class "$className" must have at least one field.',
          element: element,
        );
      }

      _generateDataClass(buffer, className, fields);
      _generateController(buffer, className, fields);
    }

    final output = buffer.toString();
    return output.isEmpty ? null : output;
  }

  void _generateController(
    StringBuffer buffer,
    String className,
    List<ResolvedField> fields,
  ) {
    final controllerName = '${className}FormController';

    final asyncFields =
        fields.where((f) => f.hasAsyncValidator).toList();

    buffer.writeln('/// Generated form controller for [$className].');
    buffer.writeln(
        'class $controllerName extends FormForgeController {');

    // Field declarations
    for (final field in fields) {
      final dartType =
          field.isNullable ? '${field.typeName}?' : field.typeName;
      final defaultValue = _defaultValueFor(field.typeName, field.isNullable);
      buffer.writeln(
          '  final FormFieldState<$dartType> ${field.name} = '
          'FormFieldState<$dartType>(initialValue: $defaultValue);');
    }
    buffer.writeln();

    // Constructor
    buffer.writeln('  $controllerName() {');
    buffer.writeln('    initializeFields();');
    buffer.writeln('  }');
    buffer.writeln();

    // Fields list override
    buffer.writeln('  @override');
    buffer.writeln('  List<FormFieldState<Object?>> get fields => [');
    for (final field in fields) {
      buffer.writeln('    ${field.name},');
    }
    buffer.writeln('  ];');
    buffer.writeln();

    // Errors map override
    buffer.writeln('  @override');
    buffer.writeln('  Map<String, String?> get errors => {');
    for (final field in fields) {
      buffer.writeln("    '${field.name}': ${field.name}.error,");
    }
    buffer.writeln('  };');
    buffer.writeln();

    // Per-field validation methods
    for (final field in fields) {
      if (field.hasSyncValidators) {
        _generateFieldValidator(buffer, field);
      }
    }

    // Cross-field validation
    final crossFieldFields =
        fields.where((f) => f.hasCrossFieldValidation).toList();
    if (crossFieldFields.isNotEmpty) {
      buffer.writeln(
          '  /// Validates cross-field constraints (Phase 2).');
      buffer.writeln('  void validateCrossFields() {');
      for (final field in crossFieldFields) {
        final msg = field.mustMatchMessage ??
            'Must match ${field.mustMatchField}';
        buffer.writeln(
            '    if (${field.name}.value != ${field.mustMatchField}.value) {');
        buffer.writeln("      ${field.name}.error = '$msg';");
        buffer.writeln('    } else if (${field.name}.error == '
            "'$msg') {");
        buffer.writeln('      ${field.name}.error = null;');
        buffer.writeln('    }');
      }
      buffer.writeln('  }');
      buffer.writeln();
    }

    // Async validation infrastructure (Phase 3)
    if (asyncFields.isNotEmpty) {
      buffer.writeln('  // Async validation state');
      buffer.writeln(
          '  final Map<String, Timer?> _debounceTimers = {};');
      buffer.writeln(
          '  final Map<String, bool> _isFieldValidating = {};');
      buffer.writeln();
      buffer.writeln(
          '  /// Whether any field is currently running async validation.');
      buffer.writeln(
          '  bool get isValidating => _isFieldValidating.values.any((v) => v);');
      buffer.writeln();

      // Async validation method
      buffer.writeln(
          '  /// Runs async validators for all fields that have them.');
      buffer.writeln(
          '  Future<void> validateAsync() async {');
      buffer.writeln('    final futures = <Future<void>>[];');
      for (final field in asyncFields) {
        final debounce = field.asyncDebounceMs ?? 500;
        buffer.writeln(
            '    if (_asyncValidators.containsKey(\'${field.name}\')) {');
        buffer.writeln(
            '      _isFieldValidating[\'${field.name}\'] = true;');
        buffer.writeln('      notifyListeners();');
        buffer.writeln(
            '      futures.add(_asyncValidators[\'${field.name}\']!'
            '(${field.name}.value).then((error) {');
        buffer.writeln(
            '        ${field.name}.error = error;');
        buffer.writeln(
            '        _isFieldValidating[\'${field.name}\'] = false;');
        buffer.writeln('        notifyListeners();');
        buffer.writeln('      }));');
        buffer.writeln('    }');
      }
      buffer.writeln('    await Future.wait(futures);');
      buffer.writeln('  }');
      buffer.writeln();

      // Debounced async trigger
      // Per-field debounce constants
      for (final field in asyncFields) {
        final debounce = field.asyncDebounceMs ?? 500;
        buffer.writeln(
            '  static const int _${field.name}DebounceMs = $debounce;');
      }
      buffer.writeln();

      buffer.writeln(
          '  /// Triggers debounced async validation for a field.');
      buffer.writeln(
          '  void _triggerAsyncValidation(String fieldName, dynamic value, int debounceMs) {');
      buffer.writeln(
          '    _debounceTimers[fieldName]?.cancel();');
      buffer.writeln(
          '    _debounceTimers[fieldName] = Timer(Duration(milliseconds: debounceMs), () {');
      buffer.writeln(
          '      if (_asyncValidators.containsKey(fieldName)) {');
      buffer.writeln(
          '        _isFieldValidating[fieldName] = true;');
      buffer.writeln('        notifyListeners();');
      buffer.writeln(
          '        _asyncValidators[fieldName]!(value).then((error) {');
      buffer.writeln('          // Find field by name and set error');
      for (final field in asyncFields) {
        buffer.writeln(
            "          if (fieldName == '${field.name}') ${field.name}.error = error;");
      }
      buffer.writeln(
          '          _isFieldValidating[fieldName] = false;');
      buffer.writeln('          notifyListeners();');
      buffer.writeln('        });');
      buffer.writeln('      }');
      buffer.writeln('    });');
      buffer.writeln('  }');
      buffer.writeln();

      // Async validator registry
      buffer.writeln(
          '  /// Registry for async validator functions. Set these before using the form.');
      buffer.writeln(
          '  final Map<String, Future<String?> Function(dynamic)> _asyncValidators = {};');
      buffer.writeln();
      buffer.writeln(
          '  /// Registers an async validator for a field.');
      buffer.writeln(
          '  void registerAsyncValidator(String fieldName, Future<String?> Function(dynamic) validator) {');
      buffer.writeln(
          '    _asyncValidators[fieldName] = validator;');
      buffer.writeln('  }');
      buffer.writeln();
    }

    // validateAll method
    final validatedFields =
        fields.where((f) => f.hasSyncValidators).toList();
    final hasAnyValidation =
        validatedFields.isNotEmpty || crossFieldFields.isNotEmpty;
    if (hasAnyValidation) {
      buffer.writeln('  /// Validates all fields and updates error state.');
      buffer.writeln('  void validateAll() {');
      // Phase 1: sync validators
      for (final field in validatedFields) {
        final methodName =
            'validate${field.name[0].toUpperCase()}${field.name.substring(1)}';
        buffer.writeln('    $methodName(${field.name}.value);');
      }
      // Phase 2: cross-field validators
      if (crossFieldFields.isNotEmpty) {
        buffer.writeln('    validateCrossFields();');
      }
      buffer.writeln('  }');
      buffer.writeln();
    }

    // Submission state
    final dataClassName = '${className}FormData';
    buffer.writeln('  bool _isSubmitting = false;');
    buffer.writeln();
    buffer.writeln('  /// Whether the form is currently being submitted.');
    buffer.writeln('  bool get isSubmitting => _isSubmitting;');
    buffer.writeln();

    // Submit method
    buffer.writeln(
        '  /// Validates all fields and calls [onSubmit] with typed form data if valid.');
    buffer.writeln(
        '  Future<void> submit(Future<void> Function($dataClassName data) onSubmit) async {');
    if (hasAnyValidation) {
      buffer.writeln('    validateAll();');
    }
    buffer.writeln('    if (!isValid) return;');
    if (asyncFields.isNotEmpty) {
      buffer.writeln('    await validateAsync();');
      buffer.writeln('    if (!isValid) return;');
    }
    buffer.writeln('    _isSubmitting = true;');
    buffer.writeln('    notifyListeners();');
    buffer.writeln('    try {');
    buffer.writeln('      await onSubmit($dataClassName(');
    for (final field in fields) {
      buffer.writeln('        ${field.name}: ${field.name}.value,');
    }
    buffer.writeln('      ));');
    buffer.writeln('    } finally {');
    buffer.writeln('      _isSubmitting = false;');
    buffer.writeln('      notifyListeners();');
    buffer.writeln('    }');
    buffer.writeln('  }');

    buffer.writeln('}');
  }

  void _generateDataClass(
    StringBuffer buffer,
    String className,
    List<ResolvedField> fields,
  ) {
    final dataClassName = '${className}FormData';

    buffer.writeln('/// Typed form data for [$className].');
    buffer.writeln('class $dataClassName {');

    // Fields
    for (final field in fields) {
      final dartType =
          field.isNullable ? '${field.typeName}?' : field.typeName;
      buffer.writeln('  final $dartType ${field.name};');
    }
    buffer.writeln();

    // Constructor
    buffer.writeln('  const $dataClassName({');
    for (final field in fields) {
      buffer.writeln('    required this.${field.name},');
    }
    buffer.writeln('  });');

    buffer.writeln('}');
    buffer.writeln();
  }

  void _generateFieldValidator(StringBuffer buffer, ResolvedField field) {
    final methodName =
        'validate${field.name[0].toUpperCase()}${field.name.substring(1)}';
    final isStringType = field.typeName == 'String';
    final paramType =
        field.isNullable ? '${field.typeName}?' : field.typeName;

    buffer.writeln(
        '  /// Validates [${field.name}] against its annotation constraints.');
    buffer.writeln('  void $methodName($paramType value) {');

    // IsRequired
    if (field.isRequired) {
      final msg = field.requiredMessage ?? 'This field is required';
      if (isStringType) {
        buffer.writeln("    if (value.isEmpty) {");
      } else if (field.isNullable) {
        buffer.writeln("    if (value == null) {");
      } else {
        // Non-nullable, non-string: always passes required check
        buffer.writeln("    if (false) {");
      }
      buffer.writeln("      ${field.name}.error = '$msg';");
      buffer.writeln('      return;');
      buffer.writeln('    }');
    }

    // IsEmail
    if (field.isEmail) {
      final msg =
          field.emailMessage ?? 'Please enter a valid email address';
      buffer.writeln(
          "    if (!RegExp(r'^[\\w\\-.]+@([\\w-]+\\.)+[\\w-]{2,4}\$')"
          ".hasMatch(value)) {");
      buffer.writeln("      ${field.name}.error = '$msg';");
      buffer.writeln('      return;');
      buffer.writeln('    }');
    }

    // MinLength
    if (field.minLength != null) {
      final msg = field.minLengthMessage ??
          'Must be at least ${field.minLength} characters';
      buffer.writeln(
          '    if (value.length < ${field.minLength}) {');
      buffer.writeln("      ${field.name}.error = '$msg';");
      buffer.writeln('      return;');
      buffer.writeln('    }');
    }

    // MaxLength
    if (field.maxLength != null) {
      final msg = field.maxLengthMessage ??
          'Must be at most ${field.maxLength} characters';
      buffer.writeln(
          '    if (value.length > ${field.maxLength}) {');
      buffer.writeln("      ${field.name}.error = '$msg';");
      buffer.writeln('      return;');
      buffer.writeln('    }');
    }

    // Pattern
    if (field.pattern != null) {
      final msg = field.patternMessage ?? 'Invalid format';
      buffer.writeln(
          "    if (!RegExp(r'${field.pattern}').hasMatch(value)) {");
      buffer.writeln("      ${field.name}.error = '$msg';");
      buffer.writeln('      return;');
      buffer.writeln('    }');
    }

    // Min (numeric)
    if (field.min != null) {
      final msg = field.minMessage ?? 'Must be at least ${field.min}';
      buffer.writeln('    if (value < ${field.min}) {');
      buffer.writeln("      ${field.name}.error = '$msg';");
      buffer.writeln('      return;');
      buffer.writeln('    }');
    }

    // Max (numeric)
    if (field.max != null) {
      final msg = field.maxMessage ?? 'Must be at most ${field.max}';
      buffer.writeln('    if (value > ${field.max}) {');
      buffer.writeln("      ${field.name}.error = '$msg';");
      buffer.writeln('      return;');
      buffer.writeln('    }');
    }

    // Clear error if all validations pass
    buffer.writeln('    ${field.name}.error = null;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  String _defaultValueFor(String typeName, bool isNullable) {
    if (isNullable) return 'null';
    switch (typeName) {
      case 'String':
        return "''";
      case 'int':
        return '0';
      case 'double':
        return '0.0';
      case 'bool':
        return 'false';
      case 'DateTime':
        return 'DateTime.now()';
      default:
        return 'null';
    }
  }
}

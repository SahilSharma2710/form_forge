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

    for (final annotatedElement in library.annotatedWith(_formForgeChecker)) {
      final element = annotatedElement.element;

      if (element is! ClassElement) {
        throw InvalidGenerationSourceError(
          '@FormForge() can only be applied to classes.',
          element: element,
        );
      }

      final className = element.name;
      final fields = _fieldResolver.resolve(element);

      // Extract @FormForge annotation parameters
      final annotation = annotatedElement.annotation;
      final persistKeyReader = annotation.read('persistKey');
      final persistKey =
          persistKeyReader.isNull ? null : persistKeyReader.stringValue;

      if (fields.isEmpty) {
        throw InvalidGenerationSourceError(
          '@FormForge() class "$className" must have at least one field.',
          element: element,
        );
      }

      // Determine form structure
      final hasSteps = fields.any((f) => f.hasFormStep);
      final hasGroups = fields.any((f) => f.hasFieldGroup);
      final hasShowWhen = fields.any((f) => f.hasShowWhen);

      _generateDataClass(buffer, className, fields);
      _generateController(buffer, className, fields, persistKey);
      _generateWidget(
        buffer,
        className,
        fields,
        hasSteps: hasSteps,
        hasGroups: hasGroups,
        hasShowWhen: hasShowWhen,
        persistKey: persistKey,
      );
    }

    final output = buffer.toString();
    return output.isEmpty ? null : output;
  }

  void _generateController(
    StringBuffer buffer,
    String className,
    List<ResolvedField> fields,
    String? persistKey,
  ) {
    final controllerName = '${_generatedPrefix(className)}FormController';
    final dataClassName = '${_generatedPrefix(className)}FormData';

    final asyncFields = fields.where((f) => f.hasAsyncValidator).toList();
    final hasSteps = fields.any((f) => f.hasFormStep);

    buffer.writeln('/// Generated form controller for [$className].');
    buffer.writeln('class $controllerName extends FormForgeController {');

    // Field declarations
    for (final field in fields) {
      final dartType =
          field.isNullable ? '${field.typeName}?' : field.typeName;
      final defaultValue = _defaultValueFor(field);
      buffer.writeln(
        '  /// Field state for [${field.name}].',
      );
      buffer.writeln(
        '  final ForgeFieldState<$dartType> ${field.name} = '
        'ForgeFieldState<$dartType>(initialValue: $defaultValue);',
      );
    }
    buffer.writeln();

    // FocusNode declarations
    buffer.writeln('  // FocusNodes for field navigation');
    for (final field in fields) {
      buffer.writeln('  /// FocusNode for [${field.name}] field.');
      buffer.writeln('  final FocusNode ${field.name}FocusNode = FocusNode();');
    }
    buffer.writeln();

    // Step management (if multi-step form)
    if (hasSteps) {
      final stepSet = <int>{};
      for (final f in fields) {
        if (f.formStep != null) stepSet.add(f.formStep!);
      }
      final maxStep =
          stepSet.isEmpty ? 0 : stepSet.reduce((a, b) => a > b ? a : b);
      buffer.writeln('  int _currentStep = 0;');
      buffer.writeln();
      buffer.writeln('  /// Gets the current step index.');
      buffer.writeln('  int get currentStep => _currentStep;');
      buffer.writeln();
      buffer.writeln('  /// Total number of steps in the form.');
      buffer.writeln('  int get totalSteps => ${maxStep + 1};');
      buffer.writeln();
      buffer.writeln('  /// Sets the current step and notifies listeners.');
      buffer.writeln('  set currentStep(int value) {');
      buffer.writeln(
          '    if (_currentStep != value && value >= 0 && value < totalSteps) {');
      buffer.writeln('      _currentStep = value;');
      buffer.writeln('      notifyListeners();');
      buffer.writeln('    }');
      buffer.writeln('  }');
      buffer.writeln();
      buffer.writeln('  /// Advances to the next step if current step is valid.');
      buffer.writeln('  bool nextStep() {');
      buffer.writeln(
          '    if (validateCurrentStep() && _currentStep < totalSteps - 1) {');
      buffer.writeln('      _currentStep++;');
      buffer.writeln('      notifyListeners();');
      buffer.writeln('      return true;');
      buffer.writeln('    }');
      buffer.writeln('    return false;');
      buffer.writeln('  }');
      buffer.writeln();
      buffer.writeln('  /// Goes back to the previous step.');
      buffer.writeln('  bool previousStep() {');
      buffer.writeln('    if (_currentStep > 0) {');
      buffer.writeln('      _currentStep--;');
      buffer.writeln('      notifyListeners();');
      buffer.writeln('      return true;');
      buffer.writeln('    }');
      buffer.writeln('    return false;');
      buffer.writeln('  }');
      buffer.writeln();
      buffer.writeln('  /// Whether the user can proceed to the next step.');
      buffer.writeln('  bool get canGoNext => _currentStep < totalSteps - 1;');
      buffer.writeln();
      buffer.writeln('  /// Whether the user can go back to the previous step.');
      buffer.writeln('  bool get canGoBack => _currentStep > 0;');
      buffer.writeln();

      // Generate step titles map
      buffer.writeln('  /// Map of step indices to their titles.');
      buffer.writeln('  Map<int, String> get stepTitles => {');
      final stepTitles = <int, String>{};
      for (final f in fields) {
        if (f.formStep != null && f.formStepTitle != null) {
          stepTitles[f.formStep!] = f.formStepTitle!;
        }
      }
      for (final entry in stepTitles.entries) {
        buffer.writeln("    ${entry.key}: '${entry.value}',");
      }
      buffer.writeln('  };');
      buffer.writeln();
    }

    // Constructor
    buffer.writeln('  /// Creates a [$controllerName].');
    buffer.writeln('  $controllerName() {');
    buffer.writeln('    initializeFields();');
    buffer.writeln('  }');
    buffer.writeln();

    // Fields list override
    buffer.writeln('  @override');
    buffer.writeln('  List<ForgeFieldState<Object?>> get fields => [');
    for (final field in fields) {
      buffer.writeln('    ${field.name},');
    }
    buffer.writeln('  ];');
    buffer.writeln();

    // Field names list
    buffer.writeln('  /// List of field names in order.');
    buffer.writeln('  static const List<String> fieldNames = [');
    for (final field in fields) {
      buffer.writeln("    '${field.name}',");
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
      buffer.writeln('  /// Validates cross-field constraints (Phase 2).');
      buffer.writeln('  void validateCrossFields() {');
      for (final field in crossFieldFields) {
        final msg =
            field.mustMatchMessage ?? 'Must match ${field.mustMatchField}';
        buffer.writeln(
          '    if (${field.name}.value != ${field.mustMatchField}.value) {',
        );
        buffer.writeln("      ${field.name}.error = '$msg';");
        buffer.writeln(
          '    } else if (${field.name}.error == '
          "'$msg') {",
        );
        buffer.writeln('      ${field.name}.error = null;');
        buffer.writeln('    }');
      }
      buffer.writeln('  }');
      buffer.writeln();
    }

    // Async validation infrastructure (Phase 3)
    if (asyncFields.isNotEmpty) {
      buffer.writeln('  // Async validation state');
      buffer.writeln('  final Map<String, Timer?> _debounceTimers = {};');
      buffer.writeln();
      buffer.writeln(
        '  /// Whether any field is currently running async validation.',
      );
      buffer.writeln(
        '  bool get isValidating => fields.any((f) => f.isValidating);',
      );
      buffer.writeln();

      // Field-specific isValidating getters
      for (final field in asyncFields) {
        final capName = field.name[0].toUpperCase() + field.name.substring(1);
        buffer.writeln(
          '  /// Whether [${field.name}] is currently validating asynchronously.',
        );
        buffer.writeln(
            '  bool get is${capName}Validating => ${field.name}.isValidating;');
      }
      buffer.writeln();

      // Async validation method
      buffer.writeln(
        '  /// Runs async validators for all fields that have them.',
      );
      buffer.writeln('  Future<void> validateAsync() async {');
      buffer.writeln('    final futures = <Future<void>>[];');
      for (final field in asyncFields) {
        buffer.writeln(
          "    if (_asyncValidators.containsKey('${field.name}')) {",
        );
        buffer.writeln('      ${field.name}.isValidating = true;');
        buffer.writeln(
          "      futures.add(_asyncValidators['${field.name}']!"
          '(${field.name}.value).then((error) {',
        );
        buffer.writeln('        ${field.name}.error = error;');
        buffer.writeln('        ${field.name}.isValidating = false;');
        buffer.writeln('      }));');
        buffer.writeln('    }');
      }
      buffer.writeln('    await Future.wait(futures);');
      buffer.writeln('    notifyListeners();');
      buffer.writeln('  }');
      buffer.writeln();

      // Debounced async trigger
      buffer.writeln('  /// Triggers debounced async validation for a field.');
      buffer.writeln(
        '  void _triggerAsyncValidation(String fieldName, dynamic value, int debounceMs) {',
      );
      buffer.writeln('    _debounceTimers[fieldName]?.cancel();');
      buffer.writeln(
        '    _debounceTimers[fieldName] = Timer(Duration(milliseconds: debounceMs), () async {',
      );
      buffer.writeln('      if (_asyncValidators.containsKey(fieldName)) {');
      // Set validating state
      for (final field in asyncFields) {
        buffer.writeln(
          "        if (fieldName == '${field.name}') ${field.name}.isValidating = true;",
        );
      }
      buffer.writeln('        notifyListeners();');
      buffer.writeln(
        '        final error = await _asyncValidators[fieldName]!(value);',
      );
      // Set error and clear validating
      for (final field in asyncFields) {
        buffer.writeln(
          "        if (fieldName == '${field.name}') {",
        );
        buffer.writeln('          ${field.name}.error = error;');
        buffer.writeln('          ${field.name}.isValidating = false;');
        buffer.writeln('        }');
      }
      buffer.writeln('        notifyListeners();');
      buffer.writeln('      }');
      buffer.writeln('    });');
      buffer.writeln('  }');
      buffer.writeln();

      // Async validator registry
      buffer.writeln(
        '  /// Registry for async validator functions.',
      );
      buffer.writeln(
        '  final Map<String, Future<String?> Function(dynamic)> _asyncValidators = {};',
      );
      buffer.writeln();
      buffer.writeln('  /// Registers an async validator for a field.');
      buffer.writeln(
        '  void registerAsyncValidator(String fieldName, Future<String?> Function(dynamic) validator) {',
      );
      buffer.writeln('    _asyncValidators[fieldName] = validator;');
      buffer.writeln('  }');
      buffer.writeln();
    }

    // validateAll method
    final validatedFields = fields.where((f) => f.hasSyncValidators).toList();
    final hasAnyValidation =
        validatedFields.isNotEmpty || crossFieldFields.isNotEmpty;
    if (hasAnyValidation) {
      buffer.writeln('  /// Validates all fields and updates error state.');
      buffer.writeln('  void validateAll() {');
      buffer.writeln('    if (!isEnabled) return;');
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

    // validateCurrentStep method (for multi-step forms)
    if (hasSteps) {
      buffer.writeln('  /// Validates only the fields in the current step.');
      buffer.writeln('  bool validateCurrentStep() {');
      buffer.writeln('    if (!isEnabled) return true;');

      // Group fields by step and validate
      final stepGroups = <int, List<ResolvedField>>{};
      for (final f in fields) {
        final step = f.formStep ?? 0;
        stepGroups.putIfAbsent(step, () => []).add(f);
      }

      buffer.writeln('    switch (_currentStep) {');
      for (final entry in stepGroups.entries) {
        buffer.writeln('      case ${entry.key}:');
        for (final field in entry.value) {
          if (field.hasSyncValidators) {
            final methodName =
                'validate${field.name[0].toUpperCase()}${field.name.substring(1)}';
            buffer.writeln('        $methodName(${field.name}.value);');
          }
        }
        // Check validity of step fields
        buffer.write('        return ');
        final stepFieldNames = entry.value.map((f) => '${f.name}.isValid');
        buffer.writeln('${stepFieldNames.join(' && ')};');
      }
      buffer.writeln('      default:');
      buffer.writeln('        return true;');
      buffer.writeln('    }');
      buffer.writeln('  }');
      buffer.writeln();
    }

    // Submission state
    buffer.writeln('  bool _isSubmitting = false;');
    buffer.writeln();
    buffer.writeln('  /// Whether the form is currently being submitted.');
    buffer.writeln('  bool get isSubmitting => _isSubmitting;');
    buffer.writeln();

    // Submit method
    buffer.writeln(
      '  /// Validates all fields and calls [onSubmit] with typed form data if valid.',
    );
    buffer.writeln(
      '  Future<void> submit(Future<void> Function($dataClassName data) onSubmit) async {',
    );
    buffer.writeln('    if (!isEnabled) return;');
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
    buffer.writeln();

    // toJson method
    _generateToJson(buffer, fields);

    // fromJson method
    _generateFromJson(buffer, controllerName, fields);

    // copyWith method
    _generateCopyWith(buffer, controllerName, fields);

    // populateFrom method
    _generatePopulateFrom(buffer, dataClassName, fields);

    // Focus management: move to next field
    buffer.writeln('  /// Moves focus to the next field in the form.');
    buffer.writeln('  void focusNextField(String currentFieldName) {');
    buffer.writeln(
        '    final currentIndex = fieldNames.indexOf(currentFieldName);');
    buffer.writeln(
        '    if (currentIndex >= 0 && currentIndex < fieldNames.length - 1) {');
    buffer.writeln(
        '      final nextFieldName = fieldNames[currentIndex + 1];');
    buffer.writeln('      _getFocusNodeByName(nextFieldName)?.requestFocus();');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();

    buffer.writeln('  FocusNode? _getFocusNodeByName(String name) {');
    buffer.writeln('    switch (name) {');
    for (final field in fields) {
      buffer.writeln("      case '${field.name}':");
      buffer.writeln('        return ${field.name}FocusNode;');
    }
    buffer.writeln('      default:');
    buffer.writeln('        return null;');
    buffer.writeln('    }');
    buffer.writeln('  }');
    buffer.writeln();

    // Dispose override to clean up FocusNodes and timers
    buffer.writeln('  @override');
    buffer.writeln('  void dispose() {');
    for (final field in fields) {
      buffer.writeln('    ${field.name}FocusNode.dispose();');
    }
    if (asyncFields.isNotEmpty) {
      buffer.writeln('    for (final timer in _debounceTimers.values) {');
      buffer.writeln('      timer?.cancel();');
      buffer.writeln('    }');
    }
    buffer.writeln('    super.dispose();');
    buffer.writeln('  }');

    buffer.writeln('}');
    buffer.writeln();
  }

  void _generateToJson(StringBuffer buffer, List<ResolvedField> fields) {
    buffer.writeln('  /// Serializes the form data to a JSON-compatible map.');
    buffer.writeln('  Map<String, dynamic> toJson() {');
    buffer.writeln('    return {');
    for (final field in fields) {
      final jsonValue = _jsonSerializeValue(field);
      buffer.writeln("      '${field.name}': $jsonValue,");
    }
    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln();
  }

  String _jsonSerializeValue(ResolvedField field) {
    final value = '${field.name}.value';
    if (field.typeName == 'DateTime') {
      if (field.isNullable) {
        return '$value?.toIso8601String()';
      }
      return '$value.toIso8601String()';
    } else if (field.typeName == 'DateTimeRange') {
      if (field.isNullable) {
        return "$value != null ? {'start': $value!.start.toIso8601String(), 'end': $value!.end.toIso8601String()} : null";
      }
      return "{'start': $value.start.toIso8601String(), 'end': $value.end.toIso8601String()}";
    } else if (field.typeName == 'Color') {
      if (field.isNullable) {
        return '$value?.value';
      }
      return '$value.value';
    } else if (field.isEnum) {
      if (field.isNullable) {
        return '$value?.name';
      }
      return '$value.name';
    } else if (field.typeName.startsWith('List<')) {
      return value;
    }
    return value;
  }

  void _generateFromJson(
    StringBuffer buffer,
    String controllerName,
    List<ResolvedField> fields,
  ) {
    buffer.writeln('  /// Populates the form from a JSON-compatible map.');
    buffer.writeln('  void fromJson(Map<String, dynamic> json) {');
    for (final field in fields) {
      final jsonKey = "'${field.name}'";
      buffer.writeln('    if (json.containsKey($jsonKey)) {');
      _writeJsonDeserialize(buffer, field, 'json[$jsonKey]');
      buffer.writeln('    }');
    }
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _writeJsonDeserialize(
    StringBuffer buffer,
    ResolvedField field,
    String jsonExpr,
  ) {
    final fieldValue = '${field.name}.value';

    if (field.typeName == 'DateTime') {
      if (field.isNullable) {
        buffer.writeln(
          '      $fieldValue = $jsonExpr != null ? DateTime.parse($jsonExpr as String) : null;',
        );
      } else {
        buffer.writeln(
          '      $fieldValue = DateTime.parse($jsonExpr as String);',
        );
      }
    } else if (field.typeName == 'DateTimeRange') {
      if (field.isNullable) {
        buffer.writeln('      if ($jsonExpr != null) {');
        buffer.writeln(
            '        final range = $jsonExpr as Map<String, dynamic>;');
        buffer.writeln(
          "        $fieldValue = DateTimeRange(start: DateTime.parse(range['start'] as String), end: DateTime.parse(range['end'] as String));",
        );
        buffer.writeln('      } else {');
        buffer.writeln('        $fieldValue = null;');
        buffer.writeln('      }');
      } else {
        buffer
            .writeln('      final range = $jsonExpr as Map<String, dynamic>;');
        buffer.writeln(
          "      $fieldValue = DateTimeRange(start: DateTime.parse(range['start'] as String), end: DateTime.parse(range['end'] as String));",
        );
      }
    } else if (field.typeName == 'Color') {
      if (field.isNullable) {
        buffer.writeln(
          '      $fieldValue = $jsonExpr != null ? Color($jsonExpr as int) : null;',
        );
      } else {
        buffer.writeln('      $fieldValue = Color($jsonExpr as int);');
      }
    } else if (field.isEnum) {
      if (field.isNullable) {
        buffer.writeln(
          '      $fieldValue = $jsonExpr != null ? ${field.typeName}.values.byName($jsonExpr as String) : null;',
        );
      } else {
        buffer.writeln(
          '      $fieldValue = ${field.typeName}.values.byName($jsonExpr as String);',
        );
      }
    } else if (field.typeName == 'int') {
      buffer.writeln('      $fieldValue = ($jsonExpr as num).toInt();');
    } else if (field.typeName == 'double') {
      buffer.writeln('      $fieldValue = ($jsonExpr as num).toDouble();');
    } else if (field.typeName == 'List<String>') {
      buffer.writeln(
        '      $fieldValue = List<String>.from($jsonExpr as List);',
      );
    } else {
      buffer.writeln('      $fieldValue = $jsonExpr as ${field.typeName};');
    }
  }

  void _generateCopyWith(
    StringBuffer buffer,
    String controllerName,
    List<ResolvedField> fields,
  ) {
    buffer.writeln(
        '  /// Creates a new controller with values copied from this one.');
    buffer.writeln('  $controllerName copyWith({');
    for (final field in fields) {
      final dartType =
          field.isNullable ? '${field.typeName}?' : '${field.typeName}?';
      buffer.writeln('    $dartType ${field.name},');
    }
    buffer.writeln('  }) {');
    buffer.writeln('    final copy = $controllerName();');
    for (final field in fields) {
      buffer.writeln(
        '    copy.${field.name}.value = ${field.name} ?? this.${field.name}.value;',
      );
    }
    buffer.writeln('    return copy;');
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generatePopulateFrom(
    StringBuffer buffer,
    String dataClassName,
    List<ResolvedField> fields,
  ) {
    buffer
        .writeln('  /// Populates the form from a [$dataClassName] instance.');
    buffer.writeln('  void populateFrom($dataClassName data) {');
    for (final field in fields) {
      buffer.writeln('    ${field.name}.value = data.${field.name};');
    }
    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateDataClass(
    StringBuffer buffer,
    String className,
    List<ResolvedField> fields,
  ) {
    final dataClassName = '${_generatedPrefix(className)}FormData';

    buffer.writeln('/// Typed form data for [$className].');
    buffer.writeln('class $dataClassName {');

    // Fields
    for (final field in fields) {
      final dartType =
          field.isNullable ? '${field.typeName}?' : field.typeName;
      buffer.writeln('  /// The value for [${field.name}].');
      buffer.writeln('  final $dartType ${field.name};');
    }
    buffer.writeln();

    // Constructor
    buffer.writeln('  /// Creates a [$dataClassName].');
    buffer.writeln('  const $dataClassName({');
    for (final field in fields) {
      buffer.writeln('    required this.${field.name},');
    }
    buffer.writeln('  });');
    buffer.writeln();

    // toJson on data class
    buffer.writeln('  /// Serializes the form data to a JSON-compatible map.');
    buffer.writeln('  Map<String, dynamic> toJson() {');
    buffer.writeln('    return {');
    for (final field in fields) {
      final jsonValue = _dataJsonSerializeValue(field);
      buffer.writeln("      '${field.name}': $jsonValue,");
    }
    buffer.writeln('    };');
    buffer.writeln('  }');
    buffer.writeln();

    // fromJson factory on data class
    buffer
        .writeln('  /// Creates a [$dataClassName] from a JSON-compatible map.');
    buffer
        .writeln('  factory $dataClassName.fromJson(Map<String, dynamic> json) {');
    buffer.writeln('    return $dataClassName(');
    for (final field in fields) {
      final jsonKey = "'${field.name}'";
      final deserialize = _dataJsonDeserialize(field, 'json[$jsonKey]');
      buffer.writeln('      ${field.name}: $deserialize,');
    }
    buffer.writeln('    );');
    buffer.writeln('  }');
    buffer.writeln();

    // copyWith on data class
    buffer.writeln('  /// Creates a copy with the given fields replaced.');
    buffer.writeln('  $dataClassName copyWith({');
    for (final field in fields) {
      final dartType = '${field.typeName}?';
      buffer.writeln('    $dartType ${field.name},');
    }
    buffer.writeln('  }) {');
    buffer.writeln('    return $dataClassName(');
    for (final field in fields) {
      buffer.writeln(
        '      ${field.name}: ${field.name} ?? this.${field.name},',
      );
    }
    buffer.writeln('    );');
    buffer.writeln('  }');

    buffer.writeln('}');
    buffer.writeln();
  }

  String _dataJsonSerializeValue(ResolvedField field) {
    final value = field.name;
    if (field.typeName == 'DateTime') {
      if (field.isNullable) {
        return '$value?.toIso8601String()';
      }
      return '$value.toIso8601String()';
    } else if (field.typeName == 'DateTimeRange') {
      if (field.isNullable) {
        return "$value != null ? {'start': $value!.start.toIso8601String(), 'end': $value!.end.toIso8601String()} : null";
      }
      return "{'start': $value.start.toIso8601String(), 'end': $value.end.toIso8601String()}";
    } else if (field.typeName == 'Color') {
      if (field.isNullable) {
        return '$value?.value';
      }
      return '$value.value';
    } else if (field.isEnum) {
      if (field.isNullable) {
        return '$value?.name';
      }
      return '$value.name';
    }
    return value;
  }

  String _dataJsonDeserialize(ResolvedField field, String jsonExpr) {
    if (field.typeName == 'DateTime') {
      if (field.isNullable) {
        return '$jsonExpr != null ? DateTime.parse($jsonExpr as String) : null';
      }
      return 'DateTime.parse($jsonExpr as String)';
    } else if (field.typeName == 'DateTimeRange') {
      if (field.isNullable) {
        return "$jsonExpr != null ? DateTimeRange(start: DateTime.parse((\$jsonExpr as Map)['start'] as String), end: DateTime.parse((\$jsonExpr as Map)['end'] as String)) : null";
      }
      return "DateTimeRange(start: DateTime.parse(($jsonExpr as Map)['start'] as String), end: DateTime.parse(($jsonExpr as Map)['end'] as String))";
    } else if (field.typeName == 'Color') {
      if (field.isNullable) {
        return '$jsonExpr != null ? Color($jsonExpr as int) : null';
      }
      return 'Color($jsonExpr as int)';
    } else if (field.isEnum) {
      if (field.isNullable) {
        return '$jsonExpr != null ? ${field.typeName}.values.byName($jsonExpr as String) : null';
      }
      return '${field.typeName}.values.byName($jsonExpr as String)';
    } else if (field.typeName == 'int') {
      if (field.isNullable) {
        return '$jsonExpr != null ? ($jsonExpr as num).toInt() : null';
      }
      return '($jsonExpr as num).toInt()';
    } else if (field.typeName == 'double') {
      if (field.isNullable) {
        return '$jsonExpr != null ? ($jsonExpr as num).toDouble() : null';
      }
      return '($jsonExpr as num).toDouble()';
    } else if (field.typeName == 'List<String>') {
      if (field.isNullable) {
        return '$jsonExpr != null ? List<String>.from($jsonExpr as List) : null';
      }
      return 'List<String>.from($jsonExpr as List)';
    } else {
      if (field.isNullable) {
        return '$jsonExpr as ${field.typeName}?';
      }
      return '$jsonExpr as ${field.typeName}';
    }
  }

  void _generateFieldValidator(StringBuffer buffer, ResolvedField field) {
    final methodName =
        'validate${field.name[0].toUpperCase()}${field.name.substring(1)}';
    final isStringType = field.typeName == 'String';
    final paramType = field.isNullable ? '${field.typeName}?' : field.typeName;

    buffer.writeln(
      '  /// Validates [${field.name}] against its annotation constraints.',
    );
    buffer.writeln('  void $methodName($paramType value) {');
    buffer.writeln('    if (!${field.name}.isEnabled) return;');

    // IsRequired
    if (field.isRequired) {
      final msg = field.requiredMessage ?? 'This field is required';
      if (isStringType && !field.isNullable) {
        buffer.writeln("    if (value.isEmpty) {");
      } else if (isStringType && field.isNullable) {
        buffer.writeln("    if (value == null || value.isEmpty) {");
      } else if (field.isNullable) {
        buffer.writeln("    if (value == null) {");
      } else {
        buffer.writeln(
          "    // Required check skipped: non-nullable ${field.typeName} always has a value.",
        );
        buffer.writeln(
          "    // Consider making the field nullable if you need an 'unset' state.",
        );
      }
      if (isStringType || field.isNullable) {
        buffer.writeln("      ${field.name}.error = '$msg';");
        buffer.writeln('      return;');
        buffer.writeln('    }');
      }
    }

    // IsEmail
    if (field.isEmail) {
      final msg = field.emailMessage ?? 'Please enter a valid email address';
      buffer.writeln(
        "    if (!RegExp(r'^[\\w\\-.]+@([\\w-]+\\.)+[\\w-]{2,4}\$')"
        ".hasMatch(value)) {",
      );
      buffer.writeln("      ${field.name}.error = '$msg';");
      buffer.writeln('      return;');
      buffer.writeln('    }');
    }

    // PhoneNumber
    if (field.isPhoneNumber) {
      final msg =
          field.phoneNumberMessage ?? 'Please enter a valid phone number';
      buffer.writeln(
        "    if (!RegExp(r'^[+]?[0-9\\s\\-().]{7,20}\$').hasMatch(value)) {",
      );
      buffer.writeln("      ${field.name}.error = '$msg';");
      buffer.writeln('      return;');
      buffer.writeln('    }');
    }

    // MinLength
    if (field.minLength != null) {
      final msg = field.minLengthMessage ??
          'Must be at least ${field.minLength} characters';
      buffer.writeln('    if (value.length < ${field.minLength}) {');
      buffer.writeln("      ${field.name}.error = '$msg';");
      buffer.writeln('      return;');
      buffer.writeln('    }');
    }

    // MaxLength
    if (field.maxLength != null) {
      final msg = field.maxLengthMessage ??
          'Must be at most ${field.maxLength} characters';
      buffer.writeln('    if (value.length > ${field.maxLength}) {');
      buffer.writeln("      ${field.name}.error = '$msg';");
      buffer.writeln('      return;');
      buffer.writeln('    }');
    }

    // Pattern
    if (field.pattern != null) {
      final msg = field.patternMessage ?? 'Invalid format';
      if (field.isNullable) {
        buffer.writeln(
          "    if (value != null && !RegExp(r'${field.pattern}').hasMatch(value)) {",
        );
      } else {
        buffer.writeln(
          "    if (!RegExp(r'${field.pattern}').hasMatch(value)) {",
        );
      }
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

  void _generateWidget(
    StringBuffer buffer,
    String className,
    List<ResolvedField> fields, {
    required bool hasSteps,
    required bool hasGroups,
    required bool hasShowWhen,
    String? persistKey,
  }) {
    final widgetName = '${_generatedPrefix(className)}FormWidget';
    final controllerName = '${_generatedPrefix(className)}FormController';

    buffer.writeln();
    buffer.writeln('/// Generated form widget for [$className].');
    buffer.writeln('class $widgetName extends StatefulWidget {');
    buffer.writeln('  /// The form controller managing state and validation.');
    buffer.writeln('  final $controllerName controller;');
    buffer.writeln();
    buffer.writeln('  /// Creates a [$widgetName].');
    buffer.writeln(
      '  const $widgetName({super.key, required this.controller});',
    );
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln(
      '  State<$widgetName> createState() => _${widgetName}State();',
    );
    buffer.writeln('}');
    buffer.writeln();

    // State class
    buffer.writeln('class _${widgetName}State extends State<$widgetName> {');
    buffer.writeln();

    // Persistence support
    if (persistKey != null) {
      buffer.writeln('  @override');
      buffer.writeln('  void initState() {');
      buffer.writeln('    super.initState();');
      buffer.writeln('    _loadPersistedData();');
      buffer.writeln('    widget.controller.addListener(_persistData);');
      buffer.writeln('  }');
      buffer.writeln();
      buffer.writeln('  Future<void> _loadPersistedData() async {');
      buffer.writeln(
        "    final prefs = await SharedPreferences.getInstance();",
      );
      buffer.writeln("    final jsonString = prefs.getString('$persistKey');");
      buffer.writeln('    if (jsonString != null) {');
      buffer.writeln('      try {');
      buffer.writeln(
        '        final json = jsonDecode(jsonString) as Map<String, dynamic>;',
      );
      buffer.writeln('        widget.controller.fromJson(json);');
      buffer.writeln('      } catch (_) {}');
      buffer.writeln('    }');
      buffer.writeln('  }');
      buffer.writeln();
      buffer.writeln('  void _persistData() {');
      buffer.writeln(
        "    SharedPreferences.getInstance().then((prefs) {",
      );
      buffer.writeln(
        "      prefs.setString('$persistKey', jsonEncode(widget.controller.toJson()));",
      );
      buffer.writeln('    });');
      buffer.writeln('  }');
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln('  void dispose() {');
      buffer.writeln('    widget.controller.removeListener(_persistData);');
      buffer.writeln('    super.dispose();');
      buffer.writeln('  }');
      buffer.writeln();
    }

    // Per-field builder methods
    for (final field in fields) {
      _generateFieldBuilder(buffer, field, fields);
    }

    // Build method
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');
    buffer.writeln('    final theme = FormForgeTheme.of(context);');
    buffer.writeln('    return AnimatedBuilder(');
    buffer.writeln('      animation: widget.controller,');
    buffer.writeln('      builder: (context, _) {');

    if (hasSteps) {
      _generateStepperBuild(buffer, fields);
    } else if (hasGroups) {
      _generateGroupedBuild(buffer, fields);
    } else {
      _generateSimpleBuild(buffer, fields, hasShowWhen);
    }

    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln('  }');

    buffer.writeln('}');
  }

  void _generateSimpleBuild(
    StringBuffer buffer,
    List<ResolvedField> fields,
    bool hasShowWhen,
  ) {
    buffer.writeln('        return Padding(');
    buffer.writeln('          padding: theme.formPadding ?? EdgeInsets.zero,');
    buffer.writeln('          child: Form(');
    buffer.writeln('            child: Column(');
    buffer.writeln(
      '              crossAxisAlignment: CrossAxisAlignment.stretch,',
    );
    buffer.writeln('              children: [');
    for (final field in fields) {
      final methodName =
          '_build${field.name[0].toUpperCase()}${field.name.substring(1)}Field';
      if (field.hasShowWhen) {
        buffer.writeln(
          '                if (_shouldShow${field.name[0].toUpperCase()}${field.name.substring(1)}()) $methodName(),',
        );
      } else {
        buffer.writeln('                $methodName(),');
      }
    }
    buffer.writeln('              ],');
    buffer.writeln('            ),');
    buffer.writeln('          ),');
    buffer.writeln('        );');
  }

  void _generateGroupedBuild(StringBuffer buffer, List<ResolvedField> fields) {
    // Group fields by their group name
    final groups = <String?, List<ResolvedField>>{};
    for (final field in fields) {
      groups.putIfAbsent(field.fieldGroup, () => []).add(field);
    }

    buffer.writeln('        return Padding(');
    buffer.writeln('          padding: theme.formPadding ?? EdgeInsets.zero,');
    buffer.writeln('          child: Form(');
    buffer.writeln('            child: Column(');
    buffer.writeln(
      '              crossAxisAlignment: CrossAxisAlignment.stretch,',
    );
    buffer.writeln('              children: [');

    for (final entry in groups.entries) {
      final groupName = entry.key;
      final groupFields = entry.value;

      if (groupName != null) {
        // Render group header
        buffer.writeln('                Padding(');
        buffer.writeln(
          '                  padding: theme.groupPadding ?? const EdgeInsets.only(top: 16, bottom: 8),',
        );
        buffer.writeln('                  child: Text(');
        buffer.writeln("                    '$groupName',");
        buffer.writeln(
          '                    style: theme.groupHeaderStyle ?? Theme.of(context).textTheme.titleMedium,',
        );
        buffer.writeln('                  ),');
        buffer.writeln('                ),');
      }

      for (final field in groupFields) {
        final methodName =
            '_build${field.name[0].toUpperCase()}${field.name.substring(1)}Field';
        if (field.hasShowWhen) {
          buffer.writeln(
            '                if (_shouldShow${field.name[0].toUpperCase()}${field.name.substring(1)}()) $methodName(),',
          );
        } else {
          buffer.writeln('                $methodName(),');
        }
      }
    }

    buffer.writeln('              ],');
    buffer.writeln('            ),');
    buffer.writeln('          ),');
    buffer.writeln('        );');
  }

  void _generateStepperBuild(StringBuffer buffer, List<ResolvedField> fields) {
    // Group fields by step
    final steps = <int, List<ResolvedField>>{};
    for (final field in fields) {
      final step = field.formStep ?? 0;
      steps.putIfAbsent(step, () => []).add(field);
    }

    // Get step titles
    final stepTitles = <int, String>{};
    for (final field in fields) {
      if (field.formStep != null && field.formStepTitle != null) {
        stepTitles[field.formStep!] = field.formStepTitle!;
      }
    }

    buffer.writeln('        return Form(');
    buffer.writeln('          child: Stepper(');
    buffer.writeln('            currentStep: widget.controller.currentStep,');
    buffer.writeln('            onStepContinue: () {');
    buffer.writeln('              if (widget.controller.canGoNext) {');
    buffer.writeln('                widget.controller.nextStep();');
    buffer.writeln('              }');
    buffer.writeln('            },');
    buffer.writeln('            onStepCancel: () {');
    buffer.writeln('              if (widget.controller.canGoBack) {');
    buffer.writeln('                widget.controller.previousStep();');
    buffer.writeln('              }');
    buffer.writeln('            },');
    buffer.writeln('            onStepTapped: (step) {');
    buffer.writeln('              widget.controller.currentStep = step;');
    buffer.writeln('            },');
    buffer.writeln('            steps: [');

    final sortedSteps = steps.keys.toList()..sort();
    for (final stepIndex in sortedSteps) {
      final stepFields = steps[stepIndex]!;
      final title = stepTitles[stepIndex] ?? 'Step ${stepIndex + 1}';

      buffer.writeln('              Step(');
      buffer.writeln("                title: Text('$title'),");
      buffer.writeln(
          '                isActive: widget.controller.currentStep >= $stepIndex,');
      buffer.writeln(
          '                state: widget.controller.currentStep > $stepIndex');
      buffer.writeln('                    ? StepState.complete');
      buffer
          .writeln('                    : widget.controller.currentStep == $stepIndex');
      buffer.writeln('                        ? StepState.editing');
      buffer.writeln('                        : StepState.indexed,');
      buffer.writeln('                content: Padding(');
      buffer.writeln(
          '                  padding: theme.formPadding ?? EdgeInsets.zero,');
      buffer.writeln('                  child: Column(');
      buffer.writeln(
        '                    crossAxisAlignment: CrossAxisAlignment.stretch,',
      );
      buffer.writeln('                    children: [');
      for (final field in stepFields) {
        final methodName =
            '_build${field.name[0].toUpperCase()}${field.name.substring(1)}Field';
        if (field.hasShowWhen) {
          buffer.writeln(
            '                      if (_shouldShow${field.name[0].toUpperCase()}${field.name.substring(1)}()) $methodName(),',
          );
        } else {
          buffer.writeln('                      $methodName(),');
        }
      }
      buffer.writeln('                    ],');
      buffer.writeln('                  ),');
      buffer.writeln('                ),');
      buffer.writeln('              ),');
    }

    buffer.writeln('            ],');
    buffer.writeln('          ),');
    buffer.writeln('        );');
  }

  void _generateFieldBuilder(
    StringBuffer buffer,
    ResolvedField field,
    List<ResolvedField> allFields,
  ) {
    final methodName =
        '_build${field.name[0].toUpperCase()}${field.name.substring(1)}Field';
    final label = _humanize(field.name);

    // Generate showWhen helper if needed
    if (field.hasShowWhen) {
      final showCapName =
          '_shouldShow${field.name[0].toUpperCase()}${field.name.substring(1)}';
      buffer.writeln('  bool $showCapName() {');
      final watchField = field.showWhenField!;
      final equalsValue = field.showWhenEquals;
      if (equalsValue is String) {
        buffer.writeln(
          "    return widget.controller.$watchField.value == '$equalsValue';",
        );
      } else if (equalsValue is bool) {
        buffer.writeln(
          '    return widget.controller.$watchField.value == $equalsValue;',
        );
      } else {
        buffer.writeln(
          '    return widget.controller.$watchField.value == $equalsValue;',
        );
      }
      buffer.writeln('  }');
      buffer.writeln();
    }

    buffer.writeln('  /// Builds the widget for the [${field.name}] field.');
    buffer.writeln('  Widget $methodName() {');
    buffer.writeln('    final theme = FormForgeTheme.of(context);');
    buffer.writeln(
        '    final isEnabled = widget.controller.isEnabled && widget.controller.${field.name}.isEnabled;');

    // Determine field index for focus management
    final fieldIndex = allFields.indexOf(field);
    final isLastField = fieldIndex == allFields.length - 1;

    // Check for special field types first
    if (field.isSlider) {
      _generateSliderField(buffer, field, label);
    } else if (field.isRatingInput) {
      _generateRatingField(buffer, field, label);
    } else if (field.isColorPicker) {
      _generateColorPickerField(buffer, field, label);
    } else if (field.isDateRange) {
      _generateDateRangeField(buffer, field, label);
    } else if (field.isChipsInput) {
      _generateChipsField(buffer, field, label);
    } else if (field.isRichText) {
      _generateRichTextField(buffer, field, label);
    } else if (field.isSearchableDropdown && field.isEnum) {
      _generateSearchableDropdown(buffer, field, label);
    } else if (field.isPhoneNumber) {
      _generatePhoneNumberField(buffer, field, label, isLastField);
    } else if (field.isEnum) {
      _generateDropdownField(buffer, field, label);
    } else if (field.typeName == 'DateTime') {
      _generateDateTimeField(buffer, field, label);
    } else {
      switch (field.typeName) {
        case 'bool':
          _generateBoolField(buffer, field, label);
          break;
        case 'int':
        case 'double':
          _generateNumericField(buffer, field, label, isLastField);
          break;
        default:
          _generateTextField(buffer, field, label, isLastField);
          break;
      }
    }

    buffer.writeln('  }');
    buffer.writeln();
  }

  void _generateTextField(
    StringBuffer buffer,
    ResolvedField field,
    String label,
    bool isLastField,
  ) {
    final hasAsync = field.hasAsyncValidator;

    buffer.writeln('    return Padding(');
    buffer.writeln(
        '      padding: EdgeInsets.symmetric(vertical: theme.fieldSpacing / 2),');
    buffer.writeln('      child: TextFormField(');
    buffer.writeln(
        '        focusNode: widget.controller.${field.name}FocusNode,');
    buffer.writeln('        enabled: isEnabled,');
    buffer.writeln(
        '        decoration: (theme.inputDecoration ?? const InputDecoration()).copyWith(');
    buffer.writeln("          labelText: '$label',");
    buffer.writeln('          labelStyle: theme.labelStyle,');
    buffer.writeln(
        '          errorText: widget.controller.${field.name}.error,');
    buffer.writeln('          errorStyle: theme.errorStyle,');
    if (hasAsync) {
      buffer.writeln(
        '          suffixIcon: widget.controller.${field.name}.isValidating && theme.showAsyncValidatingIndicator',
      );
      buffer.writeln(
        '              ? SizedBox(width: theme.asyncValidatingIndicatorSize, height: theme.asyncValidatingIndicatorSize, child: CircularProgressIndicator(strokeWidth: 2, color: theme.asyncValidatingColor))',
      );
      buffer.writeln('              : null,');
    }
    buffer.writeln('        ),');
    buffer.writeln('        onChanged: (v) {');
    buffer.writeln('          widget.controller.${field.name}.value = v;');
    if (hasAsync) {
      final debounce = field.asyncDebounceMs ?? 500;
      buffer.writeln(
        "          widget.controller._triggerAsyncValidation('${field.name}', v, $debounce);",
      );
    }
    buffer.writeln('        },');
    buffer.writeln(
      "        textInputAction: ${isLastField ? 'TextInputAction.done' : 'TextInputAction.next'},",
    );
    buffer.writeln('        onFieldSubmitted: (_) {');
    if (!isLastField) {
      buffer.writeln(
          "          widget.controller.focusNextField('${field.name}');");
    }
    buffer.writeln('        },');
    buffer.writeln('      ),');
    buffer.writeln('    );');
  }

  void _generatePhoneNumberField(
    StringBuffer buffer,
    ResolvedField field,
    String label,
    bool isLastField,
  ) {
    final hasAsync = field.hasAsyncValidator;

    buffer.writeln('    return Padding(');
    buffer.writeln(
        '      padding: EdgeInsets.symmetric(vertical: theme.fieldSpacing / 2),');
    buffer.writeln('      child: TextFormField(');
    buffer.writeln(
        '        focusNode: widget.controller.${field.name}FocusNode,');
    buffer.writeln('        enabled: isEnabled,');
    buffer.writeln('        keyboardType: TextInputType.phone,');
    buffer.writeln(
        '        decoration: (theme.inputDecoration ?? const InputDecoration()).copyWith(');
    buffer.writeln("          labelText: '$label',");
    buffer.writeln('          labelStyle: theme.labelStyle,');
    buffer.writeln("          hintText: '+1 (555) 123-4567',");
    buffer.writeln('          hintStyle: theme.hintStyle,');
    buffer.writeln(
        '          errorText: widget.controller.${field.name}.error,');
    buffer.writeln('          errorStyle: theme.errorStyle,');
    if (hasAsync) {
      buffer.writeln(
        '          suffixIcon: widget.controller.${field.name}.isValidating && theme.showAsyncValidatingIndicator',
      );
      buffer.writeln(
        '              ? SizedBox(width: theme.asyncValidatingIndicatorSize, height: theme.asyncValidatingIndicatorSize, child: CircularProgressIndicator(strokeWidth: 2, color: theme.asyncValidatingColor))',
      );
      buffer.writeln('              : null,');
    }
    buffer.writeln('        ),');
    buffer.writeln('        onChanged: (v) {');
    buffer.writeln('          widget.controller.${field.name}.value = v;');
    if (hasAsync) {
      final debounce = field.asyncDebounceMs ?? 500;
      buffer.writeln(
        "          widget.controller._triggerAsyncValidation('${field.name}', v, $debounce);",
      );
    }
    buffer.writeln('        },');
    buffer.writeln(
      "        textInputAction: ${isLastField ? 'TextInputAction.done' : 'TextInputAction.next'},",
    );
    buffer.writeln('        onFieldSubmitted: (_) {');
    if (!isLastField) {
      buffer.writeln(
          "          widget.controller.focusNextField('${field.name}');");
    }
    buffer.writeln('        },');
    buffer.writeln('      ),');
    buffer.writeln('    );');
  }

  void _generateNumericField(
    StringBuffer buffer,
    ResolvedField field,
    String label,
    bool isLastField,
  ) {
    buffer.writeln('    return Padding(');
    buffer.writeln(
        '      padding: EdgeInsets.symmetric(vertical: theme.fieldSpacing / 2),');
    buffer.writeln('      child: TextFormField(');
    buffer.writeln(
        '        focusNode: widget.controller.${field.name}FocusNode,');
    buffer.writeln('        enabled: isEnabled,');
    buffer.writeln('        keyboardType: TextInputType.number,');
    buffer.writeln(
        '        decoration: (theme.inputDecoration ?? const InputDecoration()).copyWith(');
    buffer.writeln("          labelText: '$label',");
    buffer.writeln('          labelStyle: theme.labelStyle,');
    buffer.writeln(
        '          errorText: widget.controller.${field.name}.error,');
    buffer.writeln('          errorStyle: theme.errorStyle,');
    buffer.writeln('        ),');
    buffer.writeln(
      "        initialValue: widget.controller.${field.name}.value.toString(),",
    );
    buffer.writeln('        onChanged: (v) {');
    if (field.typeName == 'int') {
      buffer.writeln(
        '          widget.controller.${field.name}.value = int.tryParse(v) ?? 0;',
      );
    } else {
      buffer.writeln(
        '          widget.controller.${field.name}.value = double.tryParse(v) ?? 0.0;',
      );
    }
    buffer.writeln('        },');
    buffer.writeln(
      "        textInputAction: ${isLastField ? 'TextInputAction.done' : 'TextInputAction.next'},",
    );
    buffer.writeln('        onFieldSubmitted: (_) {');
    if (!isLastField) {
      buffer.writeln(
          "          widget.controller.focusNextField('${field.name}');");
    }
    buffer.writeln('        },');
    buffer.writeln('      ),');
    buffer.writeln('    );');
  }

  void _generateBoolField(
    StringBuffer buffer,
    ResolvedField field,
    String label,
  ) {
    buffer.writeln('    return Padding(');
    buffer.writeln(
        '      padding: EdgeInsets.symmetric(vertical: theme.fieldSpacing / 2),');
    buffer.writeln('      child: SwitchListTile(');
    buffer.writeln('        title: Text(');
    buffer.writeln("          '$label',");
    buffer.writeln('          style: theme.labelStyle,');
    buffer.writeln('        ),');
    buffer.writeln('        value: widget.controller.${field.name}.value,');
    buffer.writeln('        onChanged: isEnabled ? (v) {');
    buffer.writeln('          widget.controller.${field.name}.value = v;');
    buffer.writeln('        } : null,');
    buffer.writeln('      ),');
    buffer.writeln('    );');
  }

  void _generateDropdownField(
    StringBuffer buffer,
    ResolvedField field,
    String label,
  ) {
    final dartType = field.isNullable ? '${field.typeName}?' : field.typeName;
    final hasAsync = field.hasAsyncValidator;

    buffer.writeln('    return Padding(');
    buffer.writeln(
        '      padding: EdgeInsets.symmetric(vertical: theme.fieldSpacing / 2),');
    buffer.writeln('      child: DropdownButtonFormField<$dartType>(');
    buffer.writeln(
        '        focusNode: widget.controller.${field.name}FocusNode,');
    buffer.writeln(
        '        decoration: (theme.inputDecoration ?? const InputDecoration()).copyWith(');
    buffer.writeln("          labelText: '$label',");
    buffer.writeln('          labelStyle: theme.labelStyle,');
    buffer.writeln(
        '          errorText: widget.controller.${field.name}.error,');
    buffer.writeln('          errorStyle: theme.errorStyle,');
    buffer.writeln('        ),');
    buffer.writeln('        value: widget.controller.${field.name}.value,');
    buffer.writeln(
      '        items: ${field.typeName}.values.map((e) => DropdownMenuItem(',
    );
    buffer.writeln('          value: e,');
    buffer.writeln('          child: Text(e.name),');
    buffer.writeln('        )).toList(),');
    buffer.writeln('        onChanged: isEnabled ? (v) {');
    if (field.isNullable) {
      buffer.writeln('          widget.controller.${field.name}.value = v;');
    } else {
      buffer.writeln('          if (v != null) {');
      buffer.writeln('            widget.controller.${field.name}.value = v;');
      buffer.writeln('          }');
    }
    if (hasAsync) {
      final debounce = field.asyncDebounceMs ?? 500;
      buffer.writeln(
        "          widget.controller._triggerAsyncValidation('${field.name}', widget.controller.${field.name}.value, $debounce);",
      );
    }
    buffer.writeln('        } : null,');
    buffer.writeln('      ),');
    buffer.writeln('    );');
  }

  void _generateSearchableDropdown(
    StringBuffer buffer,
    ResolvedField field,
    String label,
  ) {
    final hintText = field.searchableDropdownHintText ?? 'Search...';

    buffer.writeln('    return Padding(');
    buffer.writeln(
        '      padding: EdgeInsets.symmetric(vertical: theme.fieldSpacing / 2),');
    buffer.writeln('      child: Autocomplete<${field.typeName}>(');
    buffer.writeln('        optionsBuilder: (textEditingValue) {');
    buffer.writeln('          if (textEditingValue.text.isEmpty) {');
    buffer.writeln('            return ${field.typeName}.values;');
    buffer.writeln('          }');
    buffer.writeln(
      '          return ${field.typeName}.values.where((e) => e.name.toLowerCase().contains(textEditingValue.text.toLowerCase()));',
    );
    buffer.writeln('        },');
    buffer.writeln('        displayStringForOption: (option) => option.name,');
    buffer.writeln('        onSelected: (value) {');
    buffer.writeln('          widget.controller.${field.name}.value = value;');
    buffer.writeln('        },');
    buffer.writeln(
        '        fieldViewBuilder: (context, textController, focusNode, onFieldSubmitted) {');
    buffer.writeln('          return TextFormField(');
    buffer.writeln('            controller: textController,');
    buffer.writeln('            focusNode: focusNode,');
    buffer.writeln('            enabled: isEnabled,');
    buffer.writeln(
        '            decoration: (theme.inputDecoration ?? const InputDecoration()).copyWith(');
    buffer.writeln("              labelText: '$label',");
    buffer.writeln('              labelStyle: theme.labelStyle,');
    buffer.writeln("              hintText: '$hintText',");
    buffer.writeln('              hintStyle: theme.hintStyle,');
    buffer.writeln(
        '              errorText: widget.controller.${field.name}.error,');
    buffer.writeln('              errorStyle: theme.errorStyle,');
    buffer.writeln('            ),');
    buffer.writeln('            onFieldSubmitted: (_) => onFieldSubmitted(),');
    buffer.writeln('          );');
    buffer.writeln('        },');
    buffer.writeln('      ),');
    buffer.writeln('    );');
  }

  void _generateDateTimeField(
    StringBuffer buffer,
    ResolvedField field,
    String label,
  ) {
    buffer.writeln('    return Padding(');
    buffer.writeln(
        '      padding: EdgeInsets.symmetric(vertical: theme.fieldSpacing / 2),');
    buffer.writeln('      child: InkWell(');
    buffer.writeln('        onTap: isEnabled ? () async {');
    buffer.writeln('          final picked = await showDatePicker(');
    buffer.writeln('            context: context,');
    if (field.isNullable) {
      buffer.writeln(
        '            initialDate: widget.controller.${field.name}.value ?? DateTime.now(),',
      );
    } else {
      buffer.writeln(
        '            initialDate: widget.controller.${field.name}.value,',
      );
    }
    buffer.writeln('            firstDate: DateTime(1900),');
    buffer.writeln('            lastDate: DateTime(2100),');
    buffer.writeln('          );');
    buffer.writeln('          if (picked != null) {');
    buffer.writeln(
        '            widget.controller.${field.name}.value = picked;');
    buffer.writeln('          }');
    buffer.writeln('        } : null,');
    buffer.writeln('        child: InputDecorator(');
    buffer.writeln(
        '          decoration: (theme.inputDecoration ?? const InputDecoration()).copyWith(');
    buffer.writeln("            labelText: '$label',");
    buffer.writeln('            labelStyle: theme.labelStyle,');
    buffer.writeln(
        '            errorText: widget.controller.${field.name}.error,');
    buffer.writeln('            errorStyle: theme.errorStyle,');
    buffer.writeln('          ),');
    if (field.isNullable) {
      buffer.writeln(
        "          child: Text(widget.controller.${field.name}.value?.toString().split(' ').first ?? 'Select date'),",
      );
    } else {
      buffer.writeln(
        "          child: Text(widget.controller.${field.name}.value.toString().split(' ').first),",
      );
    }
    buffer.writeln('        ),');
    buffer.writeln('      ),');
    buffer.writeln('    );');
  }

  void _generateDateRangeField(
    StringBuffer buffer,
    ResolvedField field,
    String label,
  ) {
    final firstDate = field.dateRangeFirstDate ?? 1900;
    final lastDate = field.dateRangeLastDate ?? 2100;
    final helpText = field.dateRangeHelpText ?? 'Select date range';

    buffer.writeln('    return Padding(');
    buffer.writeln(
        '      padding: EdgeInsets.symmetric(vertical: theme.fieldSpacing / 2),');
    buffer.writeln('      child: InkWell(');
    buffer.writeln('        onTap: isEnabled ? () async {');
    buffer.writeln('          final picked = await showDateRangePicker(');
    buffer.writeln('            context: context,');
    buffer.writeln('            firstDate: DateTime($firstDate),');
    buffer.writeln('            lastDate: DateTime($lastDate),');
    buffer.writeln("            helpText: '$helpText',");
    buffer.writeln(
      '            initialDateRange: widget.controller.${field.name}.value,',
    );
    buffer.writeln('          );');
    buffer.writeln('          if (picked != null) {');
    buffer.writeln(
        '            widget.controller.${field.name}.value = picked;');
    buffer.writeln('          }');
    buffer.writeln('        } : null,');
    buffer.writeln('        child: InputDecorator(');
    buffer.writeln(
        '          decoration: (theme.inputDecoration ?? const InputDecoration()).copyWith(');
    buffer.writeln("            labelText: '$label',");
    buffer.writeln('            labelStyle: theme.labelStyle,');
    buffer.writeln(
        '            errorText: widget.controller.${field.name}.error,');
    buffer.writeln('            errorStyle: theme.errorStyle,');
    buffer.writeln('          ),');
    if (field.isNullable) {
      buffer.writeln('          child: Text(');
      buffer.writeln(
        "            widget.controller.${field.name}.value != null ? '\${widget.controller.${field.name}.value!.start.toString().split(' ').first} - \${widget.controller.${field.name}.value!.end.toString().split(' ').first}' : 'Select date range',",
      );
      buffer.writeln('          ),');
    } else {
      buffer.writeln('          child: Text(');
      buffer.writeln(
        "            '\${widget.controller.${field.name}.value.start.toString().split(' ').first} - \${widget.controller.${field.name}.value.end.toString().split(' ').first}',",
      );
      buffer.writeln('          ),');
    }
    buffer.writeln('        ),');
    buffer.writeln('      ),');
    buffer.writeln('    );');
  }

  void _generateSliderField(
    StringBuffer buffer,
    ResolvedField field,
    String label,
  ) {
    final min = field.sliderMin ?? 0.0;
    final max = field.sliderMax ?? 100.0;
    final divisions = field.sliderDivisions;

    buffer.writeln('    return Padding(');
    buffer.writeln(
        '      padding: EdgeInsets.symmetric(vertical: theme.fieldSpacing / 2),');
    buffer.writeln('      child: Column(');
    buffer.writeln('        crossAxisAlignment: CrossAxisAlignment.start,');
    buffer.writeln('        children: [');
    buffer.writeln('          Text(');
    buffer.writeln(
        "            '\$label: \${widget.controller.${field.name}.value.toStringAsFixed(1)}',");
    buffer.writeln('            style: theme.labelStyle,');
    buffer.writeln('          ),');
    buffer.writeln('          Slider(');
    buffer.writeln(
        '            value: widget.controller.${field.name}.value.toDouble(),');
    buffer.writeln('            min: $min,');
    buffer.writeln('            max: $max,');
    if (divisions != null) {
      buffer.writeln('            divisions: $divisions,');
    }
    if (field.sliderLabel != null) {
      buffer.writeln("            label: '${field.sliderLabel}',");
    }
    buffer.writeln('            onChanged: isEnabled ? (v) {');
    if (field.typeName == 'int') {
      buffer.writeln(
        '              widget.controller.${field.name}.value = v.toInt();',
      );
    } else {
      buffer
          .writeln('              widget.controller.${field.name}.value = v;');
    }
    buffer.writeln('            } : null,');
    buffer.writeln('          ),');
    buffer.writeln(
        '          if (widget.controller.${field.name}.error != null)');
    buffer.writeln('            Text(');
    buffer.writeln('              widget.controller.${field.name}.error!,');
    buffer.writeln(
      '              style: theme.errorStyle ?? TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),',
    );
    buffer.writeln('            ),');
    buffer.writeln('        ],');
    buffer.writeln('      ),');
    buffer.writeln('    );');
  }

  void _generateRatingField(
    StringBuffer buffer,
    ResolvedField field,
    String label,
  ) {
    final maxStars = field.ratingMaxStars ?? 5;

    buffer.writeln('    return Padding(');
    buffer.writeln(
        '      padding: EdgeInsets.symmetric(vertical: theme.fieldSpacing / 2),');
    buffer.writeln('      child: Column(');
    buffer.writeln('        crossAxisAlignment: CrossAxisAlignment.start,');
    buffer.writeln('        children: [');
    buffer.writeln('          Text(');
    buffer.writeln("            '$label',");
    buffer.writeln('            style: theme.labelStyle,');
    buffer.writeln('          ),');
    buffer.writeln('          const SizedBox(height: 8),');
    buffer.writeln('          Row(');
    buffer.writeln('            mainAxisSize: MainAxisSize.min,');
    buffer.writeln(
        '            children: List.generate($maxStars, (index) {');
    buffer.writeln(
      '              final isSelected = index < widget.controller.${field.name}.value;',
    );
    buffer.writeln('              return IconButton(');
    buffer.writeln('                icon: Icon(');
    buffer.writeln(
      '                  isSelected ? Icons.star : Icons.star_border,',
    );
    buffer.writeln(
      '                  color: isSelected ? Colors.amber : Colors.grey,',
    );
    buffer.writeln('                ),');
    buffer.writeln('                onPressed: isEnabled ? () {');
    buffer.writeln(
      '                  widget.controller.${field.name}.value = index + 1;',
    );
    buffer.writeln('                } : null,');
    buffer.writeln('              );');
    buffer.writeln('            }),');
    buffer.writeln('          ),');
    buffer.writeln(
        '          if (widget.controller.${field.name}.error != null)');
    buffer.writeln('            Text(');
    buffer.writeln('              widget.controller.${field.name}.error!,');
    buffer.writeln(
      '              style: theme.errorStyle ?? TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),',
    );
    buffer.writeln('            ),');
    buffer.writeln('        ],');
    buffer.writeln('      ),');
    buffer.writeln('    );');
  }

  void _generateColorPickerField(
    StringBuffer buffer,
    ResolvedField field,
    String label,
  ) {
    buffer.writeln('    return Padding(');
    buffer.writeln(
        '      padding: EdgeInsets.symmetric(vertical: theme.fieldSpacing / 2),');
    buffer.writeln('      child: Column(');
    buffer.writeln('        crossAxisAlignment: CrossAxisAlignment.start,');
    buffer.writeln('        children: [');
    buffer.writeln('          Text(');
    buffer.writeln("            '$label',");
    buffer.writeln('            style: theme.labelStyle,');
    buffer.writeln('          ),');
    buffer.writeln('          const SizedBox(height: 8),');
    buffer.writeln('          InkWell(');
    buffer.writeln('            onTap: isEnabled ? () async {');
    buffer.writeln(
        '              Color selectedColor = widget.controller.${field.name}.value;');
    buffer.writeln('              await showDialog(');
    buffer.writeln('                context: context,');
    buffer.writeln('                builder: (context) => AlertDialog(');
    buffer.writeln("                  title: const Text('Select Color'),");
    buffer.writeln('                  content: SingleChildScrollView(');
    buffer.writeln('                    child: Wrap(');
    buffer.writeln('                      spacing: 8,');
    buffer.writeln('                      runSpacing: 8,');
    buffer.writeln('                      children: [');
    buffer.writeln(
        '                        Colors.red, Colors.pink, Colors.purple, Colors.deepPurple,');
    buffer.writeln(
        '                        Colors.indigo, Colors.blue, Colors.lightBlue, Colors.cyan,');
    buffer.writeln(
        '                        Colors.teal, Colors.green, Colors.lightGreen, Colors.lime,');
    buffer.writeln(
        '                        Colors.yellow, Colors.amber, Colors.orange, Colors.deepOrange,');
    buffer.writeln(
        '                        Colors.brown, Colors.grey, Colors.blueGrey, Colors.black,');
    buffer.writeln('                      ].map((color) => InkWell(');
    buffer.writeln('                        onTap: () {');
    buffer.writeln('                          selectedColor = color;');
    buffer.writeln('                          Navigator.of(context).pop();');
    buffer.writeln('                        },');
    buffer.writeln('                        child: Container(');
    buffer.writeln('                          width: 40,');
    buffer.writeln('                          height: 40,');
    buffer.writeln('                          decoration: BoxDecoration(');
    buffer.writeln('                            color: color,');
    buffer.writeln(
        '                            borderRadius: BorderRadius.circular(4),');
    buffer.writeln(
        '                            border: Border.all(color: Colors.black26),');
    buffer.writeln('                          ),');
    buffer.writeln('                        ),');
    buffer.writeln('                      )).toList(),');
    buffer.writeln('                    ),');
    buffer.writeln('                  ),');
    buffer.writeln('                ),');
    buffer.writeln('              );');
    buffer.writeln(
        '              widget.controller.${field.name}.value = selectedColor;');
    buffer.writeln('            } : null,');
    buffer.writeln('            child: Container(');
    buffer.writeln('              width: 48,');
    buffer.writeln('              height: 48,');
    buffer.writeln('              decoration: BoxDecoration(');
    buffer.writeln(
        '                color: widget.controller.${field.name}.value,');
    buffer.writeln('                borderRadius: BorderRadius.circular(8),');
    buffer.writeln(
        '                border: Border.all(color: Colors.black26),');
    buffer.writeln('              ),');
    buffer.writeln('            ),');
    buffer.writeln('          ),');
    buffer.writeln(
        '          if (widget.controller.${field.name}.error != null)');
    buffer.writeln('            Text(');
    buffer.writeln('              widget.controller.${field.name}.error!,');
    buffer.writeln(
      '              style: theme.errorStyle ?? TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),',
    );
    buffer.writeln('            ),');
    buffer.writeln('        ],');
    buffer.writeln('      ),');
    buffer.writeln('    );');
  }

  void _generateChipsField(
    StringBuffer buffer,
    ResolvedField field,
    String label,
  ) {
    final maxChips = field.chipsMaxChips;

    buffer.writeln('    return Padding(');
    buffer.writeln(
        '      padding: EdgeInsets.symmetric(vertical: theme.fieldSpacing / 2),');
    buffer.writeln('      child: Column(');
    buffer.writeln('        crossAxisAlignment: CrossAxisAlignment.start,');
    buffer.writeln('        children: [');
    buffer.writeln('          Text(');
    buffer.writeln("            '$label',");
    buffer.writeln('            style: theme.labelStyle,');
    buffer.writeln('          ),');
    buffer.writeln('          const SizedBox(height: 8),');
    buffer.writeln('          Wrap(');
    buffer.writeln('            spacing: 8,');
    buffer.writeln('            runSpacing: 4,');
    buffer.writeln('            children: [');
    buffer.writeln(
      '              ...widget.controller.${field.name}.value.map((chip) => Chip(',
    );
    buffer.writeln('                label: Text(chip),');
    buffer.writeln('                onDeleted: isEnabled ? () {');
    buffer.writeln(
      '                  widget.controller.${field.name}.value = List.from(widget.controller.${field.name}.value)..remove(chip);',
    );
    buffer.writeln('                } : null,');
    buffer.writeln('              )),');
    if (maxChips != null) {
      buffer.writeln(
        '              if (isEnabled && widget.controller.${field.name}.value.length < $maxChips)',
      );
    } else {
      buffer.writeln('              if (isEnabled)');
    }
    buffer.writeln('                ActionChip(');
    buffer.writeln("                  label: const Text('+ Add'),");
    buffer.writeln('                  onPressed: () async {');
    buffer.writeln(
        '                    final controller = TextEditingController();');
    buffer.writeln(
        '                    final result = await showDialog<String>(');
    buffer.writeln('                      context: context,');
    buffer.writeln('                      builder: (context) => AlertDialog(');
    buffer
        .writeln("                        title: const Text('Add Tag'),");
    buffer.writeln('                        content: TextField(');
    buffer.writeln('                          controller: controller,');
    buffer.writeln('                          autofocus: true,');
    buffer.writeln('                        ),');
    buffer.writeln('                        actions: [');
    buffer.writeln('                          TextButton(');
    buffer.writeln(
        "                            child: const Text('Cancel'),");
    buffer.writeln(
        '                            onPressed: () => Navigator.of(context).pop(),');
    buffer.writeln('                          ),');
    buffer.writeln('                          TextButton(');
    buffer.writeln("                            child: const Text('Add'),");
    buffer.writeln(
        '                            onPressed: () => Navigator.of(context).pop(controller.text),');
    buffer.writeln('                          ),');
    buffer.writeln('                        ],');
    buffer.writeln('                      ),');
    buffer.writeln('                    );');
    buffer.writeln(
        '                    if (result != null && result.isNotEmpty) {');
    buffer.writeln(
      '                      widget.controller.${field.name}.value = List.from(widget.controller.${field.name}.value)..add(result);',
    );
    buffer.writeln('                    }');
    buffer.writeln('                  },');
    buffer.writeln('                ),');
    buffer.writeln('            ],');
    buffer.writeln('          ),');
    buffer.writeln(
        '          if (widget.controller.${field.name}.error != null)');
    buffer.writeln('            Text(');
    buffer.writeln('              widget.controller.${field.name}.error!,');
    buffer.writeln(
      '              style: theme.errorStyle ?? TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),',
    );
    buffer.writeln('            ),');
    buffer.writeln('        ],');
    buffer.writeln('      ),');
    buffer.writeln('    );');
  }

  void _generateRichTextField(
    StringBuffer buffer,
    ResolvedField field,
    String label,
  ) {
    final minLines = field.richTextMinLines ?? 3;
    final maxLines = field.richTextMaxLines ?? 10;

    buffer.writeln('    return Padding(');
    buffer.writeln(
        '      padding: EdgeInsets.symmetric(vertical: theme.fieldSpacing / 2),');
    buffer.writeln('      child: TextFormField(');
    buffer.writeln(
        '        focusNode: widget.controller.${field.name}FocusNode,');
    buffer.writeln('        enabled: isEnabled,');
    buffer.writeln('        minLines: $minLines,');
    buffer.writeln('        maxLines: $maxLines,');
    buffer.writeln(
        '        decoration: (theme.inputDecoration ?? const InputDecoration()).copyWith(');
    buffer.writeln("          labelText: '$label',");
    buffer.writeln('          labelStyle: theme.labelStyle,');
    buffer.writeln(
        '          errorText: widget.controller.${field.name}.error,');
    buffer.writeln('          errorStyle: theme.errorStyle,');
    buffer.writeln('          alignLabelWithHint: true,');
    buffer.writeln('        ),');
    buffer.writeln('        onChanged: (v) {');
    buffer.writeln('          widget.controller.${field.name}.value = v;');
    buffer.writeln('        },');
    buffer.writeln('      ),');
    buffer.writeln('    );');
  }

  String _humanize(String camelCase) {
    final result = camelCase.replaceAllMapped(
      RegExp(r'[A-Z]'),
      (match) => ' ${match.group(0)}',
    );
    return result[0].toUpperCase() + result.substring(1);
  }

  /// Returns the name prefix for generated classes.
  /// Strips trailing "Form" to avoid `LoginFormFormController`.
  String _generatedPrefix(String className) {
    if (className.endsWith('Form') && className.length > 4) {
      return className.substring(0, className.length - 4);
    }
    return className;
  }

  String _defaultValueFor(ResolvedField field) {
    if (field.isNullable) return 'null';
    switch (field.typeName) {
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
      case 'DateTimeRange':
        return 'DateTimeRange(start: DateTime.now(), end: DateTime.now().add(const Duration(days: 7)))';
      case 'Color':
        return 'const Color(0xFF000000)';
      case 'List<String>':
        return 'const <String>[]';
      default:
        if (field.isEnum &&
            field.enumValues != null &&
            field.enumValues!.isNotEmpty) {
          return '${field.typeName}.${field.enumValues!.first}';
        }
        return 'null';
    }
  }
}

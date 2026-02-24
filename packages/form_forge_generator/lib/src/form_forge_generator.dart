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

      final className = element.name!;
      final fields = _fieldResolver.resolve(element);

      if (fields.isEmpty) {
        throw InvalidGenerationSourceError(
          '@FormForge() class "$className" must have at least one field.',
          element: element,
        );
      }

      _generateDataClass(buffer, className, fields);
      _generateController(buffer, className, fields);
      _generateWidget(buffer, className, fields);
    }

    final output = buffer.toString();
    return output.isEmpty ? null : output;
  }

  void _generateController(
    StringBuffer buffer,
    String className,
    List<ResolvedField> fields,
  ) {
    final controllerName = '${_generatedPrefix(className)}FormController';

    final asyncFields =
        fields.where((f) => f.hasAsyncValidator).toList();

    buffer.writeln('/// Generated form controller for [$className].');
    buffer.writeln(
        'class $controllerName extends FormForgeController {');

    // Field declarations
    for (final field in fields) {
      final dartType =
          field.isNullable ? '${field.typeName}?' : field.typeName;
      final defaultValue = _defaultValueFor(field);
      buffer.writeln(
          '  final ForgeFieldState<$dartType> ${field.name} = '
          'ForgeFieldState<$dartType>(initialValue: $defaultValue);');
    }
    buffer.writeln();

    // Constructor
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
    final dataClassName = '${_generatedPrefix(className)}FormData';
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
    final dataClassName = '${_generatedPrefix(className)}FormData';

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
      if (isStringType && !field.isNullable) {
        buffer.writeln("    if (value.isEmpty) {");
      } else if (isStringType && field.isNullable) {
        buffer.writeln("    if (value == null || value.isEmpty) {");
      } else if (field.isNullable) {
        buffer.writeln("    if (value == null) {");
      } else {
        // Non-nullable, non-string (int, double, bool, enum, DateTime):
        // These always have a default value, so required is inherently satisfied.
        // Skip the check — the field always has a value.
        buffer.writeln("    // Required check skipped: non-nullable ${field.typeName} always has a value.");
        buffer.writeln("    // Consider making the field nullable if you need an 'unset' state.");
      }
      if (isStringType || field.isNullable) {
        buffer.writeln("      ${field.name}.error = '$msg';");
        buffer.writeln('      return;');
        buffer.writeln('    }');
      }
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
      if (field.isNullable) {
        buffer.writeln(
            "    if (value != null && !RegExp(r'${field.pattern}').hasMatch(value)) {");
      } else {
        buffer.writeln(
            "    if (!RegExp(r'${field.pattern}').hasMatch(value)) {");
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
    List<ResolvedField> fields,
  ) {
    final widgetName = '${_generatedPrefix(className)}FormWidget';
    final controllerName = '${_generatedPrefix(className)}FormController';

    buffer.writeln();
    buffer.writeln('/// Generated form widget for [$className].');
    buffer.writeln(
        'class $widgetName extends StatefulWidget {');
    buffer.writeln('  /// The form controller managing state and validation.');
    buffer.writeln('  final $controllerName controller;');
    buffer.writeln();
    buffer.writeln('  /// Creates a [$widgetName].');
    buffer.writeln(
        '  const $widgetName({super.key, required this.controller});');
    buffer.writeln();
    buffer.writeln('  @override');
    buffer.writeln(
        '  State<$widgetName> createState() => _${widgetName}State();');
    buffer.writeln('}');
    buffer.writeln();

    // State class
    buffer.writeln(
        'class _${widgetName}State extends State<$widgetName> {');
    buffer.writeln();

    // Per-field builder methods
    for (final field in fields) {
      _generateFieldBuilder(buffer, field);
    }

    // Build method
    buffer.writeln('  @override');
    buffer.writeln('  Widget build(BuildContext context) {');
    buffer.writeln('    return AnimatedBuilder(');
    buffer.writeln('      animation: widget.controller,');
    buffer.writeln('      builder: (context, _) {');
    buffer.writeln('        return Form(');
    buffer.writeln('          child: Column(');
    buffer.writeln(
        '            crossAxisAlignment: CrossAxisAlignment.stretch,');
    buffer.writeln('            children: [');
    for (final field in fields) {
      final methodName =
          'build${field.name[0].toUpperCase()}${field.name.substring(1)}Field';
      buffer.writeln('              $methodName(),');
    }
    buffer.writeln('            ],');
    buffer.writeln('          ),');
    buffer.writeln('        );');
    buffer.writeln('      },');
    buffer.writeln('    );');
    buffer.writeln('  }');

    buffer.writeln('}');
  }

  void _generateFieldBuilder(StringBuffer buffer, ResolvedField field) {
    final methodName =
        'build${field.name[0].toUpperCase()}${field.name.substring(1)}Field';
    final label = _humanize(field.name);

    buffer.writeln('  /// Builds the widget for the [${field.name}] field.');
    buffer.writeln('  Widget $methodName() {');

    if (field.isEnum) {
      // Enum → DropdownButtonFormField
      final dartType =
          field.isNullable ? '${field.typeName}?' : field.typeName;
      buffer.writeln('    return Padding(');
      buffer.writeln(
          '      padding: const EdgeInsets.symmetric(vertical: 8.0),');
      buffer.writeln('      child: DropdownButtonFormField<$dartType>(');
      buffer.writeln('        decoration: InputDecoration(');
      buffer.writeln("          labelText: '$label',");
      buffer.writeln(
          '          errorText: widget.controller.${field.name}.error,');
      buffer.writeln('        ),');
      buffer.writeln(
          '        value: widget.controller.${field.name}.value,');
      buffer.writeln(
          '        items: ${field.typeName}.values.map((e) => DropdownMenuItem(');
      buffer.writeln('          value: e,');
      buffer.writeln('          child: Text(e.name),');
      buffer.writeln('        )).toList(),');
      buffer.writeln('        onChanged: (v) {');
      if (field.isNullable) {
        buffer.writeln(
            '          widget.controller.${field.name}.value = v;');
      } else {
        buffer.writeln('          if (v != null) {');
        buffer.writeln(
            '            widget.controller.${field.name}.value = v;');
        buffer.writeln('          }');
      }
      if (field.hasAsyncValidator) {
        final debounce = field.asyncDebounceMs ?? 500;
        buffer.writeln(
            '          widget.controller._triggerAsyncValidation(\'${field.name}\', widget.controller.${field.name}.value, $debounce);');
      }
      buffer.writeln('        },');
      buffer.writeln('      ),');
      buffer.writeln('    );');
    } else if (field.typeName == 'DateTime') {
      // DateTime → Date picker
      buffer.writeln('    return Padding(');
      buffer.writeln(
          '      padding: const EdgeInsets.symmetric(vertical: 8.0),');
      buffer.writeln('      child: InkWell(');
      buffer.writeln('        onTap: () async {');
      buffer.writeln('          final picked = await showDatePicker(');
      buffer.writeln('            context: context,');
      if (field.isNullable) {
        buffer.writeln(
            '            initialDate: widget.controller.${field.name}.value ?? DateTime.now(),');
      } else {
        buffer.writeln(
            '            initialDate: widget.controller.${field.name}.value,');
      }
      buffer.writeln(
          '            firstDate: DateTime(1900),');
      buffer.writeln(
          '            lastDate: DateTime(2100),');
      buffer.writeln('          );');
      buffer.writeln('          if (picked != null) {');
      buffer.writeln(
          '            widget.controller.${field.name}.value = picked;');
      if (field.hasAsyncValidator) {
        final debounce = field.asyncDebounceMs ?? 500;
        buffer.writeln(
            '            widget.controller._triggerAsyncValidation(\'${field.name}\', widget.controller.${field.name}.value, $debounce);');
      }
      buffer.writeln('          }');
      buffer.writeln('        },');
      buffer.writeln('        child: InputDecorator(');
      buffer.writeln('          decoration: InputDecoration(');
      buffer.writeln("            labelText: '$label',");
      buffer.writeln(
          '            errorText: widget.controller.${field.name}.error,');
      buffer.writeln('          ),');
      if (field.isNullable) {
        buffer.writeln(
            "          child: Text(widget.controller.${field.name}.value?.toString().split(' ').first ?? 'Select date'),");
      } else {
        buffer.writeln(
            "          child: Text(widget.controller.${field.name}.value.toString().split(' ').first),");
      }
      buffer.writeln('        ),');
      buffer.writeln('      ),');
      buffer.writeln('    );');
    } else {
      switch (field.typeName) {
        case 'bool':
          buffer.writeln('    return CheckboxListTile(');
          buffer.writeln("      title: Text('$label'),");
          buffer.writeln(
              '      value: widget.controller.${field.name}.value,');
          buffer.writeln('      onChanged: (v) {');
          buffer.writeln(
              '        widget.controller.${field.name}.value = v ?? false;');
          if (field.hasAsyncValidator) {
            final debounce = field.asyncDebounceMs ?? 500;
            buffer.writeln(
                '        widget.controller._triggerAsyncValidation(\'${field.name}\', widget.controller.${field.name}.value, $debounce);');
          }
          buffer.writeln('      },');
          buffer.writeln('    );');
          break;
        case 'int':
        case 'double':
          buffer.writeln('    return Padding(');
          buffer.writeln(
              '      padding: const EdgeInsets.symmetric(vertical: 8.0),');
          buffer.writeln('      child: TextFormField(');
          buffer.writeln('        keyboardType: TextInputType.number,');
          buffer.writeln('        decoration: InputDecoration(');
          buffer.writeln("          labelText: '$label',");
          buffer.writeln(
              '          errorText: widget.controller.${field.name}.error,');
          buffer.writeln('        ),');
          buffer.writeln(
              "        initialValue: widget.controller.${field.name}.value.toString(),");
          buffer.writeln('        onChanged: (v) {');
          if (field.typeName == 'int') {
            buffer.writeln(
                '          widget.controller.${field.name}.value = int.tryParse(v) ?? 0;');
          } else {
            buffer.writeln(
                '          widget.controller.${field.name}.value = double.tryParse(v) ?? 0.0;');
          }
          if (field.hasAsyncValidator) {
            final debounce = field.asyncDebounceMs ?? 500;
            buffer.writeln(
                '          widget.controller._triggerAsyncValidation(\'${field.name}\', widget.controller.${field.name}.value, $debounce);');
          }
          buffer.writeln('        },');
          buffer.writeln('      ),');
          buffer.writeln('    );');
          break;
        default:
          // String and other types — TextFormField
          buffer.writeln('    return Padding(');
          buffer.writeln(
              '      padding: const EdgeInsets.symmetric(vertical: 8.0),');
          buffer.writeln('      child: TextFormField(');
          buffer.writeln('        decoration: InputDecoration(');
          buffer.writeln("          labelText: '$label',");
          buffer.writeln(
              '          errorText: widget.controller.${field.name}.error,');
          buffer.writeln('        ),');
          buffer.writeln('        onChanged: (v) {');
          buffer.writeln(
              '          widget.controller.${field.name}.value = v;');
          if (field.hasAsyncValidator) {
            final debounce = field.asyncDebounceMs ?? 500;
            buffer.writeln(
                '          widget.controller._triggerAsyncValidation(\'${field.name}\', widget.controller.${field.name}.value, $debounce);');
          }
          buffer.writeln('        },');
          buffer.writeln('      ),');
          buffer.writeln('    );');
          break;
      }
    }

    buffer.writeln('  }');
    buffer.writeln();
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
      default:
        if (field.isEnum && field.enumValues != null && field.enumValues!.isNotEmpty) {
          return '${field.typeName}.${field.enumValues!.first}';
        }
        return 'null';
    }
  }
}

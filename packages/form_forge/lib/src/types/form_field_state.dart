import 'package:flutter/foundation.dart';

/// Represents the state of a single form field including its value,
/// validation error, and loading state.
///
/// Each field in a generated form controller has a corresponding
/// [FormFieldState] that tracks the field's current value, validation
/// errors, and whether async validation is in progress.
///
/// ```dart
/// final field = FormFieldState<String>(initialValue: '');
/// field.value = 'hello@example.com';
/// print(field.isValid); // true (no error set)
/// ```
class FormFieldState<T> extends ChangeNotifier {
  T _value;
  String? _error;
  final T _initialValue;

  /// Creates a [FormFieldState] with the given [initialValue].
  FormFieldState({required T initialValue})
      : _value = initialValue,
        _initialValue = initialValue;

  /// The current value of the field.
  T get value => _value;

  /// Sets the current value and notifies listeners.
  set value(T newValue) {
    if (_value != newValue) {
      _value = newValue;
      notifyListeners();
    }
  }

  /// The current validation error message, or `null` if the field is valid.
  String? get error => _error;

  /// Sets the validation error and notifies listeners.
  set error(String? newError) {
    if (_error != newError) {
      _error = newError;
      notifyListeners();
    }
  }

  /// Whether the field is currently valid (has no error).
  bool get isValid => _error == null;

  /// Resets the field to its initial value and clears any error.
  void reset() {
    _value = _initialValue;
    _error = null;
    notifyListeners();
  }
}

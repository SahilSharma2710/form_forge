import 'package:flutter/foundation.dart';

/// Represents the state of a single form field including its value,
/// validation error, and loading state.
///
/// Each field in a generated form controller has a corresponding
/// [ForgeFieldState] that tracks the field's current value, validation
/// errors, whether async validation is in progress, and enabled state.
///
/// ```dart
/// final field = ForgeFieldState<String>(initialValue: '');
/// field.value = 'hello@example.com';
/// print(field.isValid); // true (no error set)
/// ```
class ForgeFieldState<T> extends ChangeNotifier {
  T _value;
  String? _error;
  final T _initialValue;
  bool _isEnabled;
  bool _isValidating;

  /// Creates a [ForgeFieldState] with the given [initialValue].
  ForgeFieldState({required T initialValue, bool enabled = true})
      : _value = initialValue,
        _initialValue = initialValue,
        _isEnabled = enabled,
        _isValidating = false;

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

  /// Whether the field is currently enabled.
  ///
  /// Disabled fields skip validation and render as disabled in the UI.
  bool get isEnabled => _isEnabled;

  /// Sets the enabled state and notifies listeners.
  set isEnabled(bool value) {
    if (_isEnabled != value) {
      _isEnabled = value;
      notifyListeners();
    }
  }

  /// Whether the field is currently running async validation.
  bool get isValidating => _isValidating;

  /// Sets the async validation state and notifies listeners.
  set isValidating(bool value) {
    if (_isValidating != value) {
      _isValidating = value;
      notifyListeners();
    }
  }

  /// The initial value used for reset operations.
  T get initialValue => _initialValue;

  /// Resets the field to its initial value and clears any error.
  void reset() {
    _value = _initialValue;
    _error = null;
    _isValidating = false;
    notifyListeners();
  }

  /// Clears only the error without changing the value.
  void clearError() {
    if (_error != null) {
      _error = null;
      notifyListeners();
    }
  }
}

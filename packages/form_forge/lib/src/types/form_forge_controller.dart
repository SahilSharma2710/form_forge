import 'package:flutter/foundation.dart';

import 'form_field_state.dart';

/// Base class for all generated form controllers.
///
/// Generated controllers extend this class and override [fields] to provide
/// the list of field states. The base class provides common functionality
/// like overall validity checking, error aggregation, reset, and enabled state.
///
/// This class uses [ChangeNotifier] so it can be listened to by any Flutter
/// state management solution (Provider, Riverpod, Bloc, or vanilla setState).
///
/// ```dart
/// // Generated code extends this:
/// class LoginFormController extends FormForgeController {
///   final ForgeFieldState<String> email = ForgeFieldState(initialValue: '');
///   final ForgeFieldState<String> password = ForgeFieldState(initialValue: '');
///
///   @override
///   List<ForgeFieldState<Object?>> get fields => [email, password];
/// }
/// ```
abstract class FormForgeController extends ChangeNotifier {
  bool _fieldsInitialized = false;
  bool _isEnabled = true;

  /// The list of all field states in this form.
  ///
  /// Subclasses must override this to return all [ForgeFieldState] instances.
  List<ForgeFieldState<Object?>> get fields;

  /// Whether all fields in the form are currently valid.
  bool get isValid => fields.every((field) => field.isValid);

  /// Whether the entire form is enabled.
  ///
  /// When disabled, all fields are rendered as disabled and validation is skipped.
  bool get isEnabled => _isEnabled;

  /// Sets the enabled state for the entire form.
  set isEnabled(bool value) {
    if (_isEnabled != value) {
      _isEnabled = value;
      for (final field in fields) {
        field.isEnabled = value;
      }
      notifyListeners();
    }
  }

  /// Returns a map of field errors keyed by field index.
  ///
  /// Generated controllers override this with named keys.
  Map<String, String?> get errors {
    final result = <String, String?>{};
    for (final field in fields) {
      // Subclasses should override for named keys.
      // Base implementation uses object hashCode as fallback.
      result[_fieldName(field)] = field.error;
    }
    return result;
  }

  /// Resets all fields to their initial values and clears errors.
  void reset() {
    for (final field in fields) {
      field.reset();
    }
    notifyListeners();
  }

  /// Clears all field errors without changing values.
  void clearErrors() {
    for (final field in fields) {
      field.clearError();
    }
    notifyListeners();
  }

  /// Initializes field listeners to propagate changes to the controller.
  ///
  /// Called once during first access. Generated controllers call this
  /// in their constructor.
  @protected
  void initializeFields() {
    if (_fieldsInitialized) return;
    _fieldsInitialized = true;
    for (final field in fields) {
      field.addListener(notifyListeners);
    }
  }

  String _fieldName(ForgeFieldState<Object?> field) {
    final index = fields.indexOf(field);
    return index >= 0 ? 'field_$index' : 'unknown';
  }

  @override
  void dispose() {
    for (final field in fields) {
      field.removeListener(notifyListeners);
      field.dispose();
    }
    super.dispose();
  }
}

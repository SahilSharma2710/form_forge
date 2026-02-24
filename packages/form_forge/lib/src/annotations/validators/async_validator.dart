import '../../constants/defaults.dart';

/// Typedef for async validator functions.
///
/// Takes the current field value and returns `null` if valid,
/// or an error message string if invalid.
typedef AsyncValidatorFn = Future<String?> Function(dynamic value);

/// Marks a field for asynchronous validation.
///
/// Async validators run after sync validators pass (Phase 3 of validation
/// pipeline). They are automatically debounced to avoid excessive API calls.
///
/// Register the actual validator function at runtime via
/// `controller.registerAsyncValidator('fieldName', validatorFn)`.
///
/// ```dart
/// @AsyncValidate()
/// final String email;
///
/// @AsyncValidate(debounceMs: 1000)
/// final String username;
/// ```
///
/// Then in your widget:
/// ```dart
/// final controller = MyFormFormController();
/// controller.registerAsyncValidator('email', (value) async {
///   final exists = await api.checkEmail(value as String);
///   return exists ? 'Email already taken' : null;
/// });
/// ```
class AsyncValidate {
  /// Debounce delay in milliseconds before triggering validation.
  final int debounceMs;

  /// Creates an [AsyncValidate] marker annotation with optional [debounceMs].
  const AsyncValidate({this.debounceMs = FormForgeDefaults.asyncDebounceMs});
}

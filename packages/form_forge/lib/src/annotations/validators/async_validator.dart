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
/// A loading indicator is shown while validation is in progress.
///
/// Register the actual validator function at runtime via
/// `controller.registerAsyncValidator('fieldName', validatorFn)`.
///
/// ```dart
/// @AsyncValidate()
/// final String email;
///
/// @AsyncValidate(debounce: Duration(seconds: 1))
/// final String username;
///
/// // Legacy support: using milliseconds directly
/// @AsyncValidate(debounceMs: 1000)
/// final String legacyField;
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
  /// Debounce delay as Duration before triggering validation.
  ///
  /// If provided, takes precedence over [debounceMs].
  final Duration? debounce;

  /// Debounce delay in milliseconds before triggering validation.
  ///
  /// Deprecated: Use [debounce] instead.
  final int debounceMs;

  /// Creates an [AsyncValidate] marker annotation.
  ///
  /// Use [debounce] for Duration-based debounce, or [debounceMs] for
  /// milliseconds (legacy support).
  const AsyncValidate({
    this.debounce,
    this.debounceMs = FormForgeDefaults.asyncDebounceMs,
  });

  /// Returns the effective debounce duration in milliseconds.
  int get effectiveDebounceMs => debounce?.inMilliseconds ?? debounceMs;
}

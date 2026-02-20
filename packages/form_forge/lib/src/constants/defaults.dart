/// Default validation error messages used when no custom message is provided.
class FormForgeDefaults {
  FormForgeDefaults._();

  /// Default error for [IsRequired].
  static const String required = 'This field is required';

  /// Default error for [IsEmail].
  static const String email = 'Please enter a valid email address';

  /// Default error for [MinLength]. Use [minLengthMessage] for formatted version.
  static String minLength(int length) =>
      'Must be at least $length characters';

  /// Default error for [MaxLength]. Use [maxLengthMessage] for formatted version.
  static String maxLength(int length) =>
      'Must be at most $length characters';

  /// Default error for [PatternValidator].
  static const String pattern = 'Invalid format';

  /// Default error for [Min].
  static String min(num value) => 'Must be at least $value';

  /// Default error for [Max].
  static String max(num value) => 'Must be at most $value';

  /// Default error for [MustMatch].
  static String mustMatch(String field) => 'Must match $field';

  /// Default debounce duration for async validators in milliseconds.
  static const int asyncDebounceMs = 500;
}

/// Controls conditional visibility of a form field.
///
/// The field will only be visible when the specified condition is met.
/// Use [field] to reference another field's name, and [equals] to specify
/// the value that field must have for this field to be visible.
///
/// ```dart
/// @FormForge()
/// class CheckoutForm {
///   late final bool useShippingAddress;
///
///   @ShowWhen('useShippingAddress', equals: false)
///   late final String billingAddress;
///
///   late final String paymentMethod;
///
///   @ShowWhen('paymentMethod', equals: 'credit_card')
///   late final String cardNumber;
///
///   @ShowWhen('paymentMethod', equals: 'credit_card')
///   late final String expiryDate;
/// }
/// ```
class ShowWhen {
  /// The name of the field to observe.
  final String field;

  /// The value the observed field must have for this field to be visible.
  final Object? equals;

  /// Creates a [ShowWhen] annotation.
  ///
  /// [field] is the name of the field to observe.
  /// [equals] is the value that triggers visibility.
  const ShowWhen(this.field, {required this.equals});
}

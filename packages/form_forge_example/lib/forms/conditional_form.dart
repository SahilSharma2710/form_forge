import 'package:form_forge/form_forge.dart';

part 'conditional_form.g.dart';

/// Demonstrates conditional field visibility with @ShowWhen annotation.
@FormForge()
class ConditionalForm {
  late final String paymentMethod;

  @ShowWhen('paymentMethod', equals: 'credit_card')
  @IsRequired()
  late final String cardNumber;

  @ShowWhen('paymentMethod', equals: 'credit_card')
  @IsRequired()
  late final String expiryDate;

  @ShowWhen('paymentMethod', equals: 'credit_card')
  @IsRequired()
  @MinLength(3)
  @MaxLength(4)
  late final String cvv;

  @ShowWhen('paymentMethod', equals: 'bank_transfer')
  @IsRequired()
  late final String accountNumber;

  @ShowWhen('paymentMethod', equals: 'bank_transfer')
  @IsRequired()
  late final String routingNumber;

  late final bool savePaymentInfo;
}

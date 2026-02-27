import 'package:form_forge/form_forge.dart';

part 'wizard_form.g.dart';

/// Demonstrates multi-step wizard form with @FormStep annotation.
@FormForge()
class WizardForm {
  // Step 0: Personal Info
  @FormStep(0, title: 'Personal Info')
  @IsRequired()
  late final String firstName;

  @FormStep(0, title: 'Personal Info')
  @IsRequired()
  late final String lastName;

  @FormStep(0, title: 'Personal Info')
  @IsRequired()
  @IsEmail()
  late final String email;

  // Step 1: Contact Details
  @FormStep(1, title: 'Contact')
  @PhoneNumber()
  late final String phone;

  @FormStep(1, title: 'Contact')
  late final String address;

  // Step 2: Preferences
  @FormStep(2, title: 'Preferences')
  late final bool newsletter;

  @FormStep(2, title: 'Preferences')
  @SliderInput(min: 1, max: 10, divisions: 9)
  late final int notificationFrequency;
}

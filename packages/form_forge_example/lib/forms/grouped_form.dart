import 'package:form_forge/form_forge.dart';

part 'grouped_form.g.dart';

/// Demonstrates field grouping with @FieldGroup annotation.
@FormForge()
class GroupedForm {
  @FieldGroup('Personal Information')
  @IsRequired()
  late final String fullName;

  @FieldGroup('Personal Information')
  @IsRequired()
  @IsEmail()
  late final String email;

  @FieldGroup('Personal Information')
  @PhoneNumber()
  late final String phone;

  @FieldGroup('Address')
  @IsRequired()
  late final String street;

  @FieldGroup('Address')
  @IsRequired()
  late final String city;

  @FieldGroup('Address')
  @IsRequired()
  late final String zipCode;

  @FieldGroup('Preferences')
  late final bool marketingEmails;

  @FieldGroup('Preferences')
  late final bool smsNotifications;
}

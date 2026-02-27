/// Assigns a field to a specific step in a multi-step wizard form.
///
/// When at least one field has a [FormStep] annotation, the generated form
/// will render as a wizard with stepper navigation or page-view navigation.
///
/// ```dart
/// @FormForge()
/// class RegistrationForm {
///   @FormStep(0, title: 'Personal Info')
///   @IsRequired()
///   late final String name;
///
///   @FormStep(0, title: 'Personal Info')
///   @IsRequired()
///   @IsEmail()
///   late final String email;
///
///   @FormStep(1, title: 'Address')
///   @IsRequired()
///   late final String street;
///
///   @FormStep(1, title: 'Address')
///   late final String city;
///
///   @FormStep(2, title: 'Review')
///   late final bool agreeToTerms;
/// }
/// ```
class FormStep {
  /// The step index (0-based) this field belongs to.
  final int step;

  /// The title displayed for this step in the stepper/wizard UI.
  final String? title;

  /// Creates a [FormStep] annotation with the given [step] index and optional [title].
  const FormStep(this.step, {this.title});
}

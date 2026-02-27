/// Groups form fields into visual sections with headers.
///
/// Fields with the same [name] will be rendered together under a common
/// section header. This helps organize complex forms into logical groups.
///
/// ```dart
/// @FormForge()
/// class ProfileForm {
///   @FieldGroup('Personal Information')
///   @IsRequired()
///   late final String firstName;
///
///   @FieldGroup('Personal Information')
///   @IsRequired()
///   late final String lastName;
///
///   @FieldGroup('Contact Details')
///   @IsEmail()
///   late final String email;
///
///   @FieldGroup('Contact Details')
///   @PhoneNumber()
///   late final String phone;
///
///   @FieldGroup('Preferences')
///   late final bool newsletter;
/// }
/// ```
class FieldGroup {
  /// The display name for this group, shown as a section header.
  final String name;

  /// Creates a [FieldGroup] annotation with the given group [name].
  const FieldGroup(this.name);
}

import 'package:form_forge/form_forge.dart';

/// Profile edit form demonstrating multiple field types.
///
/// Showcases:
/// - String, int, bool, and nullable fields
/// - Numeric validation with @Min / @Max
/// - Optional fields via nullable types
@FormForge()
class ProfileForm {
  @IsRequired()
  late final String displayName;

  late final String? bio;

  @Min(13, message: 'Must be at least 13 years old')
  @Max(120)
  late final int age;

  late final bool receiveNewsletter;
}

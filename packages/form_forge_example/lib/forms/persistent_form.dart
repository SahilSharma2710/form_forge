import 'package:form_forge/form_forge.dart';

part 'persistent_form.g.dart';

/// Demonstrates SharedPreferences persistence with persistKey.
@FormForge(persistKey: 'draft_application')
class PersistentForm {
  @IsRequired()
  late final String title;

  @RichTextInput(minLines: 5, maxLines: 15)
  late final String content;

  @ChipsInput()
  late final List<String> categories;

  late final bool publishImmediately;
}

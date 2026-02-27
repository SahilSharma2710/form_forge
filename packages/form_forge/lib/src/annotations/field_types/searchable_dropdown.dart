/// Marks a field as a searchable dropdown.
///
/// Unlike a standard dropdown, this widget allows users to type and filter
/// options. Ideal for fields with many possible values.
///
/// ```dart
/// @SearchableDropdown()
/// late final Country country;
///
/// @SearchableDropdown(hintText: 'Search countries...')
/// late final String countryCode;
/// ```
class SearchableDropdown {
  /// Placeholder text shown in the search input.
  final String? hintText;

  /// Creates a [SearchableDropdown] annotation with optional [hintText].
  const SearchableDropdown({this.hintText});
}

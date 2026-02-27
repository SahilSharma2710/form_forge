/// Marks a field as a date range picker.
///
/// The generated form will render a date range selection widget
/// allowing users to pick a start and end date.
///
/// The field type should be `DateTimeRange` from Flutter's material library.
///
/// ```dart
/// @DateRange()
/// late final DateTimeRange vacationDates;
///
/// @DateRange(firstDate: 2020, lastDate: 2030)
/// late final DateTimeRange bookingPeriod;
/// ```
class DateRange {
  /// The earliest selectable year.
  final int? firstDate;

  /// The latest selectable year.
  final int? lastDate;

  /// Helper text displayed in the picker dialog.
  final String? helpText;

  /// Creates a [DateRange] annotation with optional date bounds.
  const DateRange({this.firstDate, this.lastDate, this.helpText});
}

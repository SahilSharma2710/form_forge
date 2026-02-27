import 'package:flutter/material.dart';

/// Theme configuration for form_forge generated forms.
///
/// Use [FormForgeTheme] to customize the appearance of generated form widgets
/// including input decorations, spacing, label styles, and more.
///
/// Wrap your form widget with [FormForgeThemeProvider] to apply the theme:
///
/// ```dart
/// FormForgeThemeProvider(
///   theme: FormForgeTheme(
///     inputDecoration: InputDecoration(
///       border: OutlineInputBorder(),
///       filled: true,
///       fillColor: Colors.grey[100],
///     ),
///     fieldSpacing: 24.0,
///     labelStyle: TextStyle(fontWeight: FontWeight.bold),
///   ),
///   child: MyFormWidget(controller: controller),
/// )
/// ```
class FormForgeTheme {
  /// Base input decoration applied to all form fields.
  ///
  /// Individual field decorations will be merged with this base decoration.
  final InputDecoration? inputDecoration;

  /// Vertical spacing between form fields.
  final double fieldSpacing;

  /// Style applied to field labels.
  final TextStyle? labelStyle;

  /// Style applied to field hint text.
  final TextStyle? hintStyle;

  /// Style applied to error messages.
  final TextStyle? errorStyle;

  /// Style applied to group headers when using [FieldGroup].
  final TextStyle? groupHeaderStyle;

  /// Padding around group sections.
  final EdgeInsets? groupPadding;

  /// Style for step titles in multi-step forms.
  final TextStyle? stepTitleStyle;

  /// Color for active/current step indicator.
  final Color? stepActiveColor;

  /// Color for completed step indicator.
  final Color? stepCompletedColor;

  /// Color for inactive/pending step indicator.
  final Color? stepInactiveColor;

  /// Padding around the entire form.
  final EdgeInsets? formPadding;

  /// Border radius for input fields (when using OutlineInputBorder).
  final BorderRadius? inputBorderRadius;

  /// Color for the loading indicator during async validation.
  final Color? asyncValidatingColor;

  /// Size of the loading indicator during async validation.
  final double asyncValidatingIndicatorSize;

  /// Whether to show a suffix icon for fields with async validation.
  final bool showAsyncValidatingIndicator;

  /// Creates a [FormForgeTheme] with optional customizations.
  const FormForgeTheme({
    this.inputDecoration,
    this.fieldSpacing = 16.0,
    this.labelStyle,
    this.hintStyle,
    this.errorStyle,
    this.groupHeaderStyle,
    this.groupPadding,
    this.stepTitleStyle,
    this.stepActiveColor,
    this.stepCompletedColor,
    this.stepInactiveColor,
    this.formPadding,
    this.inputBorderRadius,
    this.asyncValidatingColor,
    this.asyncValidatingIndicatorSize = 16.0,
    this.showAsyncValidatingIndicator = true,
  });

  /// Creates a copy of this theme with the given fields replaced.
  FormForgeTheme copyWith({
    InputDecoration? inputDecoration,
    double? fieldSpacing,
    TextStyle? labelStyle,
    TextStyle? hintStyle,
    TextStyle? errorStyle,
    TextStyle? groupHeaderStyle,
    EdgeInsets? groupPadding,
    TextStyle? stepTitleStyle,
    Color? stepActiveColor,
    Color? stepCompletedColor,
    Color? stepInactiveColor,
    EdgeInsets? formPadding,
    BorderRadius? inputBorderRadius,
    Color? asyncValidatingColor,
    double? asyncValidatingIndicatorSize,
    bool? showAsyncValidatingIndicator,
  }) {
    return FormForgeTheme(
      inputDecoration: inputDecoration ?? this.inputDecoration,
      fieldSpacing: fieldSpacing ?? this.fieldSpacing,
      labelStyle: labelStyle ?? this.labelStyle,
      hintStyle: hintStyle ?? this.hintStyle,
      errorStyle: errorStyle ?? this.errorStyle,
      groupHeaderStyle: groupHeaderStyle ?? this.groupHeaderStyle,
      groupPadding: groupPadding ?? this.groupPadding,
      stepTitleStyle: stepTitleStyle ?? this.stepTitleStyle,
      stepActiveColor: stepActiveColor ?? this.stepActiveColor,
      stepCompletedColor: stepCompletedColor ?? this.stepCompletedColor,
      stepInactiveColor: stepInactiveColor ?? this.stepInactiveColor,
      formPadding: formPadding ?? this.formPadding,
      inputBorderRadius: inputBorderRadius ?? this.inputBorderRadius,
      asyncValidatingColor: asyncValidatingColor ?? this.asyncValidatingColor,
      asyncValidatingIndicatorSize:
          asyncValidatingIndicatorSize ?? this.asyncValidatingIndicatorSize,
      showAsyncValidatingIndicator:
          showAsyncValidatingIndicator ?? this.showAsyncValidatingIndicator,
    );
  }

  /// Merges this theme with another, with [other] taking precedence.
  FormForgeTheme merge(FormForgeTheme? other) {
    if (other == null) return this;
    return copyWith(
      inputDecoration: other.inputDecoration ?? inputDecoration,
      fieldSpacing: other.fieldSpacing,
      labelStyle: other.labelStyle ?? labelStyle,
      hintStyle: other.hintStyle ?? hintStyle,
      errorStyle: other.errorStyle ?? errorStyle,
      groupHeaderStyle: other.groupHeaderStyle ?? groupHeaderStyle,
      groupPadding: other.groupPadding ?? groupPadding,
      stepTitleStyle: other.stepTitleStyle ?? stepTitleStyle,
      stepActiveColor: other.stepActiveColor ?? stepActiveColor,
      stepCompletedColor: other.stepCompletedColor ?? stepCompletedColor,
      stepInactiveColor: other.stepInactiveColor ?? stepInactiveColor,
      formPadding: other.formPadding ?? formPadding,
      inputBorderRadius: other.inputBorderRadius ?? inputBorderRadius,
      asyncValidatingColor: other.asyncValidatingColor ?? asyncValidatingColor,
      asyncValidatingIndicatorSize: other.asyncValidatingIndicatorSize,
      showAsyncValidatingIndicator: other.showAsyncValidatingIndicator,
    );
  }
}

/// Provides a [FormForgeTheme] to descendant widgets.
///
/// Use this widget to apply consistent theming across all form_forge
/// generated forms in your widget tree.
///
/// ```dart
/// FormForgeThemeProvider(
///   theme: FormForgeTheme(
///     fieldSpacing: 20.0,
///     inputDecoration: InputDecoration(
///       border: OutlineInputBorder(),
///     ),
///   ),
///   child: MyApp(),
/// )
/// ```
class FormForgeThemeProvider extends InheritedWidget {
  /// The theme configuration to provide to descendants.
  final FormForgeTheme theme;

  /// Creates a [FormForgeThemeProvider].
  const FormForgeThemeProvider({
    super.key,
    required this.theme,
    required super.child,
  });

  /// Retrieves the nearest [FormForgeTheme] from the widget tree.
  ///
  /// Returns a default theme if no [FormForgeThemeProvider] is found.
  static FormForgeTheme of(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<FormForgeThemeProvider>();
    return provider?.theme ?? const FormForgeTheme();
  }

  /// Retrieves the nearest [FormForgeTheme] without establishing a dependency.
  ///
  /// Returns null if no [FormForgeThemeProvider] is found.
  static FormForgeTheme? maybeOf(BuildContext context) {
    final provider =
        context.dependOnInheritedWidgetOfExactType<FormForgeThemeProvider>();
    return provider?.theme;
  }

  @override
  bool updateShouldNotify(FormForgeThemeProvider oldWidget) {
    return theme != oldWidget.theme;
  }
}

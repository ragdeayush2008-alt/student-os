import 'package:flutter/material.dart';

/// Semantic convenience getters for the text theme.
extension AppTextThemeX on ThemeData {
  TextTheme get appText => textTheme;
}

/// Convenience extension to access the text theme from a [BuildContext].
extension AppBuildContextText on BuildContext {
  TextTheme get text => Theme.of(this).textTheme;
}

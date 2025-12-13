/// Application Theme
///
/// Consistent theming for the example app including colors, text styles,
/// and component themes.

import 'package:flutter/material.dart';
import 'constants.dart';

class AppTheme {
  AppTheme._();

  // Primary colors
  static const Color primaryColor = Color(0xFF4264FB); // Mapbox blue
  static const Color secondaryColor = Color(0xFF28A745);
  static const Color errorColor = Color(0xFFDC3545);
  static const Color warningColor = Color(0xFFFFC107);

  // Background colors
  static const Color scaffoldBackground = Color(0xFFF5F5F5);
  static const Color cardBackground = Colors.white;
  static const Color surfaceColor = Colors.white;

  // Feature category colors
  static const Color coreFeatureColor = Color(0xFF4264FB);
  static const Color mapFeatureColor = Color(0xFF28A745);
  static const Color advancedFeatureColor = Color(0xFFFF9800);

  /// Light theme for the app
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: scaffoldBackground,
      appBarTheme: const AppBarTheme(
        centerTitle: true,
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
      ),
      cardTheme: CardTheme(
        elevation: UIConstants.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UIConstants.borderRadius),
        ),
        color: cardBackground,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
      dividerTheme: const DividerThemeData(
        space: 1,
        thickness: 1,
      ),
    );
  }

  /// Get color for feature category
  static Color getCategoryColor(FeatureCategory category) {
    switch (category) {
      case FeatureCategory.core:
        return coreFeatureColor;
      case FeatureCategory.mapFeatures:
        return mapFeatureColor;
      case FeatureCategory.advanced:
        return advancedFeatureColor;
    }
  }
}

import 'package:flutter/material.dart';

/// Builder for creating [TripProgressConfig] with a fluent API.
///
/// Example usage:
/// ```dart
/// final config = TripProgressConfigBuilder()
///   .withSkipButtons()
///   .withProgressBar()
///   .withEta()
///   .withTheme(TripProgressTheme.dark())
///   .build();
/// ```
class TripProgressConfigBuilder {
  bool _showSkipButtons = true;
  bool _showProgressBar = true;
  bool _showEta = true;
  bool _showTotalDistance = true;
  bool _showEndNavigationButton = true;
  bool _showWaypointCount = true;
  bool _showDistanceToNext = true;
  bool _showDurationToNext = true;
  bool _showCurrentSpeed = false;
  bool _enableAudioFeedback = true;
  double? _panelHeight;
  TripProgressTheme? _theme;

  /// Start with default (all enabled) configuration.
  TripProgressConfigBuilder();

  /// Start with minimal configuration (most features disabled).
  factory TripProgressConfigBuilder.minimal() {
    return TripProgressConfigBuilder()
      ..hideSkipButtons()
      ..hideProgressBar()
      ..hideEta()
      ..hideTotalDistance()
      ..hideWaypointCount()
      ..disableAudioFeedback();
  }

  /// Enable skip previous/next buttons.
  TripProgressConfigBuilder withSkipButtons() {
    _showSkipButtons = true;
    return this;
  }

  /// Disable skip previous/next buttons.
  TripProgressConfigBuilder hideSkipButtons() {
    _showSkipButtons = false;
    return this;
  }

  /// Enable the progress bar.
  TripProgressConfigBuilder withProgressBar() {
    _showProgressBar = true;
    return this;
  }

  /// Disable the progress bar.
  TripProgressConfigBuilder hideProgressBar() {
    _showProgressBar = false;
    return this;
  }

  /// Enable ETA display.
  TripProgressConfigBuilder withEta() {
    _showEta = true;
    return this;
  }

  /// Disable ETA display.
  TripProgressConfigBuilder hideEta() {
    _showEta = false;
    return this;
  }

  /// Enable total distance remaining display.
  TripProgressConfigBuilder withTotalDistance() {
    _showTotalDistance = true;
    return this;
  }

  /// Disable total distance remaining display.
  TripProgressConfigBuilder hideTotalDistance() {
    _showTotalDistance = false;
    return this;
  }

  /// Enable end navigation button.
  TripProgressConfigBuilder withEndNavigationButton() {
    _showEndNavigationButton = true;
    return this;
  }

  /// Disable end navigation button.
  TripProgressConfigBuilder hideEndNavigationButton() {
    _showEndNavigationButton = false;
    return this;
  }

  /// Enable waypoint count display (e.g., "Waypoint 3/8").
  TripProgressConfigBuilder withWaypointCount() {
    _showWaypointCount = true;
    return this;
  }

  /// Disable waypoint count display.
  TripProgressConfigBuilder hideWaypointCount() {
    _showWaypointCount = false;
    return this;
  }

  /// Enable distance to next waypoint.
  TripProgressConfigBuilder withDistanceToNext() {
    _showDistanceToNext = true;
    return this;
  }

  /// Disable distance to next waypoint.
  TripProgressConfigBuilder hideDistanceToNext() {
    _showDistanceToNext = false;
    return this;
  }

  /// Enable duration to next waypoint.
  TripProgressConfigBuilder withDurationToNext() {
    _showDurationToNext = true;
    return this;
  }

  /// Disable duration to next waypoint.
  TripProgressConfigBuilder hideDurationToNext() {
    _showDurationToNext = false;
    return this;
  }

  /// Enable current speed display.
  TripProgressConfigBuilder withCurrentSpeed() {
    _showCurrentSpeed = true;
    return this;
  }

  /// Disable current speed display.
  TripProgressConfigBuilder hideCurrentSpeed() {
    _showCurrentSpeed = false;
    return this;
  }

  /// Enable audio feedback for button presses.
  TripProgressConfigBuilder enableAudioFeedback() {
    _enableAudioFeedback = true;
    return this;
  }

  /// Disable audio feedback for button presses.
  TripProgressConfigBuilder disableAudioFeedback() {
    _enableAudioFeedback = false;
    return this;
  }

  /// Set a custom panel height.
  TripProgressConfigBuilder withPanelHeight(double height) {
    _panelHeight = height;
    return this;
  }

  /// Apply a theme to the panel.
  TripProgressConfigBuilder withTheme(TripProgressTheme theme) {
    _theme = theme;
    return this;
  }

  /// Apply the light theme preset.
  TripProgressConfigBuilder withLightTheme() {
    _theme = TripProgressTheme.light();
    return this;
  }

  /// Apply the dark theme preset.
  TripProgressConfigBuilder withDarkTheme() {
    _theme = TripProgressTheme.dark();
    return this;
  }

  /// Build the final [TripProgressConfig].
  TripProgressConfig build() {
    return TripProgressConfig(
      showSkipButtons: _showSkipButtons,
      showProgressBar: _showProgressBar,
      showEta: _showEta,
      showTotalDistance: _showTotalDistance,
      showEndNavigationButton: _showEndNavigationButton,
      showWaypointCount: _showWaypointCount,
      showDistanceToNext: _showDistanceToNext,
      showDurationToNext: _showDurationToNext,
      showCurrentSpeed: _showCurrentSpeed,
      enableAudioFeedback: _enableAudioFeedback,
      panelHeight: _panelHeight,
      theme: _theme,
    );
  }
}

/// Builder for creating [TripProgressTheme] with a fluent API.
///
/// Example usage:
/// ```dart
/// final theme = TripProgressThemeBuilder()
///   .fromLight()  // Start with light theme base
///   .primaryColor(Colors.indigo)
///   .accentColor(Colors.amber)
///   .addCategoryColor('checkpoint', Colors.red)
///   .build();
/// ```
class TripProgressThemeBuilder {
  Color? _primaryColor;
  Color? _accentColor;
  Color? _backgroundColor;
  Color? _textPrimaryColor;
  Color? _textSecondaryColor;
  Color? _buttonBackgroundColor;
  Color? _endButtonColor;
  Color? _progressBarColor;
  Color? _progressBarBackgroundColor;
  double? _cornerRadius;
  double? _buttonSize;
  double? _iconSize;
  Map<String, Color>? _categoryColors;

  /// Create a new theme builder with default values.
  TripProgressThemeBuilder();

  /// Start from the light theme preset.
  TripProgressThemeBuilder fromLight() {
    final light = TripProgressTheme.light();
    _primaryColor = light.primaryColor;
    _accentColor = light.accentColor;
    _backgroundColor = light.backgroundColor;
    _textPrimaryColor = light.textPrimaryColor;
    _textSecondaryColor = light.textSecondaryColor;
    _buttonBackgroundColor = light.buttonBackgroundColor;
    _endButtonColor = light.endButtonColor;
    _progressBarColor = light.progressBarColor;
    _progressBarBackgroundColor = light.progressBarBackgroundColor;
    _cornerRadius = light.cornerRadius;
    _buttonSize = light.buttonSize;
    _iconSize = light.iconSize;
    return this;
  }

  /// Start from the dark theme preset.
  TripProgressThemeBuilder fromDark() {
    final dark = TripProgressTheme.dark();
    _primaryColor = dark.primaryColor;
    _accentColor = dark.accentColor;
    _backgroundColor = dark.backgroundColor;
    _textPrimaryColor = dark.textPrimaryColor;
    _textSecondaryColor = dark.textSecondaryColor;
    _buttonBackgroundColor = dark.buttonBackgroundColor;
    _endButtonColor = dark.endButtonColor;
    _progressBarColor = dark.progressBarColor;
    _progressBarBackgroundColor = dark.progressBarBackgroundColor;
    _cornerRadius = dark.cornerRadius;
    _buttonSize = dark.buttonSize;
    _iconSize = dark.iconSize;
    return this;
  }

  /// Set the primary color.
  TripProgressThemeBuilder primaryColor(Color color) {
    _primaryColor = color;
    return this;
  }

  /// Set the accent color.
  TripProgressThemeBuilder accentColor(Color color) {
    _accentColor = color;
    return this;
  }

  /// Set the background color.
  TripProgressThemeBuilder backgroundColor(Color color) {
    _backgroundColor = color;
    return this;
  }

  /// Set the primary text color.
  TripProgressThemeBuilder textPrimaryColor(Color color) {
    _textPrimaryColor = color;
    return this;
  }

  /// Set the secondary text color.
  TripProgressThemeBuilder textSecondaryColor(Color color) {
    _textSecondaryColor = color;
    return this;
  }

  /// Set the button background color.
  TripProgressThemeBuilder buttonBackgroundColor(Color color) {
    _buttonBackgroundColor = color;
    return this;
  }

  /// Set the end navigation button color.
  TripProgressThemeBuilder endButtonColor(Color color) {
    _endButtonColor = color;
    return this;
  }

  /// Set the progress bar color.
  TripProgressThemeBuilder progressBarColor(Color color) {
    _progressBarColor = color;
    return this;
  }

  /// Set the progress bar background color.
  TripProgressThemeBuilder progressBarBackgroundColor(Color color) {
    _progressBarBackgroundColor = color;
    return this;
  }

  /// Set the corner radius for panels and buttons.
  TripProgressThemeBuilder cornerRadius(double radius) {
    _cornerRadius = radius;
    return this;
  }

  /// Set the size of skip/prev buttons.
  TripProgressThemeBuilder buttonSize(double size) {
    _buttonSize = size;
    return this;
  }

  /// Set the size of waypoint icons.
  TripProgressThemeBuilder iconSize(double size) {
    _iconSize = size;
    return this;
  }

  /// Add a color for a specific category.
  TripProgressThemeBuilder addCategoryColor(String category, Color color) {
    _categoryColors ??= {};
    _categoryColors![category.toLowerCase()] = color;
    return this;
  }

  /// Set all category colors at once.
  TripProgressThemeBuilder categoryColors(Map<String, Color> colors) {
    _categoryColors = colors.map((k, v) => MapEntry(k.toLowerCase(), v));
    return this;
  }

  /// Build the final [TripProgressTheme].
  TripProgressTheme build() {
    return TripProgressTheme(
      primaryColor: _primaryColor,
      accentColor: _accentColor,
      backgroundColor: _backgroundColor,
      textPrimaryColor: _textPrimaryColor,
      textSecondaryColor: _textSecondaryColor,
      buttonBackgroundColor: _buttonBackgroundColor,
      endButtonColor: _endButtonColor,
      progressBarColor: _progressBarColor,
      progressBarBackgroundColor: _progressBarBackgroundColor,
      cornerRadius: _cornerRadius,
      buttonSize: _buttonSize,
      iconSize: _iconSize,
      categoryColors: _categoryColors,
    );
  }
}

/// Configuration for the trip progress panel display.
///
/// This configuration controls what elements are shown in the navigation
/// info panel and how they behave. Pass this to navigation options to
/// customize the trip progress UI on both iOS and Android.
class TripProgressConfig {
  /// Creates a trip progress configuration.
  const TripProgressConfig({
    this.showSkipButtons = true,
    this.showProgressBar = true,
    this.showEta = true,
    this.showTotalDistance = true,
    this.showEndNavigationButton = true,
    this.showWaypointCount = true,
    this.showDistanceToNext = true,
    this.showDurationToNext = true,
    this.showCurrentSpeed = false,
    this.enableAudioFeedback = true,
    this.panelHeight,
    this.theme,
  });

  /// Default configuration with all features enabled.
  factory TripProgressConfig.defaults() => const TripProgressConfig();

  /// Minimal configuration showing only essential info.
  factory TripProgressConfig.minimal() => const TripProgressConfig(
        showSkipButtons: false,
        showProgressBar: false,
        showEta: false,
        showTotalDistance: false,
        showWaypointCount: false,
        enableAudioFeedback: false,
      );

  /// Whether to show skip previous/next waypoint buttons.
  /// Useful for rally/road trip scenarios where users may need to
  /// skip waypoints or go back to previous ones.
  final bool showSkipButtons;

  /// Whether to show the overall trip progress bar.
  final bool showProgressBar;

  /// Whether to show the estimated time of arrival.
  final bool showEta;

  /// Whether to show the total distance remaining to destination.
  final bool showTotalDistance;

  /// Whether to show the end navigation button in the panel.
  final bool showEndNavigationButton;

  /// Whether to show the waypoint count (e.g., "Waypoint 3/8").
  final bool showWaypointCount;

  /// Whether to show distance to the next waypoint.
  final bool showDistanceToNext;

  /// Whether to show duration to the next waypoint.
  final bool showDurationToNext;

  /// Whether to show current speed (e.g., "45 mph").
  final bool showCurrentSpeed;

  /// Whether to play audio feedback when buttons are pressed.
  final bool enableAudioFeedback;

  /// Custom panel height in logical pixels. If null, uses default height.
  final double? panelHeight;

  /// Theme configuration for colors, typography, etc.
  /// If null, uses default theme.
  final TripProgressTheme? theme;

  /// Converts this configuration to a map for native platform communication.
  Map<String, dynamic> toMap() {
    return {
      'showSkipButtons': showSkipButtons,
      'showProgressBar': showProgressBar,
      'showEta': showEta,
      'showTotalDistance': showTotalDistance,
      'showEndNavigationButton': showEndNavigationButton,
      'showWaypointCount': showWaypointCount,
      'showDistanceToNext': showDistanceToNext,
      'showDurationToNext': showDurationToNext,
      'showCurrentSpeed': showCurrentSpeed,
      'enableAudioFeedback': enableAudioFeedback,
      if (panelHeight != null) 'panelHeight': panelHeight,
      if (theme != null) 'theme': theme!.toMap(),
    };
  }

  /// Creates a copy with the given fields replaced.
  TripProgressConfig copyWith({
    bool? showSkipButtons,
    bool? showProgressBar,
    bool? showEta,
    bool? showTotalDistance,
    bool? showEndNavigationButton,
    bool? showWaypointCount,
    bool? showDistanceToNext,
    bool? showDurationToNext,
    bool? showCurrentSpeed,
    bool? enableAudioFeedback,
    double? panelHeight,
    TripProgressTheme? theme,
  }) {
    return TripProgressConfig(
      showSkipButtons: showSkipButtons ?? this.showSkipButtons,
      showProgressBar: showProgressBar ?? this.showProgressBar,
      showEta: showEta ?? this.showEta,
      showTotalDistance: showTotalDistance ?? this.showTotalDistance,
      showEndNavigationButton:
          showEndNavigationButton ?? this.showEndNavigationButton,
      showWaypointCount: showWaypointCount ?? this.showWaypointCount,
      showDistanceToNext: showDistanceToNext ?? this.showDistanceToNext,
      showDurationToNext: showDurationToNext ?? this.showDurationToNext,
      showCurrentSpeed: showCurrentSpeed ?? this.showCurrentSpeed,
      enableAudioFeedback: enableAudioFeedback ?? this.enableAudioFeedback,
      panelHeight: panelHeight ?? this.panelHeight,
      theme: theme ?? this.theme,
    );
  }
}

/// Theme configuration for the trip progress panel.
///
/// Customize colors, typography, and dimensions to match your app's design.
class TripProgressTheme {
  /// Creates a trip progress theme.
  const TripProgressTheme({
    this.primaryColor,
    this.accentColor,
    this.backgroundColor,
    this.textPrimaryColor,
    this.textSecondaryColor,
    this.buttonBackgroundColor,
    this.endButtonColor,
    this.progressBarColor,
    this.progressBarBackgroundColor,
    this.cornerRadius,
    this.buttonSize,
    this.iconSize,
    this.categoryColors,
  });

  /// Light theme preset.
  factory TripProgressTheme.light() => const TripProgressTheme(
        primaryColor: Color(0xFF2196F3),
        accentColor: Color(0xFFFF5722),
        backgroundColor: Color(0xFFFFFFFF),
        textPrimaryColor: Color(0xFF1A1A1A),
        textSecondaryColor: Color(0xFF666666),
        buttonBackgroundColor: Color(0xFFE3F2FD),
        endButtonColor: Color(0xFFE53935),
        progressBarColor: Color(0xFF2196F3),
        progressBarBackgroundColor: Color(0xFFE3F2FD),
        cornerRadius: 16.0,
        buttonSize: 36.0,
        iconSize: 32.0,
      );

  /// Dark theme preset.
  factory TripProgressTheme.dark() => const TripProgressTheme(
        primaryColor: Color(0xFF64B5F6),
        accentColor: Color(0xFFFF7043),
        backgroundColor: Color(0xFF1E1E1E),
        textPrimaryColor: Color(0xFFFFFFFF),
        textSecondaryColor: Color(0xFFB0B0B0),
        buttonBackgroundColor: Color(0xFF2D2D2D),
        endButtonColor: Color(0xFFEF5350),
        progressBarColor: Color(0xFF64B5F6),
        progressBarBackgroundColor: Color(0xFF2D2D2D),
        cornerRadius: 16.0,
        buttonSize: 36.0,
        iconSize: 32.0,
      );

  /// Primary color used for icons, progress bars, and highlights.
  final Color? primaryColor;

  /// Accent color used for checkpoints and important markers.
  final Color? accentColor;

  /// Background color of the panel.
  final Color? backgroundColor;

  /// Primary text color for waypoint names and main info.
  final Color? textPrimaryColor;

  /// Secondary text color for distances, times, and labels.
  final Color? textSecondaryColor;

  /// Background color for skip/prev buttons.
  final Color? buttonBackgroundColor;

  /// Color for the end navigation button.
  final Color? endButtonColor;

  /// Color for the progress bar fill.
  final Color? progressBarColor;

  /// Background color for the progress bar track.
  final Color? progressBarBackgroundColor;

  /// Corner radius for the panel and buttons.
  final double? cornerRadius;

  /// Size of the skip/prev buttons.
  final double? buttonSize;

  /// Size of waypoint icons.
  final double? iconSize;

  /// Custom colors for different waypoint categories.
  /// Keys should be lowercase category names (e.g., 'checkpoint', 'waypoint', 'poi').
  final Map<String, Color>? categoryColors;

  /// Default category colors aligned with app's design system.
  /// Primary: #2E6578 (teal), Checkpoint: #1565C0 (dark blue)
  static const Map<String, Color> defaultCategoryColors = {
    'checkpoint': Color(0xFF1565C0), // Dark blue (Material Blue 800)
    'waypoint': Color(0xFF2E6578), // Primary teal (app primary)
    'poi': Color(0xFF4CAF50), // Green
    'scenic': Color(0xFF8BC34A), // Light Green
    'restaurant': Color(0xFFFF9800), // Orange
    'food': Color(0xFFFF9800), // Orange
    'hotel': Color(0xFF5D5D70), // Tertiary
    'accommodation': Color(0xFF5D5D70), // Tertiary
    'petrol_station': Color(0xFF607D8B), // Blue Grey
    'fuel': Color(0xFF607D8B), // Blue Grey
    'parking': Color(0xFF795548), // Brown
    'hospital': Color(0xFFF44336), // Red
    'medical': Color(0xFFF44336), // Red
    'police': Color(0xFF3F51B5), // Indigo
    'charging_station': Color(0xFF00BCD4), // Cyan
  };

  /// Gets the color for a specific category, falling back to defaults.
  Color getCategoryColor(String category) {
    final lowerCategory = category.toLowerCase();
    if (categoryColors != null && categoryColors!.containsKey(lowerCategory)) {
      return categoryColors![lowerCategory]!;
    }
    return defaultCategoryColors[lowerCategory] ?? primaryColor ?? const Color(0xFF2196F3);
  }

  /// Converts this theme to a map for native platform communication.
  Map<String, dynamic> toMap() {
    return {
      if (primaryColor != null) 'primaryColor': primaryColor!.value,
      if (accentColor != null) 'accentColor': accentColor!.value,
      if (backgroundColor != null) 'backgroundColor': backgroundColor!.value,
      if (textPrimaryColor != null) 'textPrimaryColor': textPrimaryColor!.value,
      if (textSecondaryColor != null)
        'textSecondaryColor': textSecondaryColor!.value,
      if (buttonBackgroundColor != null)
        'buttonBackgroundColor': buttonBackgroundColor!.value,
      if (endButtonColor != null) 'endButtonColor': endButtonColor!.value,
      if (progressBarColor != null) 'progressBarColor': progressBarColor!.value,
      if (progressBarBackgroundColor != null)
        'progressBarBackgroundColor': progressBarBackgroundColor!.value,
      if (cornerRadius != null) 'cornerRadius': cornerRadius,
      if (buttonSize != null) 'buttonSize': buttonSize,
      if (iconSize != null) 'iconSize': iconSize,
      if (categoryColors != null)
        'categoryColors': categoryColors!.map(
          (key, value) => MapEntry(key, value.value),
        ),
    };
  }

  /// Creates a copy with the given fields replaced.
  TripProgressTheme copyWith({
    Color? primaryColor,
    Color? accentColor,
    Color? backgroundColor,
    Color? textPrimaryColor,
    Color? textSecondaryColor,
    Color? buttonBackgroundColor,
    Color? endButtonColor,
    Color? progressBarColor,
    Color? progressBarBackgroundColor,
    double? cornerRadius,
    double? buttonSize,
    double? iconSize,
    Map<String, Color>? categoryColors,
  }) {
    return TripProgressTheme(
      primaryColor: primaryColor ?? this.primaryColor,
      accentColor: accentColor ?? this.accentColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textPrimaryColor: textPrimaryColor ?? this.textPrimaryColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      buttonBackgroundColor:
          buttonBackgroundColor ?? this.buttonBackgroundColor,
      endButtonColor: endButtonColor ?? this.endButtonColor,
      progressBarColor: progressBarColor ?? this.progressBarColor,
      progressBarBackgroundColor:
          progressBarBackgroundColor ?? this.progressBarBackgroundColor,
      cornerRadius: cornerRadius ?? this.cornerRadius,
      buttonSize: buttonSize ?? this.buttonSize,
      iconSize: iconSize ?? this.iconSize,
      categoryColors: categoryColors ?? this.categoryColors,
    );
  }
}

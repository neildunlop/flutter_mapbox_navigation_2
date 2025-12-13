/// Accessibility constants and utilities for navigation components.
///
/// This file provides standardized accessibility support following
/// WCAG AA guidelines and platform-specific requirements.
library accessibility_utils;

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

// =============================================================================
// TOUCH TARGET SIZES
// =============================================================================

/// Minimum touch target size per accessibility guidelines.
///
/// - iOS minimum: 44x44 points
/// - Android minimum: 48x48 dp
/// - WCAG 2.1 AA minimum: 44x44 CSS pixels
///
/// We use 48 to satisfy all platforms.
const double kMinTouchTargetSize = 48.0;

/// Recommended touch target size for primary actions.
const double kRecommendedTouchTargetSize = 56.0;

// =============================================================================
// SEMANTIC LABELS
// =============================================================================

/// Standard semantic labels for navigation components.
abstract class NavigationSemantics {
  NavigationSemantics._(); // Prevent instantiation
  /// Label for the navigation map view.
  static const String mapView = 'Navigation map';

  /// Hint for the navigation map view.
  static const String mapViewHint = 'Shows your current route and position';

  /// Label for marker popup overlay.
  static const String markerPopup = 'Marker details';

  /// Label for close button.
  static const String closeButton = 'Close';

  /// Hint for close button.
  static const String closeButtonHint = 'Double tap to close this panel';

  /// Label for add to route button.
  static const String addToRouteButton = 'Add to route';

  /// Hint for add to route button.
  static const String addToRouteButtonHint =
      'Double tap to add this location to your route';

  /// Label format for marker title announcement.
  static String markerTitle(String title) => 'Marker: $title';

  /// Label format for marker with category.
  static String markerWithCategory(String title, String category) =>
      '$title, Category: $category';

  /// Label for navigation instructions banner.
  static const String instructionBanner = 'Navigation instruction';

  /// Label for route progress information.
  static const String routeProgress = 'Route progress';

  /// Format for distance remaining.
  static String distanceRemaining(String distance) =>
      'Distance remaining: $distance';

  /// Format for time remaining.
  static String timeRemaining(String time) => 'Time remaining: $time';

  /// Format for arrival announcement.
  static String arrivedAt(String locationName) =>
      'Arrived at $locationName';

  /// Format for next turn instruction.
  static String nextTurn(String instruction) =>
      'Next: $instruction';
}

// =============================================================================
// ACCESSIBILITY WIDGETS
// =============================================================================

/// Wraps a widget with proper touch target sizing.
///
/// Ensures the widget meets minimum touch target size requirements
/// while maintaining visual appearance.
class AccessibleTouchTarget extends StatelessWidget {
  /// The child widget to wrap.
  final Widget child;

  /// Minimum size for the touch target.
  final double minSize;

  /// Semantic label for the touch target.
  final String? semanticLabel;

  /// Semantic hint for the touch target.
  final String? semanticHint;

  /// Callback when the touch target is tapped.
  final VoidCallback? onTap;

  /// Creates an accessible touch target.
  const AccessibleTouchTarget({
    super.key,
    required this.child,
    this.minSize = kMinTouchTargetSize,
    this.semanticLabel,
    this.semanticHint,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget result = ConstrainedBox(
      constraints: BoxConstraints(
        minWidth: minSize,
        minHeight: minSize,
      ),
      child: Center(child: child),
    );

    if (onTap != null) {
      result = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(minSize / 2),
        child: result,
      );
    }

    if (semanticLabel != null) {
      result = Semantics(
        label: semanticLabel,
        hint: semanticHint,
        button: onTap != null,
        child: result,
      );
    }

    return result;
  }
}

/// An accessible icon button with proper touch target sizing.
class AccessibleIconButton extends StatelessWidget {
  /// The icon to display.
  final IconData icon;

  /// The size of the icon.
  final double iconSize;

  /// Callback when the button is pressed.
  final VoidCallback? onPressed;

  /// Semantic label for the button.
  final String semanticLabel;

  /// Semantic hint for the button.
  final String? semanticHint;

  /// Background color of the button.
  final Color? backgroundColor;

  /// Color of the icon.
  final Color? iconColor;

  /// Creates an accessible icon button.
  const AccessibleIconButton({
    super.key,
    required this.icon,
    required this.semanticLabel,
    this.iconSize = 24.0,
    this.onPressed,
    this.semanticHint,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      hint: semanticHint,
      button: true,
      enabled: onPressed != null,
      child: Material(
        color: backgroundColor ?? Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: kMinTouchTargetSize,
              minHeight: kMinTouchTargetSize,
            ),
            child: Center(
              child: Icon(
                icon,
                size: iconSize,
                color: iconColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A live region that announces changes to screen readers.
///
/// Use this to announce navigation updates, arrival events,
/// and other important state changes.
class LiveRegion extends StatelessWidget {
  /// The content to display and announce.
  final Widget child;

  /// The text to announce to screen readers.
  final String announcement;

  /// Whether this is a polite or assertive announcement.
  ///
  /// Assertive announcements interrupt current speech.
  /// Polite announcements wait for current speech to finish.
  final bool assertive;

  /// Creates a live region.
  const LiveRegion({
    super.key,
    required this.child,
    required this.announcement,
    this.assertive = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      liveRegion: true,
      label: announcement,
      child: child,
    );
  }
}

// =============================================================================
// UTILITY FUNCTIONS
// =============================================================================

/// Announces a message to screen readers.
///
/// Use this for important navigation events like:
/// - Arrival at waypoint
/// - Route recalculation
/// - Turn instructions
void announceToScreenReader(String message, {TextDirection? textDirection}) {
  SemanticsService.announce(
    message,
    textDirection ?? TextDirection.ltr,
  );
}

/// Creates a semantic container for marker information.
Widget semanticMarkerContainer({
  required Widget child,
  required String markerTitle,
  String? markerCategory,
  String? markerDescription,
}) {
  final label = StringBuffer(markerTitle);
  if (markerCategory != null && markerCategory.isNotEmpty) {
    label.write('. Category: $markerCategory');
  }
  if (markerDescription != null && markerDescription.isNotEmpty) {
    label.write('. $markerDescription');
  }

  return Semantics(
    label: label.toString(),
    container: true,
    child: child,
  );
}

/// Extension to add accessibility helpers to widgets.
extension AccessibilityExtensions on Widget {
  /// Wraps this widget with a semantic label.
  Widget withSemanticLabel(String label, {String? hint}) {
    return Semantics(
      label: label,
      hint: hint,
      child: this,
    );
  }

  /// Wraps this widget as a semantic button.
  Widget asSemanticButton(String label, {String? hint, bool enabled = true}) {
    return Semantics(
      label: label,
      hint: hint,
      button: true,
      enabled: enabled,
      child: this,
    );
  }

  /// Wraps this widget as a live region for announcements.
  Widget asLiveRegion(String announcement) {
    return Semantics(
      liveRegion: true,
      label: announcement,
      child: this,
    );
  }
}

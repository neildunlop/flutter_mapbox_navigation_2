/// Result of waypoint validation operations
class WaypointValidationResult {
  /// Whether the waypoint configuration is valid
  final bool isValid;

  /// List of warnings about the waypoint configuration
  final List<String> warnings;

  /// List of recommendations for improving the waypoint configuration
  final List<String> recommendations;

  /// Creates a new [WaypointValidationResult]
  const WaypointValidationResult({
    required this.isValid,
    required this.warnings,
    required this.recommendations,
  });

  /// Creates a valid result with no warnings or recommendations
  factory WaypointValidationResult.valid() {
    return const WaypointValidationResult(
      isValid: true,
      warnings: [],
      recommendations: [],
    );
  }

  /// Creates an invalid result with the given warnings and recommendations
  factory WaypointValidationResult.invalid({
    required List<String> warnings,
    required List<String> recommendations,
  }) {
    return WaypointValidationResult(
      isValid: false,
      warnings: warnings,
      recommendations: recommendations,
    );
  }

  /// Whether there are any warnings
  bool get hasWarnings => warnings.isNotEmpty;

  /// Whether there are any recommendations
  bool get hasRecommendations => recommendations.isNotEmpty;

  /// Returns a formatted string representation of the validation result
  String get formattedMessage {
    final buffer = StringBuffer();
    
    if (!isValid) {
      buffer.writeln('❌ Waypoint validation failed:');
    } else if (hasWarnings) {
      buffer.writeln('⚠️  Waypoint validation warnings:');
    } else {
      buffer.writeln('✅ Waypoint validation passed');
    }
    
    if (hasWarnings) {
      for (final warning in warnings) {
        buffer.writeln('  • $warning');
      }
    }
    
    if (hasRecommendations) {
      buffer.writeln('\n💡 Recommendations:');
      for (final recommendation in recommendations) {
        buffer.writeln('  • $recommendation');
      }
    }
    
    return buffer.toString().trim();
  }

  @override
  String toString() {
    return 'WaypointValidationResult(isValid: $isValid, warnings: $warnings, recommendations: $recommendations)';
  }
} 
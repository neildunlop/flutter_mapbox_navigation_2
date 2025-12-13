/// Status Bar Widget
///
/// Displays navigation status information including distance remaining,
/// duration remaining, current instruction, and navigation state.

import 'package:flutter/material.dart';
import '../../core/constants.dart';

class StatusBar extends StatelessWidget {
  /// Whether navigation is currently active
  final bool isNavigating;

  /// Whether a route has been built
  final bool routeBuilt;

  /// Distance remaining in meters
  final double? distanceRemaining;

  /// Duration remaining in seconds
  final double? durationRemaining;

  /// Current turn instruction
  final String? currentInstruction;

  /// Current navigation event type
  final String? lastEventType;

  const StatusBar({
    super.key,
    this.isNavigating = false,
    this.routeBuilt = false,
    this.distanceRemaining,
    this.durationRemaining,
    this.currentInstruction,
    this.lastEventType,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status row
            Row(
              children: [
                _StatusIndicator(
                  label: 'Route',
                  isActive: routeBuilt,
                  activeColor: Colors.blue,
                ),
                const SizedBox(width: 16),
                _StatusIndicator(
                  label: 'Navigating',
                  isActive: isNavigating,
                  activeColor: Colors.green,
                ),
                const Spacer(),
                if (lastEventType != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      lastEventType!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
              ],
            ),

            if (routeBuilt || isNavigating) ...[
              const Divider(height: 24),

              // Distance and duration
              Row(
                children: [
                  Expanded(
                    child: _MetricDisplay(
                      icon: Icons.straighten,
                      label: 'Distance',
                      value: _formatDistance(distanceRemaining),
                    ),
                  ),
                  Expanded(
                    child: _MetricDisplay(
                      icon: Icons.timer,
                      label: 'Duration',
                      value: _formatDuration(durationRemaining),
                    ),
                  ),
                ],
              ),

              // Current instruction
              if (currentInstruction != null &&
                  currentInstruction!.isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.navigation,
                        color: Colors.blue.shade700,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentInstruction!,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Colors.blue.shade700,
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  String _formatDistance(double? meters) {
    if (meters == null) return '--';
    if (meters < 1000) {
      return '${meters.toStringAsFixed(0)} m';
    } else {
      return '${(meters / 1000).toStringAsFixed(1)} km';
    }
  }

  String _formatDuration(double? seconds) {
    if (seconds == null) return '--';
    final duration = Duration(seconds: seconds.toInt());
    if (duration.inHours > 0) {
      return '${duration.inHours}h ${duration.inMinutes.remainder(60)}m';
    } else if (duration.inMinutes > 0) {
      return '${duration.inMinutes}m ${duration.inSeconds.remainder(60)}s';
    } else {
      return '${duration.inSeconds}s';
    }
  }
}

class _StatusIndicator extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color activeColor;

  const _StatusIndicator({
    required this.label,
    required this.isActive,
    required this.activeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? activeColor : Colors.grey.shade300,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isActive ? activeColor : Colors.grey,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
        ),
      ],
    );
  }
}

class _MetricDisplay extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _MetricDisplay({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.grey.shade600),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey.shade600,
                  ),
            ),
            Text(
              value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      ],
    );
  }
}

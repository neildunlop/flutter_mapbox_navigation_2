/// Event Log Widget
///
/// Displays a scrolling list of navigation events in real-time.
/// Useful for debugging and demonstrating the event system.

import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../../core/constants.dart';

/// A single log entry
class EventLogEntry {
  final DateTime timestamp;
  final MapBoxEvent eventType;
  final String? details;

  EventLogEntry({
    required this.eventType,
    this.details,
  }) : timestamp = DateTime.now();

  String get formattedTime {
    return '${timestamp.hour.toString().padLeft(2, '0')}:'
        '${timestamp.minute.toString().padLeft(2, '0')}:'
        '${timestamp.second.toString().padLeft(2, '0')}';
  }
}

/// Widget to display event logs
class EventLogWidget extends StatelessWidget {
  /// List of log entries to display
  final List<EventLogEntry> entries;

  /// Maximum height for the log container
  final double maxHeight;

  /// Callback when clear is pressed
  final VoidCallback? onClear;

  const EventLogWidget({
    super.key,
    required this.entries,
    this.maxHeight = 200,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(UIConstants.smallPadding),
            child: Row(
              children: [
                const Icon(Icons.list_alt, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Event Log',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                Text(
                  '${entries.length} events',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (onClear != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.clear_all, size: 20),
                    onPressed: onClear,
                    tooltip: 'Clear log',
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1),

          // Log entries
          Container(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: entries.isEmpty
                ? const Padding(
                    padding: EdgeInsets.all(UIConstants.defaultPadding),
                    child: Center(
                      child: Text(
                        'No events yet. Start navigation to see events.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    reverse: true, // Show newest at top
                    itemCount: entries.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final entry = entries[entries.length - 1 - index];
                      return _EventLogItem(entry: entry);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _EventLogItem extends StatelessWidget {
  final EventLogEntry entry;

  const _EventLogItem({required this.entry});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: UIConstants.smallPadding,
        vertical: 6,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timestamp
          SizedBox(
            width: 65,
            child: Text(
              entry.formattedTime,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontFamily: 'monospace',
                    color: Colors.grey.shade600,
                  ),
            ),
          ),

          // Event indicator
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4, right: 8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getEventColor(entry.eventType),
            ),
          ),

          // Event type and details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.eventType.toString().split('.').last,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getEventColor(entry.eventType),
                      ),
                ),
                if (entry.details != null && entry.details!.isNotEmpty)
                  Text(
                    entry.details!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getEventColor(MapBoxEvent event) {
    switch (event) {
      case MapBoxEvent.route_built:
        return Colors.green;
      case MapBoxEvent.route_building:
        return Colors.blue;
      case MapBoxEvent.route_build_failed:
      case MapBoxEvent.route_build_no_routes_found:
        return Colors.red;
      case MapBoxEvent.navigation_running:
        return Colors.green;
      case MapBoxEvent.navigation_finished:
        return Colors.teal;
      case MapBoxEvent.navigation_cancelled:
        return Colors.orange;
      case MapBoxEvent.progress_change:
        return Colors.blue;
      case MapBoxEvent.on_arrival:
        return Colors.purple;
      case MapBoxEvent.user_off_route:
        return Colors.orange;
      case MapBoxEvent.milestone_event:
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }
}

/// Extension to convert RouteEvent to EventLogEntry
extension RouteEventToLogEntry on RouteEvent {
  EventLogEntry toLogEntry() {
    String? details;
    final event = eventType ?? MapBoxEvent.progress_change;

    if (event == MapBoxEvent.progress_change && data is RouteProgressEvent) {
      final progress = data as RouteProgressEvent;
      final distKm = (progress.distance ?? 0) / 1000;
      final durMin = ((progress.duration ?? 0) / 60).round();
      details = '${distKm.toStringAsFixed(1)} km remaining, ~$durMin min';
    } else if (event == MapBoxEvent.on_arrival) {
      details = 'Arrived at waypoint';
    } else if (data != null && data.toString().isNotEmpty) {
      final dataStr = data.toString();
      if (dataStr.length > 100) {
        details = '${dataStr.substring(0, 100)}...';
      } else {
        details = dataStr;
      }
    }

    return EventLogEntry(
      eventType: event,
      details: details,
    );
  }
}

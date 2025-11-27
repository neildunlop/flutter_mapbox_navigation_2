import 'package:flutter/material.dart';
import 'static_marker.dart';

/// Builder function for creating custom marker popup widgets.
///
/// This allows developers to provide their own popup UI when a marker is tapped
/// during navigation.
///
/// Parameters:
/// - [context] The build context
/// - [marker] The marker that was tapped
/// - [onClose] Callback to close/dismiss the popup
///
/// Example usage:
/// ```dart
/// MarkerPopupBuilder myCustomPopup = (context, marker, onClose) {
///   return Card(
///     child: ListTile(
///       title: Text(marker.title),
///       subtitle: Text(marker.description ?? ''),
///       trailing: IconButton(
///         icon: Icon(Icons.close),
///         onPressed: onClose,
///       ),
///     ),
///   );
/// };
/// ```
typedef MarkerPopupBuilder = Widget Function(
  BuildContext context,
  StaticMarker marker,
  VoidCallback onClose,
);

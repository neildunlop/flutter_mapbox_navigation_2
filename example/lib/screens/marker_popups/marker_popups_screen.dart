/// Marker Popups Screen
///
/// Demonstrates custom Flutter-based popup overlays for markers:
/// - Custom popupBuilder function
/// - Multiple popup styles
/// - Popup actions and interactions
/// - Positioning and animations

import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../../core/constants.dart';
import '../../data/sample_markers.dart';

class MarkerPopupsScreen extends StatefulWidget {
  const MarkerPopupsScreen({super.key});

  @override
  State<MarkerPopupsScreen> createState() => _MarkerPopupsScreenState();
}

class _MarkerPopupsScreenState extends State<MarkerPopupsScreen> {
  // ===========================================================================
  // STATE
  // ===========================================================================

  int _selectedPopupStyle = 0;
  StaticMarker? _activeMarker;

  final List<_PopupStyle> _popupStyles = [
    _PopupStyle(
      name: 'Simple',
      description: 'Basic card with title and description',
    ),
    _PopupStyle(
      name: 'Rich',
      description: 'Full details with metadata and actions',
    ),
    _PopupStyle(
      name: 'Compact',
      description: 'Minimal chip-style popup',
    ),
    _PopupStyle(
      name: 'Custom Themed',
      description: 'Custom colors matching marker category',
    ),
  ];

  // ===========================================================================
  // POPUP BUILDERS
  // ===========================================================================

  /// Simple popup - just title and description
  Widget _buildSimplePopup(
      BuildContext context, StaticMarker marker, VoidCallback onClose) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        width: 200,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    marker.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                InkWell(
                  onTap: onClose,
                  child: const Icon(Icons.close, size: 18),
                ),
              ],
            ),
            if (marker.description != null) ...[
              const SizedBox(height: 4),
              Text(
                marker.description!,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  /// Rich popup - full details with actions
  Widget _buildRichPopup(
      BuildContext context, StaticMarker marker, VoidCallback onClose) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 280,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: marker.customColor ?? Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.place, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        marker.title,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        marker.category.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          color: marker.customColor ?? Colors.blue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: onClose,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            // Description
            if (marker.description != null) ...[
              const SizedBox(height: 12),
              Text(
                marker.description!,
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],

            // Metadata
            if (marker.metadata != null && marker.metadata!.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: marker.metadata!.entries.take(4).map((entry) {
                  return _MetadataChip(
                    label: entry.key,
                    value: entry.value.toString(),
                  );
                }).toList(),
              ),
            ],

            // Actions
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      onClose();
                      _showMessage('Details for ${marker.title}');
                    },
                    icon: const Icon(Icons.info_outline, size: 18),
                    label: const Text('Details'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      onClose();
                      _showMessage('Navigating to ${marker.title}');
                    },
                    icon: const Icon(Icons.navigation, size: 18),
                    label: const Text('Go'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      backgroundColor: marker.customColor ?? Colors.blue,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Compact popup - minimal chip style
  Widget _buildCompactPopup(
      BuildContext context, StaticMarker marker, VoidCallback onClose) {
    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(20),
      color: Colors.white,
      child: InkWell(
        onTap: onClose,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: marker.customColor ?? Colors.blue,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.place, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              Text(
                marker.title,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
              const SizedBox(width: 4),
              const Icon(Icons.chevron_right, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  /// Custom themed popup - colors match marker category
  Widget _buildThemedPopup(
      BuildContext context, StaticMarker marker, VoidCallback onClose) {
    final color = marker.customColor ?? Colors.blue;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Colored header
          Container(
            width: 240,
            padding: const EdgeInsets.all(12),
            color: color,
            child: Row(
              children: [
                const Icon(Icons.place, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    marker.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                InkWell(
                  onTap: onClose,
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ],
            ),
          ),
          // Content
          Container(
            width: 240,
            padding: const EdgeInsets.all(12),
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  marker.category.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (marker.description != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    marker.description!,
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade700,
                    ),
                  ),
                ],
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      onClose();
                      _showMessage('Navigate to ${marker.title}');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: const Text('Navigate Here'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPopup(
      BuildContext context, StaticMarker marker, VoidCallback onClose) {
    switch (_selectedPopupStyle) {
      case 0:
        return _buildSimplePopup(context, marker, onClose);
      case 1:
        return _buildRichPopup(context, marker, onClose);
      case 2:
        return _buildCompactPopup(context, marker, onClose);
      case 3:
        return _buildThemedPopup(context, marker, onClose);
      default:
        return _buildSimplePopup(context, marker, onClose);
    }
  }

  // ===========================================================================
  // UI HELPERS
  // ===========================================================================

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _testPopup(StaticMarker marker) {
    setState(() => _activeMarker = marker);
  }

  void _closePopup() {
    setState(() => _activeMarker = null);
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marker Popups'),
      ),
      body: Stack(
        children: [
          ListView(
            padding: const EdgeInsets.all(UIConstants.defaultPadding),
            children: [
              // Description
              _buildDescriptionCard(),
              const SizedBox(height: 16),

              // Style selector
              _buildStyleSelector(),
              const SizedBox(height: 16),

              // Test markers
              _buildTestMarkersCard(),
              const SizedBox(height: 16),

              // Code example
              _buildCodeExample(),
            ],
          ),

          // Popup overlay
          if (_activeMarker != null)
            Positioned.fill(
              child: GestureDetector(
                onTap: _closePopup,
                child: Container(
                  color: Colors.black26,
                  child: Center(
                    child: GestureDetector(
                      onTap: () {}, // Prevent closing when tapping popup
                      child: _buildPopup(context, _activeMarker!, _closePopup),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard() {
    return Card(
      color: Colors.purple.shade50,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.chat_bubble, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                Text(
                  'Custom Popups',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.purple.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Marker popups are fully customizable Flutter widgets. '
              'Use the popupBuilder parameter to create your own design.',
              style: TextStyle(color: Colors.purple.shade900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStyleSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Popup Style',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            ...List.generate(_popupStyles.length, (index) {
              final style = _popupStyles[index];
              return RadioListTile<int>(
                value: index,
                groupValue: _selectedPopupStyle,
                onChanged: (value) =>
                    setState(() => _selectedPopupStyle = value!),
                title: Text(style.name),
                subtitle: Text(style.description),
                contentPadding: EdgeInsets.zero,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildTestMarkersCard() {
    final testMarkers = [
      SampleMarkers.restaurants.first,
      SampleMarkers.gasStations.first,
      SampleMarkers.scenicViewpoints.first,
      SampleMarkers.hotels.first,
    ];

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Test Popups',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap a marker to see the popup style:',
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: testMarkers.map((marker) {
                return ActionChip(
                  avatar: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: marker.customColor ?? Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child:
                        const Icon(Icons.place, color: Colors.white, size: 14),
                  ),
                  label: Text(marker.title),
                  onPressed: () => _testPopup(marker),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeExample() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Code Example',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const SelectableText(
                '''MarkerConfiguration(
  popupBuilder: (context, marker, onClose) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(marker.title),
            Text(marker.description ?? ''),
            ElevatedButton(
              onPressed: onClose,
              child: Text('Close'),
            ),
          ],
        ),
      ),
    );
  },
)''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PopupStyle {
  final String name;
  final String description;

  _PopupStyle({required this.name, required this.description});
}

class _MetadataChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Accessibility Screen
///
/// Demonstrates accessibility features and best practices:
/// - Semantic labels for navigation elements
/// - Accessible touch targets
/// - Screen reader announcements
/// - High contrast patterns

import 'package:flutter/material.dart';
import '../../core/constants.dart';

class AccessibilityScreen extends StatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  State<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends State<AccessibilityScreen> {
  // ===========================================================================
  // STATE
  // ===========================================================================

  bool _highContrast = false;
  bool _largeText = false;
  double _touchTargetSize = 48.0;

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Accessibility'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        children: [
          // Overview
          _buildOverviewCard(),
          const SizedBox(height: 16),

          // Semantic labels
          _buildSemanticLabelsCard(),
          const SizedBox(height: 16),

          // Touch targets
          _buildTouchTargetsCard(),
          const SizedBox(height: 16),

          // Screen reader demo
          _buildScreenReaderCard(),
          const SizedBox(height: 16),

          // Best practices
          _buildBestPracticesCard(),
          const SizedBox(height: 16),

          // Code examples
          _buildCodeExamplesCard(),
        ],
      ),
    );
  }

  Widget _buildOverviewCard() {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.accessibility_new, color: Colors.blue.shade700),
                const SizedBox(width: 8),
                Text(
                  'Accessibility Support',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.blue.shade700,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'The flutter_mapbox_navigation plugin includes accessibility features '
              'to ensure your navigation app works well with assistive technologies.',
              style: TextStyle(color: Colors.blue.shade900),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSemanticLabelsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.label, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Semantic Labels',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'Standard navigation labels for screen readers:',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),

            _buildLabelExample('Navigation map', 'Map view element'),
            _buildLabelExample('Start navigation', 'Begin route button'),
            _buildLabelExample('Stop navigation', 'End route button'),
            _buildLabelExample('Skip to next waypoint', 'Skip button'),
            _buildLabelExample('Return to previous waypoint', 'Previous button'),
            _buildLabelExample('Remaining distance', 'Distance display'),
            _buildLabelExample('Estimated time of arrival', 'ETA display'),
            _buildLabelExample('Current instruction', 'Turn instruction'),
          ],
        ),
      ),
    );
  }

  Widget _buildLabelExample(String label, String description) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          Icon(Icons.record_voice_over, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '"$label"',
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
          Text(
            description,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTouchTargetsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.touch_app, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Touch Targets',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'Minimum touch target size: ${UIConstants.minTouchTargetSize}dp',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                const Text('Target size: '),
                Expanded(
                  child: Slider(
                    value: _touchTargetSize,
                    min: 32,
                    max: 64,
                    divisions: 8,
                    label: '${_touchTargetSize.toInt()}dp',
                    onChanged: (value) =>
                        setState(() => _touchTargetSize = value),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Demo buttons
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildTouchTargetDemo(_touchTargetSize, 'Skip'),
                  const SizedBox(width: 16),
                  _buildTouchTargetDemo(_touchTargetSize, 'Next'),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _touchTargetSize >= 48
                    ? Colors.green.shade50
                    : Colors.red.shade50,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: [
                  Icon(
                    _touchTargetSize >= 48
                        ? Icons.check_circle
                        : Icons.warning,
                    size: 16,
                    color: _touchTargetSize >= 48 ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _touchTargetSize >= 48
                        ? 'Meets minimum size (48dp)'
                        : 'Below minimum (48dp recommended)',
                    style: TextStyle(
                      fontSize: 12,
                      color: _touchTargetSize >= 48
                          ? Colors.green.shade800
                          : Colors.red.shade800,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTouchTargetDemo(double size, String label) {
    return Semantics(
      button: true,
      label: label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Icon(
            label == 'Skip' ? Icons.skip_previous : Icons.skip_next,
            color: Colors.white,
            size: size * 0.5,
          ),
        ),
      ),
    );
  }

  Widget _buildScreenReaderCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.speaker_notes, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Screen Reader Support',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Text(
              'Navigation announcements are automatically read by screen readers:',
              style: TextStyle(color: Colors.grey.shade700),
            ),
            const SizedBox(height: 8),

            _buildAnnouncementDemo(
              'Turn left in 500 meters',
              Icons.turn_left,
            ),
            _buildAnnouncementDemo(
              'Arrived at destination',
              Icons.flag,
            ),
            _buildAnnouncementDemo(
              'Route recalculating',
              Icons.refresh,
            ),
            _buildAnnouncementDemo(
              'Waypoint 2 of 5',
              Icons.location_on,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnnouncementDemo(String text, IconData icon) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.indigo.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.indigo.shade100),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.indigo.shade700, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: Colors.indigo.shade900),
            ),
          ),
          Icon(Icons.volume_up, color: Colors.indigo.shade400, size: 18),
        ],
      ),
    );
  }

  Widget _buildBestPracticesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.star, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Best Practices',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildPractice(
              'Use semantic labels',
              'Add meaningful labels to all interactive elements',
              Icons.label_outline,
            ),
            _buildPractice(
              'Minimum touch targets',
              'Ensure buttons are at least 48x48dp',
              Icons.touch_app,
            ),
            _buildPractice(
              'Color contrast',
              'Use sufficient contrast ratios (4.5:1 minimum)',
              Icons.contrast,
            ),
            _buildPractice(
              'Focus indicators',
              'Make focused elements clearly visible',
              Icons.center_focus_strong,
            ),
            _buildPractice(
              'Live regions',
              'Announce dynamic content changes',
              Icons.campaign,
            ),
            _buildPractice(
              'Logical order',
              'Ensure reading order makes sense',
              Icons.format_list_numbered,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPractice(String title, String description, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Colors.green.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeExamplesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Code Examples',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),

            _buildCodeSection(
              'Semantic Button',
              '''Semantics(
  button: true,
  label: 'Start navigation to destination',
  child: ElevatedButton(
    onPressed: _startNavigation,
    child: Text('Navigate'),
  ),
)''',
            ),

            const SizedBox(height: 12),

            _buildCodeSection(
              'Touch Target Wrapper',
              '''SizedBox(
  width: 48,  // Minimum 48dp
  height: 48,
  child: IconButton(
    icon: Icon(Icons.skip_next),
    onPressed: _skipWaypoint,
  ),
)''',
            ),

            const SizedBox(height: 12),

            _buildCodeSection(
              'Live Region Announcement',
              '''// Announce to screen reader
SemanticsService.announce(
  'Arrived at waypoint 2 of 5',
  TextDirection.ltr,
);''',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCodeSection(String title, String code) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(4),
          ),
          child: SelectableText(
            code,
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

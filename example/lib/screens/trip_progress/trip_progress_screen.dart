/// Trip Progress Screen
///
/// Demonstrates the customizable trip progress panel:
/// - TripProgressConfig configuration
/// - TripProgressTheme customization
/// - Builder pattern APIs
/// - Skip buttons, progress bar, ETA display

import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../../core/constants.dart';
import '../../data/sample_waypoints.dart';

class TripProgressScreen extends StatefulWidget {
  const TripProgressScreen({super.key});

  @override
  State<TripProgressScreen> createState() => _TripProgressScreenState();
}

class _TripProgressScreenState extends State<TripProgressScreen> {
  // ===========================================================================
  // STATE
  // ===========================================================================

  final _navigation = MapBoxNavigation.instance;

  // Config options
  bool _showSkipButtons = true;
  bool _showProgressBar = true;
  bool _showEta = true;
  bool _showTotalDistance = true;
  bool _showEndButton = true;
  bool _showWaypointCount = true;
  bool _showDistanceToNext = true;
  bool _showDurationToNext = true;
  bool _showCurrentSpeed = true;
  bool _enableAudioFeedback = true;

  // Theme options
  int _selectedTheme = 0; // 0 = light, 1 = dark, 2 = custom
  Color _primaryColor = const Color(0xFF4264FB);
  Color _accentColor = const Color(0xFF28A745);
  Color _backgroundColor = Colors.white;
  double _cornerRadius = 16.0;

  // Preview state
  int _previewWaypointIndex = 2;
  final int _totalWaypoints = 5;

  // ===========================================================================
  // CONFIG BUILDING
  // ===========================================================================

  TripProgressConfig _buildConfig() {
    return TripProgressConfig(
      showSkipButtons: _showSkipButtons,
      showProgressBar: _showProgressBar,
      showEta: _showEta,
      showTotalDistance: _showTotalDistance,
      showEndNavigationButton: _showEndButton,
      showWaypointCount: _showWaypointCount,
      showDistanceToNext: _showDistanceToNext,
      showDurationToNext: _showDurationToNext,
      showCurrentSpeed: _showCurrentSpeed,
      enableAudioFeedback: _enableAudioFeedback,
      theme: _buildTheme(),
    );
  }

  TripProgressTheme _buildTheme() {
    switch (_selectedTheme) {
      case 0:
        return TripProgressTheme.light();
      case 1:
        return TripProgressTheme.dark();
      case 2:
        return TripProgressTheme(
          primaryColor: _primaryColor,
          accentColor: _accentColor,
          backgroundColor: _backgroundColor,
          textPrimaryColor: Colors.black87,
          textSecondaryColor: Colors.grey.shade600,
          buttonBackgroundColor: Colors.grey.shade200,
          endButtonColor: Colors.red,
          progressBarColor: _primaryColor,
          progressBarBackgroundColor: Colors.grey.shade200,
          cornerRadius: _cornerRadius,
          buttonSize: 44.0,
          iconSize: 24.0,
        );
      default:
        return TripProgressTheme.light();
    }
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  Future<void> _startNavigationWithConfig() async {
    final waypoints = SampleWaypoints.dcMonumentsTour;
    final config = _buildConfig();

    final options = MapBoxOptions(
      initialLatitude: waypoints.first.latitude,
      initialLongitude: waypoints.first.longitude,
      zoom: 15.0,
      voiceInstructionsEnabled: true,
      bannerInstructionsEnabled: true,
      units: VoiceUnits.metric,
      mode: MapBoxNavigationMode.driving,
      simulateRoute: true,
      tripProgressConfig: config,
    );

    try {
      await _navigation.startNavigation(
        wayPoints: waypoints,
        options: options,
      );
    } catch (e) {
      _showError('Failed to start navigation: $e');
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Trip Progress Panel'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        children: [
          // Preview
          _buildPreview(),
          const SizedBox(height: 24),

          // Display options
          _buildDisplayOptions(),
          const SizedBox(height: 16),

          // Theme options
          _buildThemeOptions(),
          const SizedBox(height: 16),

          // Custom colors (when custom theme selected)
          if (_selectedTheme == 2) ...[
            _buildCustomThemeOptions(),
            const SizedBox(height: 16),
          ],

          // Start button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _startNavigationWithConfig,
              icon: const Icon(Icons.navigation),
              label: const Text('Test with Multi-Stop Route'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: _primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Code example
          _buildCodeExample(),
        ],
      ),
    );
  }

  Widget _buildPreview() {
    final theme = _buildTheme();

    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(UIConstants.defaultPadding),
            child: Text(
              'Preview',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // Simulated panel
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.backgroundColor,
              borderRadius: BorderRadius.circular(theme.cornerRadius ?? 16.0),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                // Waypoint count
                if (_showWaypointCount)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Waypoint $_previewWaypointIndex of $_totalWaypoints',
                      style: TextStyle(
                        color: theme.textSecondaryColor,
                        fontSize: 12,
                      ),
                    ),
                  ),

                // Progress bar
                if (_showProgressBar)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _previewWaypointIndex / _totalWaypoints,
                        backgroundColor: theme.progressBarBackgroundColor,
                        valueColor: AlwaysStoppedAnimation(theme.progressBarColor),
                        minHeight: 6,
                      ),
                    ),
                  ),

                // Main content row
                Row(
                  children: [
                    // Previous button
                    if (_showSkipButtons)
                      Container(
                        width: theme.buttonSize,
                        height: theme.buttonSize,
                        decoration: BoxDecoration(
                          color: theme.buttonBackgroundColor,
                          borderRadius:
                              BorderRadius.circular((theme.cornerRadius ?? 16.0) / 2),
                        ),
                        child: Icon(
                          Icons.skip_previous,
                          color: theme.primaryColor,
                          size: theme.iconSize,
                        ),
                      ),

                    const SizedBox(width: 12),

                    // Center content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Lincoln Memorial',
                            style: TextStyle(
                              color: theme.textPrimaryColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              if (_showDistanceToNext)
                                Text(
                                  '2.4 km',
                                  style: TextStyle(
                                    color: theme.textSecondaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                              if (_showDistanceToNext && _showDurationToNext)
                                Text(
                                  ' • ',
                                  style: TextStyle(
                                    color: theme.textSecondaryColor,
                                  ),
                                ),
                              if (_showDurationToNext)
                                Text(
                                  '8 min',
                                  style: TextStyle(
                                    color: theme.textSecondaryColor,
                                    fontSize: 13,
                                  ),
                                ),
                            ],
                          ),
                          if (_showEta || _showTotalDistance) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (_showEta)
                                  Text(
                                    'ETA: 3:45 PM',
                                    style: TextStyle(
                                      color: theme.accentColor,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                if (_showEta && _showTotalDistance)
                                  Text(
                                    ' • ',
                                    style: TextStyle(
                                      color: theme.textSecondaryColor,
                                    ),
                                  ),
                                if (_showTotalDistance)
                                  Text(
                                    'Total: 8.2 km',
                                    style: TextStyle(
                                      color: theme.textSecondaryColor,
                                      fontSize: 12,
                                    ),
                                  ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Next button
                    if (_showSkipButtons) ...[
                      const SizedBox(width: 12),
                      Container(
                        width: theme.buttonSize,
                        height: theme.buttonSize,
                        decoration: BoxDecoration(
                          color: theme.buttonBackgroundColor,
                          borderRadius:
                              BorderRadius.circular((theme.cornerRadius ?? 16.0) / 2),
                        ),
                        child: Icon(
                          Icons.skip_next,
                          color: theme.primaryColor,
                          size: theme.iconSize,
                        ),
                      ),
                    ],
                  ],
                ),

                // Current speed
                if (_showCurrentSpeed)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.speed,
                          size: 16,
                          color: theme.textSecondaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '45 km/h',
                          style: TextStyle(
                            color: theme.textSecondaryColor,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),

                // End navigation button
                if (_showEndButton) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {},
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.endButtonColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular((theme.cornerRadius ?? 16.0) / 2),
                        ),
                      ),
                      child: const Text('End Navigation'),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Waypoint slider
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Text('Waypoint:'),
                Expanded(
                  child: Slider(
                    value: _previewWaypointIndex.toDouble(),
                    min: 1,
                    max: _totalWaypoints.toDouble(),
                    divisions: _totalWaypoints - 1,
                    label: '$_previewWaypointIndex',
                    onChanged: (value) =>
                        setState(() => _previewWaypointIndex = value.toInt()),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDisplayOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Display Options',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                _buildToggleChip('Skip Buttons', _showSkipButtons,
                    (v) => setState(() => _showSkipButtons = v)),
                _buildToggleChip('Progress Bar', _showProgressBar,
                    (v) => setState(() => _showProgressBar = v)),
                _buildToggleChip(
                    'ETA', _showEta, (v) => setState(() => _showEta = v)),
                _buildToggleChip('Total Distance', _showTotalDistance,
                    (v) => setState(() => _showTotalDistance = v)),
                _buildToggleChip('End Button', _showEndButton,
                    (v) => setState(() => _showEndButton = v)),
                _buildToggleChip('Waypoint Count', _showWaypointCount,
                    (v) => setState(() => _showWaypointCount = v)),
                _buildToggleChip('Distance to Next', _showDistanceToNext,
                    (v) => setState(() => _showDistanceToNext = v)),
                _buildToggleChip('Duration to Next', _showDurationToNext,
                    (v) => setState(() => _showDurationToNext = v)),
                _buildToggleChip('Current Speed', _showCurrentSpeed,
                    (v) => setState(() => _showCurrentSpeed = v)),
                _buildToggleChip('Audio Feedback', _enableAudioFeedback,
                    (v) => setState(() => _enableAudioFeedback = v)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleChip(
      String label, bool value, ValueChanged<bool> onChanged) {
    return FilterChip(
      label: Text(label),
      selected: value,
      onSelected: onChanged,
    );
  }

  Widget _buildThemeOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Theme',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                ChoiceChip(
                  label: const Text('Light'),
                  selected: _selectedTheme == 0,
                  onSelected: (s) => setState(() => _selectedTheme = 0),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Dark'),
                  selected: _selectedTheme == 1,
                  onSelected: (s) => setState(() => _selectedTheme = 1),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: const Text('Custom'),
                  selected: _selectedTheme == 2,
                  onSelected: (s) => setState(() => _selectedTheme = 2),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomThemeOptions() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom Theme',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 12),
            _buildColorPicker('Primary', _primaryColor, (c) {
              setState(() => _primaryColor = c);
            }),
            _buildColorPicker('Accent', _accentColor, (c) {
              setState(() => _accentColor = c);
            }),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('Corner Radius:'),
                Expanded(
                  child: Slider(
                    value: _cornerRadius,
                    min: 0,
                    max: 24,
                    divisions: 24,
                    label: '${_cornerRadius.toInt()}',
                    onChanged: (v) => setState(() => _cornerRadius = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildColorPicker(
      String label, Color currentColor, ValueChanged<Color> onChanged) {
    final colors = [
      Colors.blue,
      Colors.indigo,
      Colors.purple,
      Colors.pink,
      Colors.red,
      Colors.orange,
      Colors.amber,
      Colors.green,
      Colors.teal,
      Colors.cyan,
    ];

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 70,
            child: Text(label),
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: colors.map((color) {
                  final isSelected = color.value == currentColor.value;
                  return GestureDetector(
                    onTap: () => onChanged(color),
                    child: Container(
                      width: 32,
                      height: 32,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: Colors.black, width: 2)
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(Icons.check, color: Colors.white, size: 16)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
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
                '''final config = TripProgressConfig(
  showSkipButtons: true,
  showProgressBar: true,
  showEta: true,
  theme: TripProgressTheme(
    primaryColor: Colors.indigo,
    accentColor: Colors.amber,
    cornerRadius: 16.0,
  ),
);

final options = MapBoxOptions(
  tripProgressConfig: config,
  // ... other options
);''',
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

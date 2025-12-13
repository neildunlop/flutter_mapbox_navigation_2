/// Validation Screen
///
/// Demonstrates waypoint validation and error handling:
/// - WayPoint.validateWaypointCount()
/// - Error handling patterns
/// - Platform-specific validation
/// - Validation warnings and recommendations

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../../core/constants.dart';

class ValidationScreen extends StatefulWidget {
  const ValidationScreen({super.key});

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  // ===========================================================================
  // STATE
  // ===========================================================================

  // Test waypoints
  List<WayPoint> _waypoints = [];
  WaypointValidationResult? _validationResult;

  // Input fields
  final _nameController = TextEditingController(text: 'Test Location');
  final _latController = TextEditingController(text: '37.7749');
  final _lngController = TextEditingController(text: '-122.4194');

  // Options
  bool _isSilent = false;
  MapBoxNavigationMode _mode = MapBoxNavigationMode.drivingWithTraffic;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    // Start with 2 valid waypoints
    _waypoints = [
      WayPoint(
        name: 'Start',
        latitude: 37.7749,
        longitude: -122.4194,
      ),
      WayPoint(
        name: 'End',
        latitude: 37.8049,
        longitude: -122.4094,
      ),
    ];
    _validate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _latController.dispose();
    _lngController.dispose();
    super.dispose();
  }

  // ===========================================================================
  // VALIDATION
  // ===========================================================================

  void _validate() {
    final result = WayPoint.validateWaypointCount(_waypoints);
    setState(() => _validationResult = result);
  }

  void _addWaypoint() {
    final name = _nameController.text.trim();
    final lat = double.tryParse(_latController.text);
    final lng = double.tryParse(_lngController.text);

    // Validate inputs
    final errors = <String>[];

    if (name.isEmpty) {
      errors.add('Name cannot be empty');
    }

    if (lat == null || lat < -90 || lat > 90) {
      errors.add('Latitude must be between -90 and 90');
    }

    if (lng == null || lng < -180 || lng > 180) {
      errors.add('Longitude must be between -180 and 180');
    }

    // Check for silent waypoint restrictions
    if (_isSilent && _waypoints.isEmpty) {
      errors.add('First waypoint cannot be silent');
    }

    if (errors.isNotEmpty) {
      _showValidationErrors(errors);
      return;
    }

    // Add waypoint
    setState(() {
      _waypoints.add(WayPoint(
        name: name,
        latitude: lat!,
        longitude: lng!,
        isSilent: _isSilent,
      ));
    });

    // Re-validate
    _validate();

    // Reset form
    _nameController.text = 'Location ${_waypoints.length + 1}';
    _isSilent = false;
  }

  void _removeWaypoint(int index) {
    setState(() => _waypoints.removeAt(index));
    _validate();
  }

  void _showValidationErrors(List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.error, color: Colors.red),
            SizedBox(width: 8),
            Text('Validation Error'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: errors.map((e) => Text('• $e')).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // BUILD
  // ===========================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Waypoint Validation'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        children: [
          // Validation result
          _buildValidationResultCard(),
          const SizedBox(height: 16),

          // Waypoint list
          _buildWaypointListCard(),
          const SizedBox(height: 16),

          // Add waypoint form
          _buildAddWaypointCard(),
          const SizedBox(height: 16),

          // Mode selection
          _buildModeCard(),
          const SizedBox(height: 16),

          // Validation rules
          _buildValidationRulesCard(),
        ],
      ),
    );
  }

  Widget _buildValidationResultCard() {
    final result = _validationResult;
    final isValid = result?.isValid ?? false;
    final color = isValid ? Colors.green : Colors.red;

    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isValid ? Icons.check_circle : Icons.error,
                  color: color,
                ),
                const SizedBox(width: 8),
                Text(
                  isValid ? 'Valid' : 'Invalid',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_waypoints.length} waypoints',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),

            // Warnings
            if (result != null && result.warnings.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              const Text(
                'Warnings:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...result.warnings.map((w) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 16,
                          color: Colors.orange.shade700,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            w,
                            style: TextStyle(color: Colors.orange.shade900),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],

            // Recommendations
            if (result != null && result.recommendations.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text(
                'Recommendations:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...result.recommendations.map((r) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.lightbulb_outline,
                          size: 16,
                          color: Colors.blue.shade700,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            r,
                            style: TextStyle(color: Colors.blue.shade900),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWaypointListCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.route, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Waypoints',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (_waypoints.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: Text(
                  'No waypoints added',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              ...List.generate(_waypoints.length, (index) {
                final wp = _waypoints[index];
                final isFirst = index == 0;
                final isLast = index == _waypoints.length - 1;

                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: isFirst
                              ? Colors.green
                              : isLast
                                  ? Colors.red
                                  : (wp.isSilent ?? false)
                                      ? Colors.orange
                                      : Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    wp.name,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w500),
                                  ),
                                ),
                                if (wp.isSilent ?? false)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 6,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      'Silent',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            Text(
                              '${wp.latitude?.toStringAsFixed(4)}, '
                              '${wp.longitude?.toStringAsFixed(4)}',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline,
                            color: Colors.red, size: 20),
                        onPressed: () => _removeWaypoint(index),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildAddWaypointCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.add_location, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Add Waypoint',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _latController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Latitude',
                      border: OutlineInputBorder(),
                      hintText: '-90 to 90',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _lngController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Longitude',
                      border: OutlineInputBorder(),
                      hintText: '-180 to 180',
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            SwitchListTile(
              title: const Text('Silent Waypoint'),
              subtitle: const Text('No announcement at this stop'),
              value: _isSilent,
              onChanged: (value) => setState(() => _isSilent = value),
              contentPadding: EdgeInsets.zero,
            ),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _addWaypoint,
                icon: const Icon(Icons.add),
                label: const Text('Add Waypoint'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.directions, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Navigation Mode',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: MapBoxNavigationMode.values.map((mode) {
                return ChoiceChip(
                  label: Text(mode.toString().split('.').last),
                  selected: _mode == mode,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _mode = mode);
                      _validate();
                    }
                  },
                );
              }).toList(),
            ),

            if (Platform.isIOS && _mode == MapBoxNavigationMode.drivingWithTraffic)
              Container(
                margin: const EdgeInsets.only(top: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline,
                        size: 16, color: Colors.orange.shade700),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'iOS: drivingWithTraffic mode limited to 3 waypoints',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange.shade800,
                        ),
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

  Widget _buildValidationRulesCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.rule, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Validation Rules',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            _buildRule('Minimum 2 waypoints required', true),
            _buildRule('Name cannot be empty', true),
            _buildRule('Latitude: -90 to 90', true),
            _buildRule('Longitude: -180 to 180', true),
            _buildRule('First/last waypoints cannot be silent', true),
            _buildRule('No duplicate coordinates', true),
            _buildRule('Recommended max: 25 waypoints', false),
            _buildRule('iOS traffic mode: max 3 waypoints', Platform.isIOS),
          ],
        ),
      ),
    );
  }

  Widget _buildRule(String text, bool isRequired) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isRequired ? Icons.error_outline : Icons.lightbulb_outline,
            size: 16,
            color: isRequired ? Colors.red : Colors.blue,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: isRequired ? Colors.red.shade900 : Colors.blue.shade900,
              ),
            ),
          ),
          Text(
            isRequired ? 'Required' : 'Warning',
            style: TextStyle(
              fontSize: 10,
              color: isRequired ? Colors.red : Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}

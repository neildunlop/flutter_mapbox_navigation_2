/// Marker Gallery Screen
///
/// Displays all available marker icons organized by category.
/// Useful reference for developers choosing marker icons.

import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../../core/constants.dart';

class MarkerGalleryScreen extends StatelessWidget {
  const MarkerGalleryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final iconsByCategory = MarkerIcons.getIconsByCategory();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Marker Icons'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        itemCount: iconsByCategory.length,
        itemBuilder: (context, index) {
          final category = iconsByCategory.keys.elementAt(index);
          final icons = iconsByCategory[category]!;

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(category).withOpacity(0.1),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _getCategoryIcon(category),
                        color: _getCategoryColor(category),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        category,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: _getCategoryColor(category),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${icons.length} icons',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Icons grid
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: icons.map((iconId) {
                      return _IconTile(
                        iconId: iconId,
                        color: _getCategoryColor(category),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category.toLowerCase()) {
      case 'transportation':
        return Colors.blue;
      case 'food & services':
        return Colors.orange;
      case 'scenic & recreation':
        return Colors.green;
      case 'safety & traffic':
        return Colors.red;
      case 'general':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'transportation':
        return Icons.directions_car;
      case 'food & services':
        return Icons.restaurant;
      case 'scenic & recreation':
        return Icons.landscape;
      case 'safety & traffic':
        return Icons.warning;
      case 'general':
        return Icons.place;
      default:
        return Icons.category;
    }
  }
}

class _IconTile extends StatelessWidget {
  final String iconId;
  final Color color;

  const _IconTile({
    required this.iconId,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _showIconDetails(context),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 100,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade200),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _getIconData(iconId),
                color: Colors.white,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              iconId,
              style: const TextStyle(fontSize: 10),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _showIconDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(iconId),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _getIconData(iconId),
                  color: Colors.white,
                  size: 48,
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Usage:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: SelectableText(
                "iconId: MarkerIcons.$iconId",
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  IconData _getIconData(String iconId) {
    // Map icon IDs to Material icons for display
    switch (iconId) {
      case 'petrolStation':
        return Icons.local_gas_station;
      case 'chargingStation':
        return Icons.ev_station;
      case 'parking':
        return Icons.local_parking;
      case 'busStop':
        return Icons.directions_bus;
      case 'trainStation':
        return Icons.train;
      case 'airport':
        return Icons.flight;
      case 'port':
        return Icons.directions_boat;
      case 'restaurant':
        return Icons.restaurant;
      case 'cafe':
        return Icons.local_cafe;
      case 'hotel':
        return Icons.hotel;
      case 'shop':
        return Icons.shopping_bag;
      case 'pharmacy':
        return Icons.local_pharmacy;
      case 'hospital':
        return Icons.local_hospital;
      case 'police':
        return Icons.local_police;
      case 'fireStation':
        return Icons.fire_truck;
      case 'scenic':
        return Icons.photo_camera;
      case 'park':
        return Icons.park;
      case 'beach':
        return Icons.beach_access;
      case 'mountain':
        return Icons.terrain;
      case 'lake':
        return Icons.water;
      case 'waterfall':
        return Icons.water_drop;
      case 'viewpoint':
        return Icons.visibility;
      case 'hiking':
        return Icons.hiking;
      case 'speedCamera':
        return Icons.speed;
      case 'accident':
        return Icons.car_crash;
      case 'construction':
        return Icons.construction;
      case 'trafficLight':
        return Icons.traffic;
      case 'speedBump':
        return Icons.warning;
      case 'schoolZone':
        return Icons.school;
      case 'pin':
        return Icons.place;
      case 'star':
        return Icons.star;
      case 'heart':
        return Icons.favorite;
      case 'flag':
        return Icons.flag;
      case 'warning':
        return Icons.warning_amber;
      case 'info':
        return Icons.info;
      case 'question':
        return Icons.help;
      default:
        return Icons.place;
    }
  }
}

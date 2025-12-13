/// Offline Screen
///
/// Demonstrates offline navigation features:
/// - downloadOfflineRegion() with progress
/// - listOfflineRegions() management
/// - isOfflineRoutingAvailable() checks
/// - Storage management
///
/// Note: Offline routing backend implementation status may vary.

import 'package:flutter/material.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';
import '../../core/constants.dart';

class OfflineScreen extends StatefulWidget {
  const OfflineScreen({super.key});

  @override
  State<OfflineScreen> createState() => _OfflineScreenState();
}

class _OfflineScreenState extends State<OfflineScreen> {
  // ===========================================================================
  // STATE
  // ===========================================================================

  final _navigation = MapBoxNavigation.instance;

  // Download state
  bool _isDownloading = false;
  double _downloadProgress = 0.0;
  String? _downloadError;

  // Region info
  List<Map<String, dynamic>> _regions = [];
  int _cacheSize = 0;

  // Selected region for download
  _RegionPreset _selectedRegion = _RegionPreset.sanFrancisco;

  // ===========================================================================
  // LIFECYCLE
  // ===========================================================================

  @override
  void initState() {
    super.initState();
    _loadRegionInfo();
  }

  Future<void> _loadRegionInfo() async {
    try {
      final cacheSize = await _navigation.getOfflineCacheSize();
      final regionsResult = await _navigation.listOfflineRegions();

      setState(() {
        _cacheSize = cacheSize;
        if (regionsResult != null && regionsResult['regions'] != null) {
          _regions = List<Map<String, dynamic>>.from(regionsResult['regions']);
        }
      });
    } catch (e) {
      // Offline features may not be fully implemented
      debugPrint('Failed to load region info: $e');
    }
  }

  // ===========================================================================
  // ACTIONS
  // ===========================================================================

  Future<void> _downloadRegion() async {
    setState(() {
      _isDownloading = true;
      _downloadProgress = 0.0;
      _downloadError = null;
    });

    try {
      final result = await _navigation.downloadOfflineRegion(
        southWestLat: _selectedRegion.southWestLat,
        southWestLng: _selectedRegion.southWestLng,
        northEastLat: _selectedRegion.northEastLat,
        northEastLng: _selectedRegion.northEastLng,
        minZoom: 10,
        maxZoom: 16,
        includeRoutingTiles: true,
        onProgress: (progress) {
          if (mounted) {
            setState(() => _downloadProgress = progress);
          }
        },
      );

      if (result != null && result['success'] == true) {
        _showMessage('Region downloaded successfully');
        _loadRegionInfo();
      } else {
        setState(() => _downloadError = 'Download failed');
      }
    } catch (e) {
      setState(() => _downloadError = e.toString());
    } finally {
      if (mounted) {
        setState(() => _isDownloading = false);
      }
    }
  }

  Future<void> _checkAvailability() async {
    try {
      final isAvailable = await _navigation.isOfflineRoutingAvailable(
        latitude: _selectedRegion.centerLat,
        longitude: _selectedRegion.centerLng,
      );

      _showMessage(isAvailable
          ? 'Offline routing available for this location'
          : 'Offline routing NOT available');
    } catch (e) {
      _showError('Failed to check availability: $e');
    }
  }

  Future<void> _clearCache() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear Cache?'),
        content: const Text(
          'This will delete all offline map data. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Clear'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _navigation.clearOfflineCache();
        _showMessage('Cache cleared');
        _loadRegionInfo();
      } catch (e) {
        _showError('Failed to clear cache: $e');
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
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
        title: const Text('Offline Navigation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadRegionInfo,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        children: [
          // Info banner
          _buildInfoBanner(),
          const SizedBox(height: 16),

          // Storage info
          _buildStorageCard(),
          const SizedBox(height: 16),

          // Download region
          _buildDownloadCard(),
          const SizedBox(height: 16),

          // Downloaded regions
          _buildRegionsCard(),
          const SizedBox(height: 16),

          // Code example
          _buildCodeExample(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Experimental Feature',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange.shade800,
                    ),
                  ),
                  Text(
                    'Offline navigation requires downloading map tiles and routing '
                    'data. Backend implementation status may vary.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.orange.shade900,
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

  Widget _buildStorageCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.storage, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Storage',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Cache Size'),
                      Text(
                        _formatBytes(_cacheSize),
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _cacheSize > 0 ? _clearCache : null,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDownloadCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_download, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Download Region',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Region selector
            DropdownButtonFormField<_RegionPreset>(
              value: _selectedRegion,
              decoration: const InputDecoration(
                labelText: 'Select Region',
                border: OutlineInputBorder(),
              ),
              items: _RegionPreset.values.map((region) {
                return DropdownMenuItem(
                  value: region,
                  child: Text(region.name),
                );
              }).toList(),
              onChanged: _isDownloading
                  ? null
                  : (value) {
                      if (value != null) {
                        setState(() => _selectedRegion = value);
                      }
                    },
            ),

            const SizedBox(height: 12),

            // Region info
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bounds: ${_selectedRegion.southWestLat.toStringAsFixed(2)}, '
                    '${_selectedRegion.southWestLng.toStringAsFixed(2)} to '
                    '${_selectedRegion.northEastLat.toStringAsFixed(2)}, '
                    '${_selectedRegion.northEastLng.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12),
                  ),
                  Text(
                    'Est. size: ${_selectedRegion.estimatedSize}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Progress indicator
            if (_isDownloading) ...[
              LinearProgressIndicator(value: _downloadProgress),
              const SizedBox(height: 8),
              Text(
                'Downloading: ${(_downloadProgress * 100).toStringAsFixed(0)}%',
                style: const TextStyle(fontSize: 12),
              ),
            ],

            // Error message
            if (_downloadError != null) ...[
              const SizedBox(height: 8),
              Text(
                _downloadError!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],

            const SizedBox(height: 12),

            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _isDownloading ? null : _checkAvailability,
                    icon: const Icon(Icons.check_circle_outline),
                    label: const Text('Check'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _isDownloading ? null : _downloadRegion,
                    icon: const Icon(Icons.download),
                    label: const Text('Download'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegionsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(UIConstants.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.map, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Downloaded Regions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_regions.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                alignment: Alignment.center,
                child: Text(
                  'No regions downloaded',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              )
            else
              ...List.generate(_regions.length, (index) {
                final region = _regions[index];
                return ListTile(
                  leading: const Icon(Icons.map_outlined),
                  title: Text(region['regionId'] ?? 'Region $index'),
                  subtitle: Text(
                    'Complete: ${region['isComplete'] ?? 'Unknown'}',
                  ),
                  contentPadding: EdgeInsets.zero,
                );
              }),
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
                '''// Download a region
final result = await MapBoxNavigation.instance
    .downloadOfflineRegion(
  southWestLat: 37.0,
  southWestLng: -122.5,
  northEastLat: 38.0,
  northEastLng: -121.5,
  minZoom: 10,
  maxZoom: 16,
  includeRoutingTiles: true,
  onProgress: (progress) {
    print('Download: \${progress * 100}%');
  },
);

// Check availability
final available = await MapBoxNavigation.instance
    .isOfflineRoutingAvailable(37.7749, -122.4194);

// List regions
final regions = await MapBoxNavigation.instance
    .listOfflineRegions();

// Get cache size
final size = await MapBoxNavigation.instance
    .getOfflineCacheSize();''',
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 11,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}

enum _RegionPreset {
  sanFrancisco(
    name: 'San Francisco Bay Area',
    southWestLat: 37.0,
    southWestLng: -122.5,
    northEastLat: 38.0,
    northEastLng: -121.5,
    estimatedSize: '~150 MB',
  ),
  washingtonDC(
    name: 'Washington D.C.',
    southWestLat: 38.8,
    southWestLng: -77.2,
    northEastLat: 39.0,
    northEastLng: -76.9,
    estimatedSize: '~80 MB',
  ),
  smallArea(
    name: 'Small Test Area',
    southWestLat: 37.7,
    southWestLng: -122.45,
    northEastLat: 37.8,
    northEastLng: -122.35,
    estimatedSize: '~20 MB',
  );

  final String name;
  final double southWestLat;
  final double southWestLng;
  final double northEastLat;
  final double northEastLng;
  final String estimatedSize;

  const _RegionPreset({
    required this.name,
    required this.southWestLat,
    required this.southWestLng,
    required this.northEastLat,
    required this.northEastLng,
    required this.estimatedSize,
  });

  double get centerLat => (southWestLat + northEastLat) / 2;
  double get centerLng => (southWestLng + northEastLng) / 2;
}

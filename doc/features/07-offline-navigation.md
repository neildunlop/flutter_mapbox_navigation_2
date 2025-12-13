# Feature Spec: Offline Navigation

## Overview

Offline Navigation enables downloading map tiles and routing data for specific geographic regions, allowing navigation without an internet connection. Users can pre-download areas and navigate offline.

**Priority:** P1 - Should Have
**Effort:** High
**Dependencies:** Turn-by-Turn Navigation (01)

## User Stories

1. **As a user**, I can download a region for offline use before traveling to an area with poor connectivity.
2. **As a user**, I can see download progress while regions are being downloaded.
3. **As a user**, I can navigate offline in areas I've downloaded.
4. **As a user**, I can see how much storage offline maps are using.
5. **As a user**, I can delete downloaded regions to free up space.
6. **As a developer**, I can check if offline routing is available for a location.

## Technical Approach

Offline navigation uses native Mapbox offline capabilities:
- **Map Tiles**: Downloaded via `TileStoreObserver`
- **Routing Tiles**: Downloaded for turn-by-turn offline navigation
- **Region Management**: Store and manage downloaded regions

### Data Types

| Type | Purpose | Size Estimate |
|------|---------|---------------|
| Map Tiles | Visual map display | ~50-200 MB per region |
| Routing Tiles | Turn-by-turn navigation | ~20-50 MB per region |

## API Reference

### Download a Region

```dart
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

final result = await MapBoxNavigation.instance.downloadOfflineRegion(
  // Bounding box coordinates
  southWestLat: 46.0,
  southWestLng: 6.0,
  northEastLat: 47.0,
  northEastLng: 7.0,
  // Zoom levels
  minZoom: 10,
  maxZoom: 16,
  // Include routing data for offline turn-by-turn
  includeRoutingTiles: true,
  // Progress callback
  onProgress: (progress) {
    print('Download: ${(progress * 100).toStringAsFixed(0)}%');
    setState(() => _downloadProgress = progress);
  },
);

if (result?['success'] == true) {
  print('Downloaded region: ${result!['regionId']}');
  print('Resources: ${result['resourceCount']}');
}
```

### Download Result

```dart
{
  'success': true,
  'regionId': 'region_46000_6000_47000_7000_nav',
  'resourceCount': 1250,
  'includesRoutingTiles': true,
}
```

### Check Offline Availability

```dart
final isAvailable = await MapBoxNavigation.instance.isOfflineRoutingAvailable(
  latitude: 46.5,
  longitude: 6.5,
);

if (isAvailable) {
  print('Offline routing available for this location');
} else {
  print('Download region first for offline navigation');
}
```

### List Downloaded Regions

```dart
final result = await MapBoxNavigation.instance.listOfflineRegions();

if (result != null) {
  final regions = result['regions'] as List;
  print('Total regions: ${result['totalCount']}');
  print('Total size: ${(result['totalSizeBytes'] / 1024 / 1024).toStringAsFixed(1)} MB');

  for (final region in regions) {
    print('Region: ${region['regionId']}');
    print('  Map tiles: ${region['mapTilesReady']}');
    print('  Routing tiles: ${region['routingTilesReady']}');
    print('  Size: ${(region['estimatedSizeBytes'] / 1024 / 1024).toStringAsFixed(1)} MB');
  }
}
```

### Get Region Status

```dart
final status = await MapBoxNavigation.instance.getOfflineRegionStatus(
  regionId: 'region_46000_6000_47000_7000_nav',
);

if (status != null) {
  print('Region exists: ${status['exists']}');
  print('Map tiles ready: ${status['mapTilesReady']}');
  print('Routing tiles ready: ${status['routingTilesReady']}');
  print('Complete: ${status['isComplete']}');
}
```

### Get Cache Size

```dart
final sizeBytes = await MapBoxNavigation.instance.getOfflineCacheSize();
final sizeMB = sizeBytes / (1024 * 1024);
print('Offline cache: ${sizeMB.toStringAsFixed(1)} MB');
```

### Delete a Region

```dart
await MapBoxNavigation.instance.deleteOfflineRegion(
  southWestLat: 46.0,
  southWestLng: 6.0,
  northEastLat: 47.0,
  northEastLng: 7.0,
);
```

### Clear All Offline Data

```dart
final success = await MapBoxNavigation.instance.clearOfflineCache();
if (success == true) {
  print('All offline data cleared');
}
```

## Implementation Notes

### Region ID Format

Region IDs are generated based on coordinates:
```
region_{swLat*1000}_{swLng*1000}_{neLat*1000}_{neLng*1000}[_nav]
```

The `_nav` suffix indicates routing tiles are included.

### Zoom Level Considerations

| Zoom | Detail Level | Use Case |
|------|--------------|----------|
| 10 | Country | Overview |
| 12 | City | Urban navigation |
| 14 | Neighborhood | Detailed streets |
| 16 | Block | Maximum detail |

Higher zoom levels increase download size significantly.

### Download Best Practices

1. **Region Size**: Keep regions under 50km x 50km for reasonable download sizes
2. **Zoom Range**: Use 10-16 for navigation, 10-14 for overview only
3. **Connectivity**: Download on WiFi when possible
4. **Background**: Consider background download for large regions

## Test Cases

### Unit Tests

```dart
// test/unit/offline_navigation_test.dart

void main() {
  group('Offline Navigation', () {
    test('should validate bounding box coordinates', () {
      // Valid coordinates
      expect(46.0 >= -90 && 46.0 <= 90, isTrue);
      expect(6.0 >= -180 && 6.0 <= 180, isTrue);
    });

    test('should generate correct region ID', () {
      // Region ID format test
      final expectedId = 'region_46000_6000_47000_7000_nav';
      // Implementation generates this format
    });

    test('should calculate approximate download size', () {
      // Size estimation based on zoom levels and region size
    });
  });
}
```

### Integration Tests

```dart
// test/integration/offline_navigation_test.dart

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('should download and verify offline region', (tester) async {
    double progress = 0;

    // Download small test region
    final result = await MapBoxNavigation.instance.downloadOfflineRegion(
      southWestLat: 46.0,
      southWestLng: 6.0,
      northEastLat: 46.1,  // Small region for testing
      northEastLng: 6.1,
      minZoom: 10,
      maxZoom: 12,
      includeRoutingTiles: true,
      onProgress: (p) => progress = p,
    );

    expect(result?['success'], isTrue);
    expect(progress, equals(1.0));

    // Verify availability
    final isAvailable = await MapBoxNavigation.instance.isOfflineRoutingAvailable(
      latitude: 46.05,
      longitude: 6.05,
    );
    expect(isAvailable, isTrue);

    // Clean up
    await MapBoxNavigation.instance.deleteOfflineRegion(
      southWestLat: 46.0,
      southWestLng: 6.0,
      northEastLat: 46.1,
      northEastLng: 6.1,
    );
  });

  testWidgets('should list offline regions', (tester) async {
    final result = await MapBoxNavigation.instance.listOfflineRegions();

    expect(result, isNotNull);
    expect(result!['totalCount'], isA<int>());
    expect(result['totalSizeBytes'], isA<int>());
  });

  testWidgets('should report cache size', (tester) async {
    final size = await MapBoxNavigation.instance.getOfflineCacheSize();
    expect(size, isA<int>());
    expect(size, greaterThanOrEqualTo(0));
  });
}
```

### E2E Tests

```dart
// test/e2e/offline_navigation_test.dart

void main() {
  group('Offline Navigation E2E', () {
    testWidgets('complete offline navigation flow', (tester) async {
      // 1. Download a region
      // 2. Verify download complete
      // 3. Disable network (if possible in test)
      // 4. Start navigation within region
      // 5. Verify navigation works
      // 6. Delete region
    });

    testWidgets('progress callback accuracy', (tester) async {
      // 1. Start download
      // 2. Verify progress increases monotonically
      // 3. Verify progress reaches 1.0 on completion
    });

    testWidgets('handle download interruption', (tester) async {
      // 1. Start download
      // 2. Simulate interruption
      // 3. Resume or restart download
      // 4. Verify completion
    });

    testWidgets('storage management', (tester) async {
      // 1. Download multiple regions
      // 2. Check total cache size
      // 3. Delete one region
      // 4. Verify size decreased
      // 5. Clear all
      // 6. Verify cache is empty
    });
  });
}
```

## Acceptance Criteria

- [ ] Developer can download regions by bounding box
- [ ] Progress callback reports accurate download progress
- [ ] Routing tiles can be optionally included
- [ ] Developer can check if offline routing is available
- [ ] Developer can list all downloaded regions
- [ ] Developer can get status of specific region
- [ ] Developer can get total cache size
- [ ] Developer can delete specific regions
- [ ] Developer can clear all offline data
- [ ] Navigation works offline in downloaded regions
- [ ] Works on both iOS and Android
- [ ] Download survives app restart (for long downloads)

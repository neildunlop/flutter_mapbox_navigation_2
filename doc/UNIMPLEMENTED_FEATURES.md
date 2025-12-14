# Unimplemented Features

This document tracks features available in the native Mapbox SDKs that are not yet implemented in the Flutter wrapper.

## Not Implemented

### Map Features
- **Custom map layers** - Adding custom data layers to the map

### Location Features
- **Location history** - Recording and accessing navigation history
- **Location sharing** - Sharing current location with other users

### Advanced Navigation
- **Speed limits display** - Showing current speed limits on the map
- **Junction views** - Detailed junction images for complex intersections
- **EV routing** - Electric vehicle-specific routing with charging stops
- **Truck routing** - Commercial vehicle routing with height/weight restrictions
- **Incident reporting** - User-submitted traffic incident reports

### UI Features
- **Custom instruction views** - Fully customizable navigation instruction UI
- **Custom progress views** - Fully customizable route progress UI

## Partially Implemented

### Unit System (Metric/Imperial)
- **Status**: Works on Android, issues on iOS
- **Issue**: Voice instructions may not respect unit settings consistently

### Lane Guidance
- **Status**: Basic implementation
- **Missing**: Advanced lane change suggestions, complex intersection handling

### Map Camera Controls
- **Status**: Limited implementation
- **Missing**: Full programmatic camera control, custom camera animations

### Map Gestures
- **Status**: Basic implementation
- **Missing**: Custom gesture handling, gesture configuration options

### Location Events
- **Status**: Limited implementation
- **Missing**: Comprehensive location update callbacks, accuracy notifications

### Custom UI Components
- **Status**: Limited implementation
- **Missing**: Full widget customization for all navigation elements

## Platform-Specific Issues

### Android
- Full icon coverage (all 33 marker icons implemented as vector drawables)

### iOS
- Full icon coverage via SF Symbols
- Unit system setting may not apply to all voice instructions

## Priority Suggestions

### High Priority
1. Unit system fixes (especially iOS)
2. Lane guidance improvements
3. Map camera controls enhancement

### Medium Priority
1. Speed limits display
2. Junction views
3. Custom instruction views

### Low Priority
1. EV routing
2. Truck routing
3. Location history/sharing
4. Incident reporting
5. Custom map layers

## Contributing

When implementing a missing feature:
1. Update this document to move the feature to "Implemented"
2. Add tests for the new functionality
3. Update the feature_comparison.md matrix
4. Add documentation in the appropriate feature spec file

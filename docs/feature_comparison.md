# Mapbox Navigation SDK Features Comparison

This document compares the features available in the Mapbox Navigation SDKs with their implementation status in the Flutter wrapper.

## Core Navigation Features

| Feature | Android SDK | iOS SDK | Flutter Wrapper | Notes |
|---------|------------|---------|----------------|-------|
| Turn-by-turn navigation | ✅ | ✅ | ✅ | Basic navigation is implemented |
| Route calculation | ✅ | ✅ | ✅ | Via `startNavigation` and `buildRoute` |
| Alternative routes | ✅ | ✅ | ✅ | Via `alternatives` option |
| Rerouting | ✅ | ✅ | ✅ | Automatic rerouting when off-route |
| Voice instructions | ✅ | ✅ | ✅ | Via `voiceInstructionsEnabled` option |
| Banner instructions | ✅ | ✅ | ✅ | Via `bannerInstructionsEnabled` option |
| Free drive mode | ✅ | ✅ | ✅ | Via `startFreeDrive` method |
| Waypoints | ✅ | ✅ | ✅ | Via `addWayPoints` method |
| Unit system (imperial/metric) | ✅ | ✅ | ⚠️ | Partially implemented, issues on iOS |
| Language localization | ✅ | ✅ | ✅ | Via `language` option |

## Map Features

| Feature | Android SDK | iOS SDK | Flutter Wrapper | Notes |
|---------|------------|---------|----------------|-------|
| Custom map styles | ✅ | ✅ | ✅ | Via `mapStyleUrlDay` and `mapStyleUrlNight` |
| Map camera controls | ✅ | ✅ | ⚠️ | Limited implementation |
| Map gestures | ✅ | ✅ | ⚠️ | Basic implementation only |
| Map markers | ✅ | ✅ | ❌ | Not implemented |
| Map annotations | ✅ | ✅ | ❌ | Not implemented |
| Custom map layers | ✅ | ✅ | ❌ | Not implemented |

## Location Features

| Feature | Android SDK | iOS SDK | Flutter Wrapper | Notes |
|---------|------------|---------|----------------|-------|
| Location tracking | ✅ | ✅ | ✅ | Basic implementation |
| Location permissions | ✅ | ✅ | ✅ | Basic implementation |
| Location simulation | ✅ | ✅ | ✅ | Via `simulateRoute` option |
| Location history | ✅ | ✅ | ❌ | Not implemented |
| Location sharing | ✅ | ✅ | ❌ | Not implemented |

## Advanced Features

| Feature | Android SDK | iOS SDK | Flutter Wrapper | Notes |
|---------|------------|---------|----------------|-------|
| Offline routing | ✅ | ✅ | ❌ | Not implemented - API exists but native methods return errors |
| Traffic avoidance | ✅ | ✅ | ✅ | Via `mode` option |
| Incident reporting | ✅ | ✅ | ❌ | Not implemented |
| Speed limits | ✅ | ✅ | ❌ | Not implemented |
| Lane guidance | ✅ | ✅ | ⚠️ | Limited implementation |
| Junction views | ✅ | ✅ | ❌ | Not implemented |
| EV routing | ✅ | ✅ | ❌ | Not implemented |
| Truck routing | ✅ | ✅ | ❌ | Not implemented |
| Walking navigation | ✅ | ✅ | ✅ | Via `mode` option |
| Cycling navigation | ✅ | ✅ | ✅ | Via `mode` option |

## UI Features

| Feature | Android SDK | iOS SDK | Flutter Wrapper | Notes |
|---------|------------|---------|----------------|-------|
| Custom UI components | ✅ | ✅ | ⚠️ | Limited implementation |
| Custom navigation view | ✅ | ✅ | ✅ | Via embedded view |
| Custom instruction views | ✅ | ✅ | ❌ | Not implemented |
| Custom progress views | ✅ | ✅ | ❌ | Not implemented |
| Custom action buttons | ✅ | ✅ | ⚠️ | Limited implementation |
| Custom feedback UI | ✅ | ✅ | ⚠️ | Limited implementation |

## Event Handling

| Feature | Android SDK | iOS SDK | Flutter Wrapper | Notes |
|---------|------------|---------|----------------|-------|
| Navigation events | ✅ | ✅ | ✅ | Via event channel |
| Route progress events | ✅ | ✅ | ✅ | Via event channel |
| Location events | ✅ | ✅ | ⚠️ | Limited implementation |
| Map events | ✅ | ✅ | ⚠️ | Limited implementation |
| Gesture events | ✅ | ✅ | ⚠️ | Limited implementation |

## Legend
- ✅ Fully implemented
- ⚠️ Partially implemented or has issues
- ❌ Not implemented

## Implementation Priority Suggestions

### High Priority
1. Unit system fixes (especially for iOS)
2. Offline routing completion
3. Lane guidance improvements
4. Map camera controls enhancement
5. Custom UI components

### Medium Priority
1. Map markers and annotations
2. Location history
3. Speed limits
4. Junction views
5. Custom instruction views

### Low Priority
1. EV routing
2. Truck routing
3. Location sharing
4. Incident reporting
5. Custom map layers

## Notes
- This comparison is based on the current state of the Flutter wrapper and the latest Mapbox SDK documentation
- Some features might be partially implemented but not fully documented
- Platform-specific differences should be considered when implementing new features
- The priority list is subjective and should be adjusted based on your specific needs 
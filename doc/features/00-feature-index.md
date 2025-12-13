# Feature Index: Flutter Mapbox Navigation

This document provides an index of all features in the Flutter Mapbox Navigation plugin.

## Feature Status Legend

- **Implemented**: Feature is fully functional on both iOS and Android
- **Partial**: Feature works but has limitations or missing functionality
- **Planned**: Feature is planned but not yet implemented
- **Not Implemented**: Feature exists in native SDK but not exposed in plugin

## Core Navigation Features

| Feature | Status | Priority | Spec |
|---------|--------|----------|------|
| [Turn-by-Turn Navigation](./01-turn-by-turn-navigation.md) | Implemented | P0 | Complete |
| [Free Drive Mode](./02-free-drive-mode.md) | Implemented | P1 | Complete |
| [Multi-Stop Navigation](./03-multi-stop-navigation.md) | Implemented | P1 | Complete |
| [Embedded Navigation View](./04-embedded-navigation-view.md) | Implemented | P1 | Complete |

## Map Features

| Feature | Status | Priority | Spec |
|---------|--------|----------|------|
| [Static Markers](./05-static-markers.md) | Implemented | P1 | Complete |
| [Marker Popups](./06-marker-popups.md) | Implemented | P2 | Complete |
| Custom Map Styles | Implemented | P2 | Planned |
| Custom Map Layers | Not Implemented | P3 | - |

## Advanced Features

| Feature | Status | Priority | Spec |
|---------|--------|----------|------|
| [Offline Navigation](./07-offline-navigation.md) | Implemented | P1 | Complete |
| [Trip Progress Panel](./08-trip-progress-panel.md) | Implemented | P2 | Complete |
| [Event System](./09-event-system.md) | Implemented | P0 | Complete |
| [Waypoint Validation](./10-waypoint-validation.md) | Implemented | P1 | Complete |

## Voice & Language Features

| Feature | Status | Priority | Spec |
|---------|--------|----------|------|
| Voice Instructions | Implemented | P0 | Included in TBT Navigation |
| Banner Instructions | Implemented | P0 | Included in TBT Navigation |
| Language Localization | Implemented | P1 | Included in TBT Navigation |
| Unit System (Imperial/Metric) | Partial | P1 | Included in TBT Navigation |

## Platform Features

| Feature | Status | Priority | Spec |
|---------|--------|----------|------|
| [Accessibility Support](./11-accessibility.md) | Implemented | P1 | Complete |
| Android 13+ Security | Implemented | P1 | - |
| iOS Background Modes | Implemented | P1 | - |

## Future Features (Planned)

| Feature | Status | Priority | Notes |
|---------|--------|----------|-------|
| Vehicle Movement Simulation | Planned | P2 | Enhanced simulation |
| Speed Limits Display | Not Implemented | P3 | Available in native SDK |
| Lane Guidance | Partial | P3 | Basic implementation |
| Junction Views | Not Implemented | P3 | Available in native SDK |
| EV Routing | Not Implemented | P4 | Available in native SDK |
| Truck Routing | Not Implemented | P4 | Available in native SDK |
| Location History | Not Implemented | P3 | - |
| Incident Reporting | Not Implemented | P4 | - |

## Feature Dependencies

```
Turn-by-Turn Navigation (01)
    ├── Event System (09)
    ├── Voice Instructions
    ├── Banner Instructions
    ├── Unit System
    └── Waypoint Validation (10)

Embedded Navigation View (04)
    ├── Turn-by-Turn Navigation (01)
    ├── Static Markers (05)
    └── Marker Popups (06)

Multi-Stop Navigation (03)
    ├── Turn-by-Turn Navigation (01)
    ├── Waypoint Validation (10)
    └── Trip Progress Panel (08)

Offline Navigation (07)
    └── Turn-by-Turn Navigation (01)

Static Markers (05)
    ├── Marker Popups (06)
    └── Event System (09) - marker tap events
```

## Creating New Feature Specs

When adding a new feature specification:

1. Create a new file in `doc/features/` with format `XX-feature-name.md`
2. Follow the template structure from existing specs
3. Include all sections: Overview, User Stories, Technical Approach, Implementation, Tests, Acceptance Criteria
4. Update this index with the new feature

## Notes

- Feature specs are designed to support end-to-end testing
- Platform differences (iOS vs Android) should be documented in each spec

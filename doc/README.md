# Documentation Index

This folder contains documentation for the Flutter Mapbox Navigation plugin.

## Quick Start

- [Architecture Overview](./overview.md) - Plugin architecture and key components
- [Configuration Guide](./mapbox_overview.md) - MapBoxOptions configuration reference

## Feature Guides

- [Static Markers](./static_markers.md) - Custom POI markers on the map
- [Marker Popups](./popup_usage_guide.md) - Flutter popup overlay system

## Reference

- [Feature Comparison](./feature_comparison.md) - SDK features vs Flutter wrapper
- [Unimplemented Features](./UNIMPLEMENTED_FEATURES.md) - Features not yet implemented
- [Testing Guide](./testing.md) - Running and writing tests
- [Modernisation Notes](./modernisation.md) - Version history and migration notes

## Feature Specifications

Detailed specifications for each feature are in the `features/` folder:

| Feature | Description |
|---------|-------------|
| [Feature Index](./features/00-feature-index.md) | Master list of all features |
| [Turn-by-Turn Navigation](./features/01-turn-by-turn-navigation.md) | Core navigation feature |
| [Free Drive Mode](./features/02-free-drive-mode.md) | Passive navigation without destination |
| [Multi-Stop Navigation](./features/03-multi-stop-navigation.md) | Multiple waypoint routing |
| [Embedded Navigation View](./features/04-embedded-navigation-view.md) | Navigation within Flutter app |
| [Static Markers](./features/05-static-markers.md) | POI marker specification |
| [Marker Popups](./features/06-marker-popups.md) | Popup overlay specification |
| [Offline Navigation](./features/07-offline-navigation.md) | Offline map and routing |
| [Trip Progress Panel](./features/08-trip-progress-panel.md) | Waypoint progress UI |
| [Event System](./features/09-event-system.md) | Navigation events |
| [Waypoint Validation](./features/10-waypoint-validation.md) | Waypoint validation rules |
| [Accessibility](./features/11-accessibility.md) | Accessibility support |

## Standards

- [Quality Standards](./standards/FLUTTER_PLUGIN_QUALITY_STANDARDS.md) - Plugin quality guidelines

## External Resources

- [Mapbox Navigation SDK (Android)](https://docs.mapbox.com/android/navigation/overview/)
- [Mapbox Navigation SDK (iOS)](https://docs.mapbox.com/ios/navigation/overview/)
- [Flutter Platform Channels](https://docs.flutter.dev/platform-integration/platform-channels)

# Trip Progress UI - Implementation Notes

## Current State (November 2024)

We have implemented a **floating overlay** for trip progress that sits above the native Mapbox info panel. This works but is not integrated into the native navigation UI.

### What's Implemented
- `TripProgressOverlay` (Android & iOS) - Floating card showing:
  - Next waypoint/checkpoint name with category icon
  - Distance to next waypoint
  - Progress bar with "Stop X/Y"
  - Total time remaining
- `TripProgressManager` - Tracks waypoints and provides progress updates
- `TripProgressData` - Data model for progress information

### Files
**Android:**
- `utilities/TripProgressOverlay.kt`
- `utilities/TripProgressManager.kt`
- `models/TripProgressData.kt`

**iOS:**
- `Classes/TripProgressOverlay.swift`
- `Classes/TripProgressManager.swift`
- `Classes/TripProgressData.swift`

---

## Desired Improvement

User wants trip progress info **inside** the native bottom info panel, not floating above it.

---

## Mapbox Drop-in UI ViewBinders (Android SDK v2.x)

The Navigation SDK has these customization slots:

| Binder | Purpose |
|--------|---------|
| `infoPanelBinder` | Entire bottom info panel |
| `infoPanelHeaderBinder` | Header area of info panel |
| `infoPanelContentBinder` | Content area (we tried this - content was clipped) |
| `tripProgressBinder` | ETA/distance/time display - **most promising** |
| `speedLimitBinder` | Speed limit widget |
| `maneuverBinder` | Top instruction panel |
| `roadNameBinder` | Road name display |
| `actionButtonsBinder` | Action buttons |

### Options to Explore

1. **`tripProgressBinder`** - Replace default trip progress with custom view showing waypoint info + ETA/distance
2. **`infoPanelHeaderBinder`** - Add waypoint info at TOP of info panel
3. **Replace `infoPanelBinder`** - Full control but must recreate all functionality

---

## SDK Version Research (November 2024)

### Current Versions in This Project
- **Android**: `com.mapbox.navigation:ui-dropin:2.16.0` (v2.x)
- **iOS**: `MapboxNavigation ~> 2.11` (v2.x)

### SDK v3 Changes - CRITICAL FINDINGS

| Platform | Drop-in UI Status | ViewBinder Support | Migration Impact |
|----------|-------------------|-------------------|------------------|
| **Android** | **COMPLETELY REMOVED** | ❌ Gone | Must build custom UI |
| **iOS** | Still available | ✅ Yes | Library renamed only |

#### Android v3 Details
The `ui-dropin` module was **eliminated entirely** in Navigation SDK v3.

**What happened to the components:**
- UI widgets → `com.mapbox.navigationcore:ui-components`
- Data/logic → `tripdata` module
- ViewBinders → No longer exist

**v3 Approach**: Compose your own navigation UI using individual components from `ui-components`. The `tripdata` module provides `TripProgressComponent` and other data sources you can bind to custom views.

**Migration guide**: https://docs.mapbox.com/android/navigation/guides/migration-from-v2/

#### iOS v3 Details
Drop-in UI is **still available** in v3, just renamed.

**Changes:**
- Library: `MapboxNavigation` → `MapboxNavigationUIKit`
- ViewBinders: Still work the same way
- Customization: Same approach as v2

**Migration guide**: https://docs.mapbox.com/ios/navigation/v3/guides/migrate-to-v3-ui/

---

## Options Going Forward

### Option A: Stay on SDK v2 (Recommended for now)
- ✅ Both platforms have Drop-in UI with ViewBinders
- ✅ Can use `tripProgressBinder` to inject waypoint info into native panel
- ✅ Consistent approach across Android and iOS
- ⚠️ Eventually will need to migrate to v3

### Option B: Upgrade to SDK v3
- **Android**: Major rewrite - must build custom navigation UI from scratch
- **iOS**: Minor changes - rename imports, same customization approach
- ⚠️ Creates platform divergence - different architecture per platform
- ⚠️ Android would require significant development time

### Option C: Keep Floating Overlay (Current Implementation)
- ✅ Already working on both platforms
- ✅ Platform-independent approach
- ✅ Will work regardless of SDK version
- ⚠️ Not integrated into native info panel as user originally wanted

---

## Recommendation

**Short term**: Keep current floating overlay implementation (Option C) - it works and is platform-agnostic.

**If native integration is required**: Stay on SDK v2 (Option A) and use `tripProgressBinder` to customize the native trip progress area. This gives the cleanest result with consistent approach across platforms.

**Avoid**: Upgrading to SDK v3 until absolutely necessary, as it would require completely rebuilding Android navigation UI.

---

## Future Feature: Quick Skip Waypoints

User also wants ability for drivers to quickly skip waypoints when resuming a journey (without navigating through the app to uncheck visited waypoints).

Ideas:
- Tap on trip progress panel to show list of upcoming waypoints
- Swipe or tap to mark waypoints as "skipped"
- "Continue from here" button to recalculate route

---

## Next Steps

1. ~~Investigate SDK v3 architecture for UI customization~~ ✅ DONE - See findings above
2. **Decision needed**: Choose between Option A (stay on v2, use ViewBinders) or Option C (keep floating overlay)
3. If Option A chosen: Implement `tripProgressBinder` on Android to inject waypoint info into native panel
4. If Option A chosen: Implement equivalent on iOS using v2 ViewBinders
5. Consider hybrid: Keep floating overlay but try to make it look more integrated with native UI

# Flutter Mapbox Navigation - Architecture Notes

## 🎯 **Popup System Architecture**

### **Current Implementation:**
```
User Tap → _onMarkerTap() → MarkerPopupManager → MarkerPopupProvider → MarkerPopupOverlay → Visual Popup
```

### **Key Components:**

#### **1. MarkerPopupManager (Singleton)**
- **File:** `lib/src/managers/marker_popup_manager.dart`
- **Purpose:** Central state management for all popups
- **Key Methods:**
  - `showPopupForMarker(marker, screenPosition)`
  - `hidePopup()`
  - `reset()` - Reinitialize without disposal
- **Protection:** Prevents singleton disposal to avoid crashes

#### **2. MarkerPopupProvider (Widget)**
- **File:** `lib/src/managers/marker_popup_manager.dart` (lines 192-272)
- **Purpose:** Connects singleton to widget tree via ChangeNotifier
- **Lifecycle:** Listens to MarkerPopupManager, rebuilds on changes

#### **3. MarkerPopupOverlay (Visual Widget)**
- **File:** `lib/src/widgets/marker_popup_overlay.dart`
- **Purpose:** Renders actual popup UI with animations
- **Key Features:** Positioned overlay, animations, tap-outside-to-hide

#### **4. NavigationViewWithPopups (Integration)**
- **File:** `lib/src/widgets/navigation_view_with_popups.dart`
- **Purpose:** Wraps navigation view with popup functionality

## 🏗️ **Navigation Modes**

### **Embedded Navigation** ✅
- Uses `MapBoxNavigationViewWithPopups` widget
- Runs in existing Flutter screen
- **Popup Status:** Should work (needs debugging)

### **Full-Screen Navigation** ✅ 
- **NEW:** Flutter route (`example/lib/fullscreen_navigation.dart`)
- **OLD:** Native Android Activity (being phased out)
- Uses same widget as embedded → popups should work
- **Button:** "🎯 Start Flutter Full-Screen"

### **Native Full-Screen** (Legacy)
- Android `NavigationActivity.kt` 
- Uses `MarkerPopupBinder.kt` to send events to Flutter
- **Status:** Working but complex, being replaced by Flutter route

## 🔧 **Platform Integration**

### **Android Methods Added:**
```kotlin
// In FlutterMapboxNavigationPlugin.kt
getMarkerScreenPosition(lat, lng) -> {x, y}
getMapViewport() -> viewport data

// In StaticMarkerManager.kt  
getScreenPosition() -> coordinate conversion
getMapViewport() -> camera state
```

### **Event Flow for Native → Flutter:**
```
Android Marker Tap → MarkerPopupBinder → Flutter Event → 
_handleFullScreenMarkerTap() → MarkerPopupManager.showPopupForMarker()
```

## 📱 **Testing Approach**

### **Debug Flow:**
1. **Embedded View Test:** Use "Test Popup" button
2. **Full-Screen Test:** Use "🎯 Start Flutter Full-Screen" button  
3. **Legacy Test:** Use other navigation buttons (native)

### **Key Test Cases:**
- ✅ Marker tap in embedded navigation
- ✅ "Test Popup" button functionality
- 🔄 Marker tap in Flutter full-screen navigation
- 🔄 Visual popup rendering and animations
- 🔄 Navigation between different modes

## 🚨 **Known Issues & Fixes**

### **1. Singleton Disposal** ✅ FIXED
- **Issue:** "MarkerPopupManager was used after being disposed"
- **Fix:** Override dispose() to prevent actual disposal
- **Status:** No more crashes

### **2. Layout Crashes** ✅ FIXED  
- **Issue:** RenderBox layout errors in full-screen
- **Fix:** Added `SizedBox.expand()` and `SafeArea`
- **Status:** Stable full-screen navigation

### **3. Visual Popups Not Showing** ❌ CURRENT ISSUE
- **Issue:** Code executes but popups don't render
- **Debug:** Comprehensive logging added
- **Status:** Ready for debugging session

## 🎛️ **Configuration**

### **MarkerConfiguration Properties:**
```dart
MarkerConfiguration(
  popupBuilder: _buildMarkerPopup,           // Required for Flutter popups
  popupDuration: Duration(seconds: 6),      // Auto-hide timing
  popupOffset: Offset(0, -80),              // Position offset
  hidePopupOnTapOutside: true,              // Tap-to-hide
  onMarkerTap: _onMarkerTap,                // Callback
)
```

### **Example Popup Builder:**
```dart
Widget _buildMarkerPopup(StaticMarker marker, BuildContext context) {
  return Container(/* custom popup UI */);
}
```

## 📂 **File Structure**

### **Core Library Files:**
```
lib/src/
├── managers/
│   └── marker_popup_manager.dart          # Singleton + Provider
├── widgets/
│   ├── marker_popup_overlay.dart          # Visual popup rendering
│   └── navigation_view_with_popups.dart   # Integration wrapper
├── models/
│   └── marker_configuration.dart          # Configuration class
└── utilities/
    └── coordinate_converter.dart           # Lat/lng to screen conversion
```

### **Android Platform Files:**
```
android/src/main/kotlin/com/eopeter/fluttermapboxnavigation/
├── FlutterMapboxNavigationPlugin.kt       # Platform methods
├── StaticMarkerManager.kt                 # Coordinate conversion
└── utilities/MarkerPopupBinder.kt         # Native → Flutter events
```

### **Example App Files:**
```
example/lib/
├── app.dart                               # Main app with embedded nav
├── fullscreen_navigation.dart            # Flutter full-screen route
└── popup_example.dart                     # Advanced popup examples
```

---

**Next Session Goal:** Debug why popups aren't rendering visually despite code execution.
**Strategy:** Follow debug logs to identify break point in rendering pipeline.
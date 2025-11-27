# Getting Started with Flutter Mapbox Navigation Example

This example project demonstrates how to use the Flutter Mapbox Navigation plugin for manual testing and development.

## 🚀 Setting up the Example Project in Android Studio

### **Option 1: Quick Setup (Recommended)**

1. **Open in Android Studio:**
   - Open Android Studio
   - Click "Open" (not "Create New Project")
   - Navigate to: `/Users/neildunlop/Dev/flutter_mapbox_navigation_2/example`
   - Click "Open"

2. **Let Android Studio auto-configure:**
   - Android Studio will detect it's a Flutter project
   - It should automatically configure the Flutter SDK path
   - Wait for indexing to complete

### **Option 2: If you need to set up Mapbox tokens:**

3. **Configure Mapbox Access Token (Required for real functionality):**
   ```bash
   cd /Users/neildunlop/Dev/flutter_mapbox_navigation_2/example/android
   cp gradle.properties.template gradle.properties
   ```
   
   Then edit `gradle.properties` and replace `<YOUR TOKEN HERE>` with your actual Mapbox token.

4. **For iOS (if testing on iOS):**
   - You'll need to add your Mapbox token to iOS configuration as well
   - Check the main README for iOS setup instructions

### **Running the Example:**

5. **In Android Studio:**
   - Ensure you have a device/emulator running
   - Select the device from the device dropdown
   - Click the green "Run" button (▶️)
   - Or press `Shift + F10`

### **Alternative: Command Line (Faster)**
```bash
cd /Users/neildunlop/Dev/flutter_mapbox_navigation_2/example
flutter run
```

## 📱 What You'll See

The example app demonstrates:
- ✅ **Full Screen Navigation** - Complete turn-by-turn navigation
- ✅ **Embedded Navigation** - Navigation view within the app
- ✅ **Free Drive Mode** - Passive navigation
- ✅ **Static Markers** - Custom POI markers with tap events
- ✅ **Route Building** - Dynamic waypoint management
- ✅ **Unit Settings** - Metric/Imperial switching

## 🧪 Key Features to Test

- **Route Planning**: Set origin/destination points
- **Navigation Modes**: Try both full-screen and embedded views
- **Marker Interaction**: Tap on markers to see events
- **Voice Instructions**: Test audio guidance
- **Multi-stop Routes**: Add multiple waypoints

## 🔧 Troubleshooting

- **Build Issues**: Run `flutter clean && flutter pub get` in the example directory
- **Mapbox Errors**: Ensure your Mapbox token is valid and properly configured
- **Android Issues**: Check that you have the latest Android SDK tools

## 📋 Requirements

- Flutter SDK (>=2.19.4)
- Android Studio with Flutter plugin
- Valid Mapbox access token
- Android device/emulator or iOS simulator

## 🗂️ Project Structure

```
example/
├── lib/
│   ├── main.dart          # Entry point
│   └── app.dart           # Main app with navigation demos
├── android/               # Android-specific configuration
├── ios/                   # iOS-specific configuration
└── pubspec.yaml          # Dependencies
```

The example project is a comprehensive demonstration that shows off all the plugin's capabilities and is perfect for manual testing during development.
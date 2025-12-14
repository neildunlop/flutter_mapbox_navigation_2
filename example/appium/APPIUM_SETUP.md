# Appium MCP Setup for Flutter Mapbox Navigation

This guide explains how to set up Appium MCP for integration testing of full-screen navigation features.

## Prerequisites

1. **Node.js** (v18 or later)
2. **Appium** installed globally
3. **Android SDK** with platform-tools
4. **An Android device or emulator**

## Installation

### 1. Install Appium
```bash
npm install -g appium
appium driver install uiautomator2
```

### 2. Add Appium MCP to Claude Code
```bash
claude mcp add appium-mcp -- npx -y appium-mcp@latest
```

Or manually add to your MCP configuration:
```json
{
  "mcpServers": {
    "appium-mcp": {
      "disabled": false,
      "timeout": 100,
      "type": "stdio",
      "command": "npx",
      "args": ["appium-mcp@latest"],
      "env": {
        "ANDROID_HOME": "C:\\Users\\YourUsername\\AppData\\Local\\Android\\Sdk",
        "CAPABILITIES_CONFIG": "F:\\Dev\\adventure_platform\\adventure_platform_map_component\\flutter_mapbox_navigation\\example\\appium\\capabilities.json"
      }
    }
  }
}
```

### 3. Start Appium Server
```bash
appium
```

Default server runs on http://localhost:4723

### 4. Build the Example App
```bash
cd example
flutter build apk --debug
```

### 5. Grant Permissions (Optional but recommended)
```bash
adb shell pm grant com.eopeter.flutter_mapbox_navigation_example android.permission.ACCESS_FINE_LOCATION
adb shell pm grant com.eopeter.flutter_mapbox_navigation_example android.permission.ACCESS_COARSE_LOCATION
```

## Configuration

Edit `capabilities.json` to match your device:

### For Physical Device
1. Get your device UDID: `adb devices`
2. Update `appium:udid` in capabilities.json
3. Update `appium:platformVersion` to match your device

### For Emulator
1. Start your emulator
2. The default configuration should work

## Testing Full-Screen Navigation with Appium MCP

Once configured, you can use Claude Code with Appium MCP to:

1. **Launch the app and navigate to Basic Navigation**
2. **Tap "Start Navigation" button**
3. **Verify full-screen navigation UI elements appear**
4. **Test navigation controls (recenter, mute, exit)**
5. **Verify progress updates**
6. **Test arrival detection**

### Example Test Scenarios

#### Test 1: Basic Navigation Launch
- Tap "Basic Navigation" from home screen
- Wait for navigation view to load
- Verify navigation started (check for maneuver banner)
- Tap back button to exit
- Verify return to home screen

#### Test 2: Navigation Controls
- Start navigation
- Locate and tap the sound/mute button
- Verify voice state changed
- Locate and tap recenter button
- Verify camera recentered

#### Test 3: Free Drive Mode
- Tap "Free Drive" from home screen
- Verify map loads without destination
- Verify location marker visible
- Exit free drive mode

## Troubleshooting

### "Device not found"
- Ensure USB debugging is enabled
- Run `adb devices` to verify connection
- Restart adb: `adb kill-server && adb start-server`

### "App not installed"
- Rebuild the app: `flutter build apk --debug`
- Manually install: `adb install -r build/app/outputs/flutter-apk/app-debug.apk`

### "Permission denied"
- Pre-grant permissions using adb commands above
- Set `autoGrantPermissions: true` in capabilities

### "Session timeout"
- Increase `newCommandTimeout` in capabilities
- Ensure device is not locked

## Environment Variables

Set these environment variables for Appium:
```bash
# Windows
set ANDROID_HOME=C:\Users\YourUsername\AppData\Local\Android\Sdk
set PATH=%PATH%;%ANDROID_HOME%\platform-tools;%ANDROID_HOME%\tools

# Linux/Mac
export ANDROID_HOME=$HOME/Android/Sdk
export PATH=$PATH:$ANDROID_HOME/platform-tools:$ANDROID_HOME/tools
```

# Full-Screen Navigation Test Scenarios

These test scenarios are designed to be executed via Appium MCP with Claude Code.

## Pre-requisites
1. Appium server running (`appium`)
2. Android device/emulator connected (`adb devices`)
3. App built (`flutter build apk --debug`)
4. Permissions granted

---

## Test Suite 1: Basic Navigation Launch

### TC-1.1: Launch Navigation from Home Screen
**Steps:**
1. Launch the app
2. Wait for home screen to load
3. Find and tap "Basic Navigation" button
4. Wait for navigation to initialize

**Expected Results:**
- Navigation view loads
- Map displays route
- Navigation maneuver banner appears
- Voice instruction plays (if not muted)

### TC-1.2: Exit Navigation
**Steps:**
1. Complete TC-1.1 (navigation is active)
2. Find the exit/back button (arrow icon)
3. Tap the exit button
4. Wait for transition

**Expected Results:**
- Navigation stops
- Returns to home screen
- "Mapbox Navigation" title visible

---

## Test Suite 2: Navigation Controls

### TC-2.1: Toggle Voice Instructions
**Steps:**
1. Start navigation (TC-1.1)
2. Find the sound/mute button
3. Tap to toggle mute
4. Verify icon changes

**Expected Results:**
- Icon changes from speaker to muted speaker (or vice versa)
- Voice instructions should be muted/unmuted accordingly

### TC-2.2: Recenter Camera
**Steps:**
1. Start navigation
2. Pan/drag the map away from current position
3. Find and tap recenter button
4. Verify camera position

**Expected Results:**
- Camera returns to follow user location
- Map centers on current position with navigation bearing

### TC-2.3: Overview Route
**Steps:**
1. Start navigation
2. Find overview button
3. Tap overview
4. Verify map zoom changes

**Expected Results:**
- Map zooms out to show entire route
- Start and end markers visible

---

## Test Suite 3: Free Drive Mode

### TC-3.1: Launch Free Drive
**Steps:**
1. From home screen, tap "Free Drive"
2. Wait for map to load

**Expected Results:**
- Map loads without destination route
- Current location marker visible
- No navigation instructions shown

### TC-3.2: Exit Free Drive
**Steps:**
1. Complete TC-3.1
2. Tap back/exit button
3. Wait for transition

**Expected Results:**
- Returns to home screen
- No navigation active

---

## Test Suite 4: Embedded Navigation

### TC-4.1: Build Route in Embedded View
**Steps:**
1. From home screen, tap "Embedded Map"
2. Wait for map to load
3. Tap "Build Route" button
4. Wait for route to build

**Expected Results:**
- Map displays route line
- Button changes to "Clear"
- Route distance/time shown (if applicable)

### TC-4.2: Start Embedded Navigation
**Steps:**
1. Complete TC-4.1 (route built)
2. Tap "Start" button
3. Wait for navigation to begin

**Expected Results:**
- Navigation begins in embedded view
- Button changes to "Stop"
- Progress updates visible
- Simulated movement (if simulation enabled)

### TC-4.3: Stop Embedded Navigation
**Steps:**
1. Complete TC-4.2 (navigation active)
2. Tap "Stop" button
3. Verify navigation stops

**Expected Results:**
- Navigation stops
- Button returns to "Start"
- Route still displayed

### TC-4.4: Clear Route
**Steps:**
1. Have a route displayed
2. Tap "Clear" button
3. Verify route cleared

**Expected Results:**
- Route line removed from map
- Button returns to "Build Route"

---

## Test Suite 5: Multi-Stop Navigation

### TC-5.1: Load Multi-Stop Screen
**Steps:**
1. From home screen, scroll down
2. Tap "Multi-Stop Navigation"
3. Wait for screen to load

**Expected Results:**
- Multi-stop screen loads
- Waypoint list visible
- Map may show with markers

---

## Test Suite 6: Static Markers

### TC-6.1: Load Static Markers Screen
**Steps:**
1. From home screen, tap "Static Markers"
2. Wait for screen to load

**Expected Results:**
- Screen loads with map
- Category checkboxes visible (Restaurants, Gas Stations)

### TC-6.2: Add Markers
**Steps:**
1. Complete TC-6.1
2. Select one or more categories
3. Tap "Add Markers" button
4. Wait for markers to appear

**Expected Results:**
- Markers appear on map
- Markers correspond to selected categories

---

## Appium MCP Commands (Examples)

When using Appium MCP with Claude Code, you can use natural language commands like:

```
"Launch the app and wait for it to load"
"Tap the button that says 'Basic Navigation'"
"Find and take a screenshot"
"Check if there's an element with text 'Mapbox Navigation'"
"Tap the back button"
"Wait 5 seconds for the map to load"
"Find the element with the text 'Build Route' and tap it"
"Scroll down until you see 'Multi-Stop Navigation'"
```

## Element Identifiers

Common elements to look for:

| Element | Identifier |
|---------|------------|
| Home screen title | text="Mapbox Navigation" |
| Basic Navigation button | text="Basic Navigation" |
| Free Drive button | text="Free Drive" |
| Embedded Map button | text="Embedded Map" |
| Static Markers button | text="Static Markers" |
| Multi-Stop Navigation button | text="Multi-Stop Navigation" |
| Build Route button | text="Build Route" |
| Clear button | text="Clear" |
| Start button | text="Start" |
| Stop button | text="Stop" |
| Back button | contentDescription="Back" or class="android.widget.ImageButton" |

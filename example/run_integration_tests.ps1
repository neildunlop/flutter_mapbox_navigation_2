# PowerShell script to run integration tests with pre-granted permissions
# Usage: .\run_integration_tests.ps1

$ADB = "$env:LOCALAPPDATA\Android\Sdk\platform-tools\adb.exe"
$PACKAGE = "com.neiladunlop.fluttermapboxnavigation2example"

# Get the first online device
$device = & $ADB devices | Select-String "device$" | Select-Object -First 1
if ($device -match "^(\S+)") {
    $deviceId = $matches[1]
    Write-Host "Using device: $deviceId"
} else {
    Write-Host "No device found. Please connect a device or start an emulator."
    exit 1
}

# Build and install the app first
Write-Host "Building and installing app..."
flutter build apk --debug
& $ADB -s $deviceId install -r build\app\outputs\flutter-apk\app-debug.apk

# Grant location permissions
Write-Host "Granting location permissions..."
& $ADB -s $deviceId shell pm grant $PACKAGE android.permission.ACCESS_FINE_LOCATION
& $ADB -s $deviceId shell pm grant $PACKAGE android.permission.ACCESS_COARSE_LOCATION
& $ADB -s $deviceId shell pm grant $PACKAGE android.permission.ACCESS_BACKGROUND_LOCATION 2>$null

Write-Host "Running integration tests..."
flutter test integration_test/all_tests.dart -d $deviceId

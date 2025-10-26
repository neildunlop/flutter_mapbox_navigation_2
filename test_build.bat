@echo off
cd example
echo "Testing Flutter popup system compilation..."
flutter clean
flutter pub get
flutter build apk --debug
echo "Build completed!"
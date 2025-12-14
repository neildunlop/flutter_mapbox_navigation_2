# Testing Guide

This document covers the testing strategy, architecture, and practical guide for running tests in the Flutter Mapbox Navigation plugin.

## Test Structure

```
test/
├── unit/           # Unit tests - business logic, models, validation
├── widget/         # Widget tests - UI components
├── integration/    # Integration tests - platform communication
└── golden/         # Golden tests - visual regression
```

## Running Tests

### All Tests
```bash
flutter test
```

### Specific Test Types
```bash
# Unit tests only
flutter test test/unit/

# Widget tests only
flutter test test/widget/

# Integration tests only
flutter test test/integration/

# Single test file
flutter test test/unit/waypoint_test.dart
```

### With Coverage
```bash
# Generate coverage report
flutter test --coverage

# Generate HTML report (requires lcov)
genhtml coverage/lcov.info -o coverage/html

# View report
start coverage/html/index.html    # Windows
open coverage/html/index.html     # macOS
```

## Test Architecture

### What We Test

1. **Flutter Object Creation**
   - Correct instantiation of `WayPoint`, `StaticMarker`, and other models
   - Validation of required fields and parameter combinations

2. **Message Serialization**
   - Correct JSON formatting for platform channel messages
   - Proper handling of different data types

3. **Method Channel Communication**
   - Verification that correct methods are called
   - Proper parameter passing and response handling

### What We Don't Test

1. **Native Platform Code** - Tested separately in platform-specific tests
2. **Mapbox SDK Integration** - Tested via device/emulator integration tests
3. **Real Navigation** - Requires physical device testing

### Architecture Flow

```
Flutter App Layer
    ├── Flutter Code → MapBoxNavigation → Method Channel
    │
Real App Flow
    └── Method Channel → Platform Handler → Native Code → Mapbox SDK

Test Flow
    └── Method Channel → Mock Handler → Test Verification
```

## Test Categories

### Unit Tests
**Purpose**: Test individual components in isolation
**Coverage Target**: 80%

Key areas:
- Waypoint handling and validation
- Navigation state management
- Configuration validation
- Error handling

### Widget Tests
**Purpose**: Test UI components and interactions
**Coverage Target**: 70%

Key areas:
- Navigation view rendering
- User input handling
- Widget lifecycle

### Integration Tests
**Purpose**: Test plugin integration with Flutter
**Coverage Target**: 60%

Key areas:
- Method channel communication
- Full navigation workflows
- Error handling and recovery

### Golden Tests
**Purpose**: Visual verification of UI states

Key areas:
- Map rendering states
- Navigation UI states
- Theme variations

## Writing Tests

### Test File Structure
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mapbox_navigation/flutter_mapbox_navigation.dart';

void main() {
  group('Feature Name', () {
    setUp(() {
      // Setup code
    });

    tearDown(() {
      // Cleanup code
    });

    test('should do something specific', () {
      // Arrange
      final waypoint = WayPoint(name: 'Test', latitude: 0.0, longitude: 0.0);

      // Act
      final json = waypoint.toJson();

      // Assert
      expect(json['name'], equals('Test'));
    });
  });
}
```

### Mocking Strategy

```dart
// Set up mock handler for platform channel
TestWidgetsFlutterBinding.ensureInitialized();

const channel = MethodChannel('flutter_mapbox_navigation');
TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
    .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
  switch (methodCall.method) {
    case 'buildRoute':
      return true;
    case 'startNavigation':
      return true;
    default:
      return null;
  }
});
```

## Best Practices

1. **Test Organization**
   - Group related tests
   - Use descriptive test names
   - Follow AAA pattern (Arrange, Act, Assert)

2. **Test Independence**
   - Each test should be independent
   - Clean up state in tearDown
   - Don't rely on test execution order

3. **Mock Responses**
   - Return consistent mock responses
   - Simulate both success and failure cases
   - Match real platform behavior

4. **Coverage**
   - Test all public methods
   - Cover different parameter combinations
   - Include error cases and edge cases

## Continuous Integration

Tests run automatically on:
- Every pull request
- Every push to master branch
- Manual workflow trigger

### GitHub Actions Workflow
```yaml
name: Tests
on: [push, pull_request]
jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
      - run: flutter pub get
      - run: flutter test --coverage
```

## Troubleshooting

### Common Issues

**Test Timeout**
- Increase timeout duration: `timeout: Duration(seconds: 30)`
- Check for infinite loops or blocking operations
- Verify async operations complete

**Platform Channel Errors**
- Ensure mock handlers are set up before tests
- Verify method channel names match
- Check that mocks return expected types

**Coverage Issues**
- Run with `--coverage` flag
- Check that files are not excluded
- Verify test execution completes

### Getting Help
1. Check test logs for detailed error messages
2. Review the test documentation
3. Check GitHub issues for known problems

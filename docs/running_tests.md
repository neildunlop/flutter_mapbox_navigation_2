# Running Tests

## Prerequisites
- Flutter SDK installed
- Dart SDK installed
- Android Studio or VS Code with Flutter extensions
- Mapbox access token configured

## Test Structure
The tests are organized in the following structure:
```
test/
├── unit/           # Unit tests
├── widget/         # Widget tests
├── integration/    # Integration tests
└── golden/         # Golden tests
```

## Running Tests

### Running All Tests
To run all tests:
```bash
flutter test
```

### Running Specific Test Types
To run specific test types:
```bash
# Run unit tests only
flutter test test/unit/

# Run widget tests only
flutter test test/widget/

# Run integration tests only
flutter test test/integration/

# Run golden tests only
flutter test test/golden/
```

### Running Individual Test Files
To run a specific test file:
```bash
flutter test test/unit/waypoint_test.dart
```

### Running Tests with Coverage
To run tests with coverage report:
```bash
flutter test --coverage
```

To view the coverage report:
```bash
# Install lcov if not already installed
# On Windows with Chocolatey:
# choco install lcov
# 
# On macOS with Homebrew:
# brew install lcov

# Generate HTML report
genhtml coverage/lcov.info -o coverage/html

# Open the report
start coverage/html/index.html
```

## Test Development

### Creating New Tests
1. Create test file in appropriate directory
2. Follow naming convention: `*_test.dart`
3. Include necessary imports
4. Write test cases following AAA pattern (Arrange, Act, Assert)

### Test File Structure
```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:your_package/your_file.dart';

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
      // Act
      // Assert
    });
  });
}
```

### Best Practices
1. Use descriptive test names
2. Follow AAA pattern
3. Keep tests independent
4. Use appropriate assertions
5. Mock external dependencies
6. Clean up resources in tearDown

## Continuous Integration
Tests are automatically run on:
- Every pull request
- Every push to main branch
- Manual workflow trigger

## Troubleshooting

### Common Issues
1. **Test Timeout**
   - Increase timeout duration
   - Check for infinite loops
   - Verify async operations

2. **Platform Channel Errors**
   - Ensure proper mocking
   - Check method channel setup
   - Verify platform-specific code

3. **Coverage Issues**
   - Check test coverage configuration
   - Verify test execution
   - Review coverage report

### Getting Help
If you encounter issues:
1. Check the test logs
2. Review the test documentation
3. Check GitHub issues
4. Contact the maintainers 
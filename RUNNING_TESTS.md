# Running and Testing the Implementation

## Prerequisites

1. Flutter SDK installed (3.3.0 or higher)
2. Dart SDK (comes with Flutter)

## Setup

1. Get dependencies:
```bash
flutter pub get
```

2. Run code analysis:
```bash
flutter analyze
```

## Running Tests

### Run All Tests
```bash
flutter test
```

### Run Specific Test File
```bash
# Session tests
flutter test test/session_test.dart

# Repository tests
flutter test test/repository_test.dart
```

### Run Tests with Coverage
```bash
flutter test --coverage
```

## Running the Application

### Development Mode
```bash
flutter run
```

### Run on Specific Device
```bash
# List available devices
flutter devices

# Run on specific device
flutter run -d <device-id>
```

### Build for Release

#### Android
```bash
flutter build apk --release
```

#### iOS
```bash
flutter build ios --release
```

## Manual Testing Workflow

### 1. Test Authentication Flow

1. Launch the app
2. You should see the login screen
3. Enter any email (e.g., `test@example.com`)
4. Enter any password (e.g., `password123`)
5. Click "Login"
6. Should be redirected to dashboard
7. Close and reopen app - should stay logged in

### 2. Test Navigation

From dashboard, navigate to:
- Settings (placeholder)
- Customers (placeholder)
- Job Cards (placeholder)
- etc.

### 3. Test Repository Operations (via Code/Tests)

The repositories are tested via the test suite:
- Create operations
- Fetch operations
- List operations with filtering
- Watch streams for real-time updates
- Sorting verification

## Verifying Implementation

### Check Session Persistence

1. Login with `test@example.com`
2. Check Hive storage location:
   - Android: `/data/data/com.example.garage_mv0/app_flutter/`
   - iOS: `<app-container>/Documents/`
3. Should see `auth.hive` and `garages.hive` files

### Check Repository Data

After creating data via repositories, check Hive boxes:
- `customers.hive`
- `vehicles.hive`
- `jobCards.hive`
- etc.

### Verify Router Behavior

1. When not logged in, trying to access `/dashboard` should redirect to `/login`
2. When logged in, accessing `/login` should redirect to `/dashboard`
3. Public route `/approve/:token` should work without authentication

## Troubleshooting

### Tests Failing

If tests fail with Hive errors:
```bash
# Clean test data
flutter clean
flutter pub get
flutter test
```

### App Won't Start

1. Check Flutter installation:
```bash
flutter doctor
```

2. Clear build cache:
```bash
flutter clean
flutter pub get
```

3. Restart IDE/editor

### Router Not Working

Make sure you're using the `routerProvider` from `app_router.dart`:
```dart
final router = ref.watch(routerProvider);
```

## Code Quality

### Format Code
```bash
dart format .
```

### Analyze Code
```bash
flutter analyze
```

### Check for Outdated Packages
```bash
flutter pub outdated
```

## Next Steps After Testing

Once you've verified the implementation works:

1. **Add Firebase**: Replace mock repositories with Firebase implementations
2. **Build UI**: Create customer, vehicle, and job card screens
3. **Add Features**: Implement quotation builder, PDF generation, etc.
4. **End-to-End Tests**: Add integration tests for complete workflows

## Debugging Tips

### Enable Verbose Logging
```bash
flutter run -v
```

### View Hive Data

Use Hive's developer tools or add debug code:
```dart
final box = await Hive.openBox('customers');
print(box.values);
```

### Debug Router
```dart
GoRouter(
  debugLogDiagnostics: true,
  // ... routes
)
```

### Watch Provider State
```dart
ref.listen<SessionState>(sessionControllerProvider, (previous, next) {
  print('Session changed: ${next.isAuthenticated}');
});
```

## Performance Testing

For production readiness, test:
- Large dataset handling (1000+ customers)
- Concurrent operations
- Memory usage
- Battery impact
- Network handling (when Firebase is added)

## Security Checklist

Before production:
- [ ] Replace local auth with Firebase Auth
- [ ] Add proper input validation
- [ ] Implement rate limiting
- [ ] Add error boundaries
- [ ] Secure sensitive data
- [ ] Add logging and monitoring

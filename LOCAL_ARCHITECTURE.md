# Local-First Architecture Guide

## Overview
The Garage MVP app is built with a local-first architecture using Hive for data persistence. This allows the app to work completely offline without requiring Firebase during development.

## Architecture

### Repository Pattern
The app uses the Repository pattern with abstract interfaces, allowing easy switching between different implementations:

```
Abstract Interface → Local Implementation (Hive)
                  → Future: Firebase Implementation
```

### Local Storage (Hive)
All data is stored locally using Hive, a lightweight and fast key-value database for Flutter.

**Location:** `lib/core/local_storage.dart`

#### Hive Boxes
The following boxes are created for data storage:

- `app` - Application-level data (sessionGarageId)
- `auth` - Authentication data (currentUserId)
- `garages` - Garage profiles
- `users` - User accounts
- `customers` - Customer records
- `vehicles` - Vehicle records
- `jobCards` - Job card records
- `quotations` - Quotation records
- `invoices` - Invoice records
- `payments` - Payment records
- `approvalTokens` - Customer approval tokens

### Repository Implementations

All repository implementations are located in `lib/repositories/local/`:

1. **LocalGarageRepository** - Manages garage profiles and usage tracking
2. **LocalAuthRepository** - Handles authentication and user sessions
3. **LocalCustomerRepository** - CRUD operations for customers
4. **LocalVehicleRepository** - CRUD operations for vehicles
5. **LocalJobCardRepository** - CRUD operations for job cards
6. **LocalQuotationRepository** - CRUD operations for quotations
7. **LocalInvoiceRepository** - CRUD operations for invoices
8. **LocalPaymentRepository** - CRUD operations for payments
9. **LocalApprovalRepository** - Manages customer approval tokens

### Data Flow

1. **App Initialization**
   - `main.dart` initializes Hive: `await LocalStorage.init()`
   - All boxes are opened and ready for use

2. **User Authentication**
   - Sign up creates a new garage and user
   - Sign in sets `sessionGarageId` in the app box
   - Current user is tracked in the auth box

3. **Data Operations**
   - All data is scoped by `garageId` (multi-tenancy ready)
   - CRUD operations use the repository pattern
   - Stream-based updates notify listeners of changes

### Session Management

The app maintains a session using:
- `LocalStorage.getSessionGarageId()` - Get current garage
- `LocalStorage.setSessionGarageId(id)` - Set current garage

This allows the app to remember which garage is logged in across app restarts.

## Benefits of Local-First

✅ **Works Offline** - No internet connection required
✅ **Fast Development** - No Firebase setup needed initially
✅ **Easy Testing** - Data persists locally between app restarts
✅ **Privacy** - All data stays on the device
✅ **Future Ready** - Easy to add Firebase later

## Migration to Firebase (Future)

When ready to use Firebase:

1. Create Firebase repository implementations (e.g., `FirebaseCustomerRepository`)
2. Update `lib/app/providers/repository_providers.dart` to use Firebase implementations
3. Uncomment Firebase initialization in `main.dart`
4. Data migration can be done by reading from Hive and writing to Firebase

The repository interfaces ensure this transition will be seamless!

## Development Tips

### Testing Locally
Since all data is in Hive:
- Use Flutter DevTools to inspect Hive data
- Clear app data to reset the database
- Data persists between hot reloads and app restarts

### Adding New Features
When adding new features:
1. Define the model class with `toMap()` and `fromMap()` methods
2. Create the repository interface
3. Implement the local repository using Hive
4. Add the repository provider in `repository_providers.dart`

### Common Patterns

**Creating a record:**
```dart
final customer = Customer(
  id: uuid.v4(),
  garageId: currentGarageId,
  // ... other fields
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
await customerRepository.create(customer);
```

**Listing records:**
```dart
final customers = await customerRepository.listByGarage(garageId);
```

**Watching for changes:**
```dart
customerRepository.watchByGarage(garageId).listen((customers) {
  // Handle updates
});
```

## File Structure

```
lib/
├── core/
│   └── local_storage.dart          # Hive initialization and box management
├── repositories/
│   ├── customer_repository.dart     # Abstract interface
│   ├── local/
│   │   ├── local_customer_repository.dart  # Hive implementation
│   │   └── ... (other local implementations)
│   └── mock/                        # Mock implementations (for reference)
└── app/
    └── providers/
        └── repository_providers.dart   # Dependency injection
```

## Dependencies

The following packages are used for local storage:

- `hive: ^2.2.3` - Core Hive database
- `hive_flutter: ^1.1.0` - Flutter integration for Hive
- `uuid: ^4.3.3` - Generate unique IDs
- `intl: ^0.19.0` - Date/time formatting

## Notes

- The old `lib/services/local_storage.dart` was kept for backward compatibility
- Mock implementations are kept in `lib/repositories/mock/` for reference
- Firebase dependencies remain in `pubspec.yaml` for future use
- All models support both ISO date format and milliseconds for flexibility

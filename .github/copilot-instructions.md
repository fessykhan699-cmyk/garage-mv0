# GitHub Copilot Instructions for Garage MVP

## Project Overview
This is a **production-ready mobile app MVP** for garages (auto repair workshops) to create job cards, quotations, invoices, and share them via WhatsApp. The app is **cash-first** with a freemium monetization model.

**Goal:** Ship a working MVP that can collect real money in week 1. Not a demo, not a UI toy.

## Tech Stack
- **Platform:** Flutter (Android + iOS)
- **SDK:** Dart 3.3.0+
- **Backend:** Firebase only
  - Firebase Auth (Email/Password)
  - Cloud Firestore (database)
  - Firebase Storage (PDFs and images)
  - Firebase Functions (optional)
- **State Management:** flutter_riverpod 2.5.1+
- **Routing:** go_router 13.2.0+
- **Key Libraries:**
  - pdf 3.10.8+ (PDF generation)
  - printing 5.11.0+ (PDF printing/sharing)
  - share_plus 7.2.1+ (WhatsApp sharing)
  - image_picker 1.0.7+ (photo uploads)
  - flutter_image_compress 2.1.0+ (image compression)
  - hive 2.2.3+ (local storage)

## Project Structure
```
lib/
├── app/              # App-wide configuration, theme, routing
├── features/         # Feature modules (auth, customers, job_cards, etc.)
├── models/           # Data models
├── services/         # Firebase services, PDF generation
├── repositories/     # Data access layer
└── main.dart         # App entry point
```

## Commands & Workflows

### Development
```bash
# Get dependencies
flutter pub get

# Run app
flutter run

# Run on specific device
flutter run -d <device-id>

# Hot reload: Press 'r' in terminal
# Hot restart: Press 'R' in terminal
```

### Linting & Code Quality
```bash
# Analyze code
flutter analyze

# Format code (use this before committing)
dart format .

# Check for outdated packages
flutter pub outdated
```

### Build
```bash
# Build APK (Android)
flutter build apk --release

# Build iOS
flutter build ios --release
```

### Testing
```bash
# Run all tests
flutter test

# Run specific test file
flutter test test/path/to/test.dart

# Run tests with coverage
flutter test --coverage
```

## Coding Conventions

### Dart Style
- Follow official Dart style guide
- Use `dart format .` before committing
- Use trailing commas for better formatting
- Prefer `const` constructors when possible
- Use descriptive variable names, avoid abbreviations

### File Naming
- Use snake_case for file names: `job_card_screen.dart`
- Use PascalCase for class names: `JobCardScreen`
- Use camelCase for variables and functions: `jobCardId`

### Import Organization
```dart
// 1. Dart SDK imports
import 'dart:async';

// 2. Flutter imports
import 'package:flutter/material.dart';

// 3. Package imports
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 4. Local imports
import '../models/job_card.dart';
import '../services/firestore_service.dart';
```

### State Management with Riverpod
- Use Riverpod providers for dependency injection
- Keep providers in separate files or at the top of feature files
- Use `ConsumerWidget` or `Consumer` for accessing providers
- Prefer `AsyncValue` for async operations

### Firebase Best Practices
- Always include `garageId` in document paths for multi-tenancy
- Use server timestamps: `FieldValue.serverTimestamp()`
- Use subcollections for logical grouping: `garages/{garageId}/customers/{customerId}`
- Batch writes when updating multiple documents
- Handle errors gracefully with try-catch blocks

## Critical Constraints (NON-NEGOTIABLE)

### Scope Control
**DO NOT add features beyond MVP scope:**
- ✅ Auth, Garage profile, Customers, Vehicles
- ✅ Job Cards with photos
- ✅ Quotation builder with PDF
- ✅ Public approval link (no-login)
- ✅ Invoice + payment recording
- ✅ WhatsApp share templates
- ✅ Dashboard (today paid, pending approvals, unpaid invoices)

**OUT OF SCOPE (DO NOT BUILD):**
- ❌ Customer app
- ❌ Chat inside app
- ❌ Inventory/suppliers
- ❌ Appointment booking
- ❌ Multi-branch roles/permissions
- ❌ Push notifications
- ❌ Offline mode
- ❌ Deep analytics
- ❌ Fancy animations

### Monetization Model (MUST ENFORCE)
**FREE Plan allows:**
- Create up to 3 job cards
- Build quotation inside app (preview only)
- ❌ NO PDF export
- ❌ NO WhatsApp share
- ❌ NO customer approval link
- ❌ NO invoice PDF

**PRO Plan unlocks:**
- ✅ PDF export + WhatsApp share
- ✅ Customer approval link
- ✅ Invoice PDF + payment tracking
- ✅ Remove watermark

**Implementation:**
- Check `garages/{garageId}.plan` field ("free" or "pro")
- Gate features with `canUseProFeatures()` function
- Track usage counters in `garages/{garageId}.usage`
- Show paywall screen when free users try to access pro features

### Forbidden Actions
- ❌ Never use FlutterFlow or no-code tools
- ❌ Never add paid external services (except Firebase)
- ❌ Never commit secrets or API keys to code
- ❌ Never allow cross-garage data access
- ❌ Never skip error handling on Firebase operations
- ❌ Never implement features that increase complexity without value
- ❌ Never create messy UI that decreases conversion

## Firestore Schema Reference

### Key Collections
- `garages/{garageId}` - Garage profile, plan, usage counters
- `users/{userId}` - User profile with garageId
- `garages/{garageId}/customers/{customerId}` - Customers
- `garages/{garageId}/vehicles/{vehicleId}` - Vehicles
- `garages/{garageId}/jobCards/{jobCardId}` - Job cards
- `garages/{garageId}/quotations/{quotationId}` - Quotations
- `approvalTokens/{tokenId}` - Public approval tokens (no auth required)
- `garages/{garageId}/invoices/{invoiceId}` - Invoices
- `garages/{garageId}/payments/{paymentId}` - Payment records

### Security Rules Principles
- Isolate garages by garageId
- Only garage users can read/write their data
- Public approval tokens can only access ONE quotation
- Tokens can only write approval decision once
- Use `request.auth.uid` for user-based rules
- Use token validation for public approval flow

## PDF Generation & Storage
1. Generate PDF using `pdf` package
2. Compress images before adding to PDF
3. Upload PDF to Firebase Storage: `garages/{garageId}/pdfs/{pdfId}.pdf`
4. Save storage path and download URL in Firestore
5. For free plan: Either no PDF or watermarked PDF only

## WhatsApp Share Templates

### Quotation Template
```
Hi {CustomerName}, here is your quotation for {VehiclePlate}. 
Total: {Total}. 
Please approve or reject here: {ApprovalLink}. 
PDF attached.
```

### Invoice Template
```
Hi {CustomerName}, your invoice for {VehiclePlate} is ready. 
Amount due: {Total}. 
PDF attached. Thank you.
```

## Error Handling
- Always wrap Firebase calls in try-catch blocks
- Show user-friendly error messages
- Log errors for debugging: `print()` or `debugPrint()`
- Handle network errors gracefully
- Handle permission denied errors (likely cross-garage access attempt)

## UI/UX Guidelines
- Keep UI clean and minimal
- UI is a liability unless it increases conversion
- Follow Material Design 3 guidelines
- Use consistent spacing and colors
- Show loading states for async operations
- Show empty states when lists are empty
- Always provide clear call-to-action buttons

## Testing Approach
- Write unit tests for business logic
- Write widget tests for complex UI
- Use `flutter test` to run tests
- Mock Firebase services in tests
- Focus on critical paths: quotation calculation, PDF generation, approval flow

## Common Patterns

### Loading States
```dart
AsyncValue.when(
  data: (data) => YourWidget(data),
  loading: () => CircularProgressIndicator(),
  error: (err, stack) => Text('Error: $err'),
)
```

### Error Handling
```dart
try {
  await firestoreService.createJobCard(jobCard);
} on FirebaseException catch (e) {
  if (e.code == 'permission-denied') {
    showError('Access denied');
  } else {
    showError('Failed to create job card: ${e.message}');
  }
} catch (e) {
  showError('Unexpected error: $e');
}
```

### Pro Feature Gate
```dart
Future<bool> canUseProFeatures() async {
  final garage = await getGarage();
  return garage.plan == 'pro';
}

// Before exporting PDF
if (!await canUseProFeatures()) {
  showPaywallScreen();
  return;
}
// Proceed with PDF export
```

## Development Workflow
1. Check existing documentation: AGENT_PROMPT.md, UI_FLOW.md, FIRESTORE_SCHEMA.md, TASKS.md
2. Follow the phase order in TASKS.md
3. Implement one feature at a time
4. Test locally before committing
5. Keep commits focused and atomic
6. Update README if setup steps change

## Assumptions You Can Make
- VAT rate is 5% (if enabled)
- Manual upgrade toggle for testing (no real payment integration yet)
- WhatsApp sharing uses `share_plus` package
- Job card numbers are timestamp-based or simple incrementing
- Invoice numbers are timestamp-based or simple incrementing
- Approval links expire after 30 days (configurable)
- Images are compressed to max 1MB before upload
- PDFs are stored in Firebase Storage with public read access (but obscure URLs)

## When in Doubt
- Prioritize shipping working features over perfect code
- Keep it simple - no over-engineering
- Make reasonable assumptions and document them
- Focus on the core pain points:
  - Customer approval proof
  - Professional PDFs
  - Payment tracking
  - Preventing disputes
- Remember: This is a solo-founder MVP, not an enterprise system

## References
- See AGENT_PROMPT.md for detailed requirements
- See UI_FLOW.md for screen flow and navigation
- See FIRESTORE_SCHEMA.md for complete data model
- See FIRESTORE_RULES.md for security rules notes
- See TASKS.md for implementation order and checklist
- See README.md for setup instructions

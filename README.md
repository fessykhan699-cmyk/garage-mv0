# Garage MVP (Job Card → Quote → Approval → Invoice)

Cash-first garage app for creating professional quotations + customer approval links + invoices shared via WhatsApp.

## MVP Scope (Locked)
- Auth + Garage profile
- Customers + Vehicles
- Job Cards (with photos)
- Quotation builder + PDF
- Public approval link (approve/reject)
- Invoice + payment recording + PDF
- WhatsApp share templates
- Dashboard (today paid, pending approvals, unpaid invoices)

Out of scope: inventory, chat, appointments, notifications, multi-branch roles.

## Tech Stack
- Flutter (Android + iOS)
- Firebase: Auth, Firestore, Storage (Functions optional)
- Hive: Local storage for offline-first development
- No FlutterFlow

## Development Mode
The app currently runs in **local-first mode** using Hive for data persistence. This allows full offline development and testing without Firebase setup.

### Local Mode (Current)
- Uses Hive for all data storage
- No Firebase connection required
- Data persists locally on device
- Perfect for development and testing

### Firebase Mode (Future)
- Will use Firebase Auth, Firestore, and Storage
- Repository interfaces are already defined
- Easy switch from Local to Firebase implementations
- Plan to implement Firebase repositories later

## Monetization (Cash-first)
Free plan:
- Build quotes inside app (preview only)
- No PDF export
- No WhatsApp share
- No approval links
- No invoice PDF

Pro plan:
- PDF export + WhatsApp share
- Approval links
- Invoice PDF + payments
- No watermark

Plan gating is controlled by Firestore: `garages/{garageId}.plan = "free" | "pro"`

## Repo Files
- `AGENT_PROMPT.md` — Build instructions for AI agent
- `UI_FLOW.md` — Screen flow (locked)
- `FIRESTORE_SCHEMA.md` — Firestore schema (locked)
- `TASKS.md` — Execution order checklist

## Setup (Laptop Required)
### Prereqs
- Flutter SDK installed
- Android Studio (for Android) and/or Xcode (for iOS)

### Local Development (No Firebase Required)
The app is currently configured for local-first development using Hive:

```bash
flutter pub get
flutter run
```

No Firebase setup needed! The app will work completely offline.

### Firebase Setup (Optional for Future)
When ready to integrate Firebase:
1. Create Firebase project
2. Enable Authentication → Email/Password
3. Create Firestore database
4. Enable Storage
5. Add Android + iOS apps in Firebase console
6. Download config files:
   - `google-services.json` → `android/app/`
   - `GoogleService-Info.plist` → `ios/Runner/`

### Local Run
```bash
flutter pub get
flutter run

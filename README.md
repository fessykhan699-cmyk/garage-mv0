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

Out of scope: inventory, chat, appointments, notifications, offline mode, multi-branch roles.

## Tech Stack
- Flutter (Android + iOS)
- Firebase: Auth, Firestore, Storage (Functions optional)
- No FlutterFlow

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
- Firebase account

### Firebase Setup
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
```

### Git Merge Workflow
```bash
git checkout main
git pull
git merge <branch-name>
git push
```

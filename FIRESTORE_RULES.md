# Firestore Rules (To Paste Later)

NOTE:
- Use these only after the app code exists and you know where `garageId` lives.
- Public approval tokens must only expose ONE quotation summary and allow decision once.

TODO ON LAPTOP:
- Paste final rules in Firebase Console → Firestore → Rules
- Test:
  - user from garage A cannot read/write garage B
  - token can only read one quote summary
  - token can only approve/reject once

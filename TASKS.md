# Garage MVP – Execution Tasks (Do Not Skip Order)

## Phase 0 — Repo + Rules
- [ ] Confirm AGENT_PROMPT.md exists
- [ ] Confirm UI_FLOW.md exists
- [ ] Confirm FIRESTORE_SCHEMA.md exists
- [ ] Scope locked (no extra features)

## Phase 1 — Firebase Setup (must be first)
- [ ] Create Firebase project
- [ ] Enable Authentication: Email/Password
- [ ] Create Firestore database
- [ ] Enable Firebase Storage
- [ ] Add Firestore Security Rules (tight isolation + public token access)
- [ ] Add required Firestore indexes (after queries are known)
- [ ] Create initial “garages” doc on first login (free plan default)

## Phase 2 — Flutter Project Scaffold
- [ ] Create Flutter app
- [ ] Add dependencies:
  - firebase_core
  - firebase_auth
  - cloud_firestore
  - firebase_storage
  - (state mgmt: Riverpod OR Provider)
  - pdf + printing/sharing packages
  - image_picker + image compression
- [ ] App folder structure:
  - lib/app
  - lib/features/*
  - lib/shared/*
  - lib/services/*
  - lib/models/*
- [ ] Global theme + routing

## Phase 3 — Auth + Garage Context
- [ ] Login screen
- [ ] On first login:
  - create garage doc (plan=free, usage counters)
  - create user doc with garageId
- [ ] Persist garageId in app state

## Phase 4 — Core CRUD
- [ ] Customers: list + add + search
- [ ] Vehicles: list (per customer) + add
- [ ] Job Cards:
  - create job card (customer + vehicle + complaint)
  - job card detail + status updates
  - photo upload before/after

## Phase 5 — Quotation Builder + Calculations
- [ ] Labor items add/edit/remove
- [ ] Parts items add/edit/remove
- [ ] VAT toggle (default 5% assumption)
- [ ] Totals calculation (subtotal, vat, total)
- [ ] Save quotation draft

## Phase 6 — Monetization Gate (cash-first)
- [ ] Implement `canUseProFeatures()`:
  - if plan != "pro" → block:
    - PDF export
    - WhatsApp share
    - approval link generation
    - invoice PDF
- [ ] Paywall screen:
  - shows benefits
  - “Contact to upgrade” / “Manual upgrade” (admin only)

## Phase 7 — PDF Generation + Storage
- [ ] Generate Quotation PDF
- [ ] Upload PDF to Storage
- [ ] Save pdf.downloadUrl + storagePath in quotation
- [ ] If free plan allows preview only:
  - no PDF upload OR upload watermarked only (pick one and enforce)

## Phase 8 — Approval Link (public)
- [ ] Create approval token doc (approvalTokens/{tokenId})
- [ ] Build public approval screen:
  - loads via tokenId
  - shows quote summary
  - approve/reject once
  - writes decision + timestamp
  - updates quotation status accordingly

## Phase 9 — WhatsApp Share
- [ ] Share quotation PDF + approval link with template message (Pro only)
- [ ] Share invoice PDF with template message (Pro only)

## Phase 10 — Invoice + Payments
- [ ] Convert approved quotation to invoice
- [ ] Generate invoice PDF + upload
- [ ] Record payments
- [ ] Update invoice status + totals (paid/partial/unpaid)

## Phase 11 — Dashboard
- [ ] Today paid total
- [ ] Pending approvals count + amount
- [ ] Unpaid invoices count + amount
- [ ] Open job cards count

## Phase 12 — Hardening
- [ ] Error handling (network, permission denied)
- [ ] Loading states
- [ ] Basic empty states
- [ ] Ensure rules block cross-garage access
- [ ] Ensure public token cannot read other data

## Phase 13 — README + Demo Script
- [ ] README setup steps
- [ ] 60-second demo script (create job → quote → approval → invoice → payment)

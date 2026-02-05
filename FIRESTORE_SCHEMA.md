# Firestore Schema – Garage MVP (Locked)

## Naming rules
- Every document must include: `garageId`
- Use server timestamps for created/updated
- Prefer subcollections only when needed

---

## Collection: garages
**Path:** `garages/{garageId}`
**Fields:**
- name: string
- phone: string
- address: string
- logoUrl: string (optional)
- plan: string ("free" | "pro")
- planActivatedAt: timestamp (optional)
- planExpiresAt: timestamp (optional)
- usage: map
  - jobCardsCreated: number
  - pdfExports: number
  - approvalsCreated: number
  - invoicesCreated: number
- createdAt: timestamp
- updatedAt: timestamp

---

## Collection: users
**Path:** `users/{userId}`
**Fields:**
- garageId: string
- email: string
- role: string ("owner" | "staff")  // keep, but no complex permissions
- createdAt: timestamp
- updatedAt: timestamp

---

## Collection: customers
**Path:** `garages/{garageId}/customers/{customerId}`
**Fields:**
- garageId: string
- name: string
- phone: string
- notes: string (optional)
- createdAt: timestamp
- updatedAt: timestamp

---

## Collection: vehicles
**Path:** `garages/{garageId}/vehicles/{vehicleId}`
**Fields:**
- garageId: string
- customerId: string
- plateNumber: string
- make: string (optional)
- model: string (optional)
- year: number (optional)
- vin: string (optional)
- createdAt: timestamp
- updatedAt: timestamp

---

## Collection: jobCards
**Path:** `garages/{garageId}/jobCards/{jobCardId}`
**Fields:**
- garageId: string
- customerId: string
- vehicleId: string
- jobCardNumber: string  // simple incremental-ish or timestamp-based
- complaint: string
- notes: string (optional)
- status: string ("draft" | "awaiting_approval" | "approved" | "in_progress" | "ready" | "closed")
- beforePhotoUrls: array<string> (optional)
- afterPhotoUrls: array<string> (optional)
- createdAt: timestamp
- updatedAt: timestamp

---

## Collection: quotations
**Path:** `garages/{garageId}/quotations/{quotationId}`
**Fields:**
- garageId: string
- jobCardId: string
- customerId: string
- vehicleId: string
- quoteNumber: string
- status: string ("draft" | "sent" | "approved" | "rejected")
- laborItems: array<map>
  - name: string
  - qty: number
  - rate: number
  - total: number
- partItems: array<map>
  - name: string
  - qty: number
  - rate: number
  - total: number
- vatEnabled: boolean
- vatRate: number   // default 0.05 (assumption)
- subtotal: number
- vatAmount: number
- total: number
- pdf:
  - storagePath: string (optional)
  - downloadUrl: string (optional)
  - generatedAt: timestamp (optional)
  - watermarked: boolean
- approval:
  - tokenId: string (optional)
  - approvalUrl: string (optional)
  - approvedAt: timestamp (optional)
  - rejectedAt: timestamp (optional)
  - customerComment: string (optional)
- createdAt: timestamp
- updatedAt: timestamp

---

## Collection: approvalTokens (public access)
**Path:** `approvalTokens/{tokenId}`
**Fields:**
- garageId: string
- quotationId: string
- status: string ("pending" | "approved" | "rejected")
- customerComment: string (optional)
- createdAt: timestamp
- decidedAt: timestamp (optional)
- expiresAt: timestamp (optional)
- used: boolean
- usedAt: timestamp (optional)

---

## Collection: invoices
**Path:** `garages/{garageId}/invoices/{invoiceId}`
**Fields:**
- garageId: string
- quotationId: string
- jobCardId: string
- customerId: string
- vehicleId: string
- invoiceNumber: string
- status: string ("unpaid" | "partial" | "paid")
- subtotal: number
- vatAmount: number
- total: number
- amountPaid: number
- balanceDue: number
- pdf:
  - storagePath: string (optional)
  - downloadUrl: string (optional)
  - generatedAt: timestamp (optional)
- createdAt: timestamp
- updatedAt: timestamp

---

## Collection: payments
**Path:** `garages/{garageId}/payments/{paymentId}`
**Fields:**
- garageId: string
- invoiceId: string
- amount: number
- method: string ("cash" | "card" | "bank")
- paidAt: timestamp
- note: string (optional)
- createdAt: timestamp

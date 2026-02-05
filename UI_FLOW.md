# UI Flow – Garage MVP (Locked Scope)

## Authentication
- Login (Email + Password)

## Dashboard
- Today’s paid total
- Pending approvals (count + amount)
- Unpaid invoices (count + amount)
- Quick actions:
  - New Job Card
  - New Customer

## Customers
- Customers list
- Add customer
  - Name
  - Phone
  - Notes (optional)

## Vehicles
- Vehicle list per customer
- Add vehicle
  - Plate number
  - Make (optional)
  - Model (optional)
  - Year (optional)

## Job Cards
- Create job card
  - Select customer
  - Select vehicle
  - Complaint / notes
  - Photos (before)
- Job card detail
  - Status: Draft → Awaiting Approval → Approved → In Progress → Ready → Closed
  - Photos (after)
  - Create quotation

## Quotation
- Quotation builder
  - Labor items
  - Parts items
  - VAT toggle
  - Total auto-calculated
- Quotation preview
  - PRO paywall gate before:
    - PDF export
    - WhatsApp share
    - Approval link
- Share quotation
  - WhatsApp (PDF + approval link)

## Customer Approval (Public)
- No login
- View quotation summary
- Approve or Reject
- Optional comment
- Timestamp saved

## Invoice
- Convert approved quotation → invoice
- Invoice PDF
- Payment status:
  - Unpaid
  - Partial
  - Paid
- Record payment:
  - Amount
  - Method
  - Date
- Share invoice via WhatsApp

## Settings
- Garage profile
  - Name
  - Logo
  - Phone
  - Address
- Plan status (Free / Pro)
- Manual upgrade toggle (admin only / hidden)

## Explicitly Out of Scope
- Inventory
- Chat
- Appointments
- Notifications
- Offline mode
- Multi-branch / roles

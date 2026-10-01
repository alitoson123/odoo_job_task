# Odoo Sales Portal Mobile App

A clean, production-grade Flutter application for sales teams that integrates directly with Odoo ERP (version 20.0 Enterprise).

---

## Architecture & Idea Overview

The application is built to empower mobile sales representatives with quick access to their customer directory, order statuses, and customer contact management in both online and field/offline scenarios.

The codebase strictly follows **Clean Architecture** combined with a **Feature-First structure**:
- **`core/`**: Reusable core infrastructure, including:
  - `services/`: `OdooClient` (JSON-2 HTTP client with Bearer authentication), `NetworkInfo` (connectivity observation), and `ServiceLocator` (GetIt DI).
  - `storage/`: `SecureStorage` (encrypted keychain/keystore token persistence) and `HiveStorage` (local offline cache and operations queue).
  - `router/`: Centralized declarative routing via `GoRouter` with auth-guard redirection.
  - `errors/`: Unified failure abstraction (`Failure`, `ServerFailure`, `CancelFailure`) mapping HTTP codes and Dio errors to human-readable messages.
  - `widgets/`: Shared UI components, such as `OfflineBanner`.
- **`features/auth/`**: Authentication lifecycle, credential validation against Odoo, secure session storage, and logout.
- **`features/customers/`**: Customer listing with live search, details view, phone editing, local caching, and synchronization queue.
- **`features/orders/`**: Sales order inspection (list & details), quotation confirmation workflow, and internal user permission check (`base.group_user`).

---
## What is Done 

### ✅ What is Done
1. **Authentication**:
   - Secure login with Odoo username and API key.
   - Credentials stored in encrypted secure storage (`flutter_secure_storage`).
   - Auto-login on app restart if valid credentials exist.
   - Logout and session expiration handling (401/403).
2. **Customer Directory**:
   - Customer list fetched with `customer_rank > 0` sorted alphabetically.
   - Debounced search filtering by customer name.
   - Loading, Empty, and Error states with retry on failure.
3. **Customer Details & Edit**:
   - Contact and multi-part address inspection.
   - Phone number editing with instant optimistic local update and Odoo write (`res.partner/write`).
4. **Sales Orders (Internal Users Only)**:
   - Authorization check verifying if the user belongs to `base.group_user`.
   - Sales orders list displaying order number, partner, date, and status.
   - Order detail view displaying itemized lines, quantities, unit prices, and totals.
   - Quotation confirmation action (`sale.order/action_confirm`) updating state to confirmed (`sale`).
5. **Offline Mode & Auto-Sync**:
   - Full read cache in Hive for customers and sales orders.
   - Clear "Offline mode" banner when browsing without internet.
   - "Pending sync" badge for customers with uncommitted changes.
   - Auto-sync service monitoring network connectivity (`connectivity_plus`) and executing queued writes when connection is restored.


---


## Architectural & Technical Decisions

### 1. Why Login Uses an API Key Instead of a Password
- **Security & Scoping**: Odoo API Keys (introduced natively for RPC access) can be restricted, monitored, and revoked independently of the user's master account password without resetting global credentials.
- **Direct RPC Protocol Compatibility**: Odoo JSON-2 endpoints authenticate via HTTP headers (`Authorization: bearer <API_KEY>`), avoiding the need for multi-step cookie/session management or XML-RPC password transmission over every payload.
- **Secure On-Device Storage**: The API key and authenticated username are persisted securely in Android Keystore / iOS Keychain via `flutter_secure_storage`.

### 2. JSON-2 as the Primary API
- Odoo 18/20 offers the modern `/json/2/<model>/<method>` REST-like JSON RPC specification.
- Unlike legacy XML-RPC, JSON-2 operates natively with standard JSON request/response formats, eliminates heavy XML serialization overhead, and provides faster round trips with structured status payloads.

### 3. Offline Handling & Conflict Policy
- **Local Cache (`Hive`)**: Successful reads for customers (`customers` box) and sales orders (`orders` box) are persisted in local fast storage. If the device loses connection, cached data is displayed alongside an **Offline mode** banner.
- **Sync Queue (`pending_ops`)**: Edits performed while offline update the local cache immediately (optimistic UI) and queue an operation into the `pending_ops` Hive box.
- **Conflict Resolution: Last Write Wins**: When internet connectivity returns, `CustomerSyncService` executes pending writes in strict chronological order. The last edit committed by the user takes precedence.








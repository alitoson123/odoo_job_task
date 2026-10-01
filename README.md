# Odoo Sales Portal Mobile App

A clean, production-grade Flutter application for sales teams that integrates directly with Odoo ERP (version 20.0 Enterprise).

---

## Architecture Overview

The project adheres to Clean Architecture with a Feature-First structure:
- **`core/`**: Centralized services, networking (`OdooClient`), storage (`SecureStorage`, `HiveStorage`), routing (`AppRouter`), error handling (`Failure`), and shared widgets (`OfflineBanner`).
- **`features/auth/`**: Authentication, credential validation, session expiry management, and secure token persistence.
- **`features/customers/`**: Customer listing with search, details view, phone number updates, offline caching, and automatic synchronization queue.
- **`features/orders/`**: Sales orders list, quotation inspection, order confirmation, and role verification (`base.group_user`).

---

## Offline Handling & Synchronization (Step 9)

### 1. Local Cache (`Hive`)
- **Customers Box (`customers`)**: Successful customer fetches are cached in Hive. When the device is offline or requests fail due to network errors, data is served from local cache with an **Offline mode** banner.
- **Sales Orders Box (`orders`)**: Sales orders and detailed order items are cached locally for offline browsing.

### 2. Offline Sync Queue (`pending_ops`)
- When customer contact information (e.g. phone number) is edited offline:
  1. The local cache in `customers` is updated immediately for an instant optimistic UI update.
  2. The edit operation is stored in the `pending_ops` Hive box:
     ```json
     {
       "partnerId": 12,
       "field": "phone",
       "value": "+1 555 0199",
       "timestamp": 1727827200000
     }
     ```
  3. A **Pending sync** indicator is displayed on that customer across the app.

### 3. Background Synchronization (`connectivity_plus`)
- `CustomerSyncService` continuously listens to network connectivity.
- When connectivity is restored:
  - Operations in `pending_ops` are processed in FIFO order (`res.partner/write`).
  - Succeeded operations are removed from the queue.
  - Operations that encounter network interruptions are retained for subsequent sync attempts.
  - Active cubits automatically refresh upon sync completion.

### 4. Conflict Policy: Last Write Wins
- Offline updates adhere to a **Last Write Wins** resolution policy.
- Local modifications update the cache instantly. When connectivity returns, operations are committed to Odoo in chronological timestamp order, ensuring the latest user update is applied.

---

## Running the Application

Pass your test Odoo API Key using `--dart-define`:
```bash
flutter run --dart-define=ODOO_KEY=your_rpc_api_key_here
```

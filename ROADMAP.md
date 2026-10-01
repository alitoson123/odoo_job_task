# Odoo Sales App: Full Roadmap

## 0. Context for the AI Agent

You are helping build a **Flutter mobile app for a sales team that integrates with Odoo (ERP)**. This is a time-boxed hiring task (deadline: 2 days), so prioritize a working, clean, reviewable app over completeness.

- **Odoo instance:** `https://techmates.odoo.com`
- **Database:** `techmates`
- **Odoo version:** 20.0 Enterprise
- **API:** JSON-2 (`POST /json/2/<model>/<method>`), authenticated with an **API Key** (scope: RPC). XML-RPC is the fallback only.
- **Developer level:** Flutter/Dart developer, familiar with BLoC and Clean Architecture, but new to Odoo. Explain Odoo-specific behavior when relevant.

### Hard rules
1. **Never hardcode or commit the API Key.** Pass it with `--dart-define=ODOO_KEY=...` for tests, and store user credentials with `flutter_secure_storage`.
2. Use **BLoC** (`flutter_bloc` + `equatable`) for state management.
3. Follow a feature-first structure with `data` / `presentation` layers per feature.
4. Keep files small and focused. Handle loading, empty, and error states on every screen.
5. Odoo returns `false` (not `null`) for empty fields. Always convert `false` to `null` in models.
6. Many2one fields (e.g. `partner_id`) are returned as `[id, "Display Name"]`.
7. Build and verify one step at a time. Do not jump ahead.

---

## 1. Original Requirements (from the client)

### 1.1 Login Screen
- Login with Odoo username + password.
- Authenticate against Odoo (prefer REST API, fallback to XML-RPC).
- Success: go to Customer List. Failure: show an error message.

### 1.2 Customer List Screen
- Fetch customers (`res.partner`) where `customer_rank > 0`.
- Display: Name, Phone, City.
- Basic search by customer name.

### 1.3 Customer Details Screen
- Show: Name, Phone, Email, Address.
- Allow updating the phone number and saving it back to Odoo.

### 1.4 Offline Handling (bonus)
- If offline: view cached customers.
- Edits made offline must sync back when the device is online again.

### 1.5 Sales Orders (internal users only)
- If the user is an internal user (`base.group_user`), provide a Sales Orders screen.
- List sale orders with: Order Number, Customer, Order Date, Status.
- On tap: show details (products, totals, status).
- Ability to confirm a sale order (draft/quotation to confirmed).

---

## 2. Progress Overview

| # | Step | Status |
|---|------|--------|
| 1 | Set up Odoo trial, API key, sample data | Done |
| 2 | Test the API outside Flutter (Python) | Done |
| 3 | Create Flutter project, packages, folders | Done |
| 4 | Odoo client + Auth repository (login logic) | In progress |
| 5 | Login screen (UI + BLoC + secure storage) | Todo |
| 6 | Customer list + search | Todo |
| 7 | Customer details + phone update | Todo |
| 8 | Sales orders (list, details, confirm) for internal users | Todo |
| 9 | Offline (cache + sync queue) | Todo |
| 10 | Polish, README, delivery | Todo |

**Priority order if time runs short:** 4, 5, 6, 7, 8, 10, 9.
Offline is a bonus. Even if the full sync queue is not finished, implement at least a simple cache for the customer list.

---

## 3. Tech Stack

| Purpose | Package |
|---------|---------|
| HTTP client | `dio` |
| State management | `flutter_cubit` |
| Secure credential storage | `flutter_secure_storage` |
| Local cache | `hive_flutter` |
| Connectivity | `connectivity_plus` |

---


## 5. Step-by-Step Details

### Step 4: Odoo Client + Auth Repository

**Goal:** a single `OdooClient` class that performs every request to `/json/2/<model>/<method>`.

**Required headers on every request:**
- `Authorization: bearer <API_KEY>`
- `X-Odoo-Database: techmates`
- `Content-Type: application/json`

**Error mapping:**
- HTTP 401/403: "Invalid username or API key"
- Connection error / timeout: "No internet connection"
- Anything else: show the server message

**Login design decision:** the client asked for username + password, but JSON-2 authenticates with an API Key. So the login form has a Username field and a Password / API Key field, and the user enters their API Key in the second field. This must be documented in the README.

**Login verification:** call `res.users/search_read` with `domain: [["login","=",username]]`, `fields: ["id","name","login"]`, `limit: 1`. A non-empty result means success. On failure, clear the stored key.

**Fallback:** XML-RPC (`/xmlrpc/2/common` then `authenticate`) if the real password must be supported.

**Definition of Done:**
- [ ] A valid key prints the user's data
- [ ] An invalid key prints the error message
- [ ] The key is not written anywhere in the source code

---

### Step 5: Login Screen

- Two fields: Username and Password / API Key (with show/hide toggle).
- `AuthBloc` states: `Initial`, `Loading`, `Authenticated`, `Failure`.
- On success: save username and API key in `flutter_secure_storage`, then navigate to Customer List.
- On failure: show the error message (SnackBar or text under the field).
- Auto-login: if credentials are stored, skip the login screen on app start.
- Logout: clear storage and return to Login.
- Validation: fields must not be empty.

**Definition of Done:**
- [ ] Successful login navigates to Customer List
- [ ] Failed login shows an error
- [ ] The user stays logged in after restarting the app

---

### Step 6: Customer List + Search

**Request:**
```json
POST /json/2/res.partner/search_read
{
  "domain": [["customer_rank", ">", 0]],
  "fields": ["name", "phone", "city"]
}
```

**Search by name:** append `["name", "ilike", query]` to the domain.

**UI:**
- `ListView` showing Name, Phone, City.
- Search bar with debounce (about 400 ms).
- Loading, Empty, and Error states (with a Retry button).
- Pull-to-refresh.

**Definition of Done:**
- [ ] The list shows customers
- [ ] Search works
- [ ] Tapping a customer opens the details screen

---

### Step 7: Customer Details + Phone Update

**Read details:**
```json
POST /json/2/res.partner/read
{
  "ids": [ID],
  "fields": ["name", "phone", "email", "street", "street2", "city", "zip", "country_id"]
}
```

**Address:** join `street`, `city`, and `country_id` (a Many2one, so use the display name) into one display string. Skip empty parts.

**Update phone:**
```json
POST /json/2/res.partner/write
{
  "ids": [ID],
  "vals": { "phone": "NEW_PHONE" }
}
```

**UI:** editable phone field, Save button, loading indicator, success/failure message.

**Definition of Done:**
- [ ] Details show correctly (Name, Phone, Email, Address)
- [ ] The phone update is saved and visible inside Odoo itself

---

### Step 8: Sales Orders (internal users only)

**Internal user check (`base.group_user`):**
- After login, verify the user belongs to `base.group_user`.
- Internal user: show the Sales Orders entry point. Otherwise hide it.
- NOTE: the exact method in Odoo 20 must be verified at implementation time. Options: call `has_group` on `res.users` through JSON-2, or read the user's groups and compare against the `base.group_user` external ID. Test in Python or Postman first.

**Order list:**
```json
POST /json/2/sale.order/search_read
{
  "fields": ["name", "partner_id", "date_order", "state"],
  "order": "date_order desc"
}
```
- `partner_id` is `[id, "Name"]`.
- States: `draft` (Quotation), `sent` (Quotation Sent), `sale` (Confirmed), `done` (Locked), `cancel` (Cancelled).
- Show status as a colored badge.

**Order details:**
```json
POST /json/2/sale.order/read
{
  "ids": [ID],
  "fields": ["name", "partner_id", "date_order", "state", "order_line", "amount_untaxed", "amount_tax", "amount_total"]
}

POST /json/2/sale.order.line/read
{
  "ids": [LINE_IDS],
  "fields": ["product_id", "name", "product_uom_qty", "price_unit", "price_subtotal"]
}
```

**Confirm order:**
```json
POST /json/2/sale.order/action_confirm
{ "ids": [ID] }
```
- Show the Confirm button only when state is `draft` or `sent`.
- Show a confirmation dialog first.
- After success, reload the order and the list.

**Test data:** draft orders S00002, S00003, S00004, S00006 exist in the test instance. A `sent` order is S00020.

**Definition of Done:**
- [ ] The list shows Number / Customer / Date / Status
- [ ] Details show products and totals
- [ ] Confirm changes the state to `sale` inside Odoo

---

### Step 9: Offline Handling (bonus)

**Part 1: read cache**
- After a successful customer fetch, save the customers in a Hive box named `customers`.
- If the device is offline or the request fails due to network: show the cached list with an "Offline mode" banner.
- Optional: apply the same idea to Sales Orders.

**Part 2: sync queue for edits**
- When the phone is edited while offline:
  1. Update the local cache immediately.
  2. Add an operation to a Hive box named `pending_ops`: `{ partnerId, field: 'phone', value, timestamp }`.
  3. Show a "Pending sync" indicator on that customer.
- `connectivity_plus` watches the network. When connectivity returns, run the sync:
  - Execute pending operations in order (`res.partner/write`).
  - On success: remove from the queue.
  - On failure: keep it for the next attempt.
- Conflict policy: **last write wins**. Document it in the README.

**Definition of Done:**
- [ ] With airplane mode on, the app opens and shows cached customers
- [ ] A phone edit made offline appears in Odoo after connectivity returns

---

### Step 10: Polish + Delivery

- [ ] Handle all errors (network, 401, timeout) with clear messages
- [ ] Loading / Empty / Error states on every screen
- [ ] Logout works
- [ ] `README.md` containing:
  - Idea and architecture overview
  - How to run: `flutter run --dart-define=ODOO_KEY=...`
  - Why login uses an API Key instead of a password
  - Decisions: JSON-2 as the primary API, offline conflict policy
  - What is done and what is not
- [ ] Clean GitHub repo (no keys or secrets in history)
- [ ] Release APK: `flutter build apk --release`
- [ ] Short demo video or screenshots (optional but valuable)
- [ ] Final check of every requirement in section 1

---

## 6. API Quick Reference

| Operation | Endpoint | Body |
|-----------|----------|------|
| List customers | `res.partner/search_read` | `domain`, `fields`, `limit`, `order` |
| Customer details | `res.partner/read` | `ids`, `fields` |
| Update customer | `res.partner/write` | `ids`, `vals` |
| List orders | `sale.order/search_read` | `domain`, `fields`, `order` |
| Order lines | `sale.order.line/read` | `ids`, `fields` |
| Confirm order | `sale.order/action_confirm` | `ids` |
| Verify user | `res.users/search_read` | `domain`, `fields`, `limit` |

**Always send:** `Authorization: bearer <KEY>`, `X-Odoo-Database: techmates`, `Content-Type: application/json`.

---

## 7. Common Pitfalls

| Problem | Likely cause |
|---------|--------------|
| `401` / `403` | Wrong key, key scope is MCP instead of RPC, or user lacks access rights |
| Empty field is `false` instead of a string | Odoo returns `false` for empty fields; convert to `null` |
| `partner_id` is not a String | Many2one fields come back as `[id, name]` |
| Key stops working | The key expired; check the Expires setting used at creation |

---

## 8. Suggested Timeline (2 days)

**Day 1**
- Steps 4, 5, 6, 7 (Login, customers, details, phone update)

**Day 2**
- Step 8 (Sales Orders + Confirm)
- Step 9 (Offline) if time allows
- Step 10 (README, polish, delivery)

> If time runs short, deliver a fully working build of the core requirements (1 to 5) and state clearly in the README that Offline is partial or not done. A working app beats a complete but crashing one.

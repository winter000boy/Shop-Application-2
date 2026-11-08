# Ajgar Mobile UP — project context

Repair-shop management app for mobile repair shops in India. Flutter app (`mobile/`) + Spring Boot API
(`backend/`), deployed on Render (`render.yaml`, see `DEPLOYMENT.md`). GitHub: `winter000boy/Shop-Application-2`.
The internal code name in packages and docs is still "FixManager" / `repair_shop_app`.

Keep this file current: when you add or change a feature, update its section here in the same PR.

## Architecture in one paragraph

Offline-first. Every screen reads and writes the local Drift SQLite database (`mobile/lib/database/app_database.dart`);
`SyncManager` (`mobile/lib/services/sync_manager.dart`) pushes local changes and pulls server changes in one
`POST /api/v1/orders/sync` call (on start, resume, reconnect, every 5 min, and 2 s after an edit). The server
resolves conflicts last-write-wins on `updatedAt` and keeps tombstones for deletions. State management is Riverpod
(`mobile/lib/shared/providers.dart`). Hive holds preferences and the cached shop profile; session tokens and the
device-secret AES key live in the platform keystore (`flutter_secure_storage`).

## Commands

```bash
cd mobile && dart run build_runner build --delete-conflicting-outputs   # after changing Drift tables
cd mobile && flutter analyze && flutter test
cd mobile && flutter run --dart-define=API_BASE_URL=http://<lan-ip>:8080/api/v1
cd backend && mvn test            # H2 in-memory, Flyway migrations run on startup
```

On a Privacera laptop Maven is routed to the corporate mirror; off VPN use a settings file whose only content is a
`<localRepository>` so Maven Central is used (`mvn -s <file> test`).

## Features

### Authentication & password reset
- Email + password sign-up/sign-in, JWT access token + rotating refresh token (`AuthController`, `AuthService`,
  `mobile/lib/features/auth/`). Several devices can be signed in at once; refresh-token replay revokes all sessions.
- **Forgot password**: `ForgotPasswordScreen` → `POST /auth/forgot-password` emails a 6-digit code (BCrypt-hashed,
  short-lived, attempt-limited; printed in the backend log when no mail server is configured) →
  `POST /auth/reset-password`. Linked from the login screen ("Forgot Password?").
- Signing out wipes all local shop data: orders, job photos (files + rows) and offers (`AuthNotifier.logout`,
  `AppDatabase.clearAllShopData`, `PhotoStore.deleteAll`). The same happens when a *different* shop signs in on the
  device; the same shop signing back in keeps unsynced local edits.

### Home page — all repairing jobs (`mobile/lib/features/dashboard/`)
- `DashboardScreen` is the home: title "All Repairing Jobs", a horizontal row of tiles with live counts —
  **All, Today, Pending, Repaired, Delivered, Cancelled** — then **brand filter chips**, a search box, and the job list.
- Filter logic is pure and unit-tested in `job_filters.dart` (`JobFilters`). "Today" = job *received* today (local
  `createdAt`), regardless of status. Brand chips are computed from the jobs in the selected tile and grouped
  case-insensitively via `Brands.normalize`; jobs with no brand fall under "Other". Search matches customer name,
  mobile, alternate number, IMEI, brand, model and job number.
- Each job (`job_list_card.dart`) shows job number, sync state, photo count, status badge (tap to change status),
  customer, device, problem, estimate, balance due, received date and estimated delivery (red when overdue), with
  Call / WhatsApp / Delete actions. Tap opens the job card for editing.
- The drawer holds New Job Card, Offers, Change Language, Help & Support, Settings, "More Tools" (placeholders for
  future modules: Dealer Repairing, Rough Register, Daily Profit, Sale Request, POS, Old Mobile, Quick Invoice) and
  Sign Out. The old `OrdersListScreen` was removed; the home page replaces it.

### Job card (`mobile/lib/features/repair_orders/presentation/add_order_screen.dart`)
`AddOrderScreen` creates (no `order`) or edits a job card. Sections:
1. **Customer** — name*, mobile number*, alternate contact, address.
2. **Device** — brand* (autocomplete from `core/brands.dart`, free text allowed), model*, IMEI (optional, 15 digits),
   problem*, **device photos** (camera or gallery, up to 6; **at least one required when creating** a job).
3. **Screen lock** — PIN/password and a 3×3 pattern drawer. Both are AES-GCM encrypted at rest on the phone
   (`DeviceSecretCipher`) and on the server, and are wiped automatically once the job is Delivered or Cancelled.
4. **Accessories received** — SIM, memory card, charger, battery, back cover + free-text "other".
5. **Estimate & delivery** — estimate*, advance paid, estimated delivery date, status, received date/time, reminder.
6. **Additional details** — free text (`description` column).
7. **KYC** — ID proof type (Aadhaar, PAN, Voter ID, Driving Licence, Passport, Other) + up to 2 ID photos.
8. **WhatsApp** — "Send WhatsApp Message" (on by default) and email (email is still a mock that only logs).

Data: job card text fields are columns on `Orders` (Drift schema v3) and on `repair_orders` (Flyway
`V2__job_card_fields.sql`): `alternate_number, brand, model, imei, estimated_delivery, accessories_battery,
accessories_other, kyc_doc_type`. They sync like every other order field. `OrdersOperations` (`orders_notifier.dart`)
does create/update/updateStatus/delete; `createOrder`/`updateOrder` return the saved row so the screen can message it.

### Job photos (device condition & KYC) — device-local only
- Table `OrderPhotos` (`id, orderId, kind = device|kyc, filePath, createdAt`); files are copied by `PhotoStore`
  (`mobile/lib/services/photo_store.dart`) into the app's private `documents/job_photos/` folder, downscaled to
  1600 px / quality 75 by `image_picker`.
- **Photos are not uploaded to the server.** They exist only on the phone that took them, are deleted with the job,
  and are wiped on sign-out. Uploading them would need object storage (Render's disk is ephemeral) and a decision on
  storing customer ID documents (privacy/DPDP Act) — not done yet.
- Widget: `shared/widgets/photo_picker_grid.dart` (thumbnails, tap to zoom, remove, add via camera/gallery).
- Permissions: iOS `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` in `Info.plist`.

### WhatsApp messages (`mobile/lib/services/whatsapp_service.dart`)
- Opens WhatsApp via a `https://wa.me/<number>?text=…` link with a pre-filled message; the shop presses Send.
  Nothing is sent automatically and no WhatsApp Business API account is needed.
- Numbers are normalised to digits with the shop's country code for 10-digit local numbers (unit-tested).
- `jobMessage` picks the text by status: received (job no, problem, estimate, advance, expected delivery),
  repaired (ready for pickup, balance due), delivered (thank you), cancelled (please collect). Messages are English.
- Triggered: after saving a new job card or changing its status (when the job's WhatsApp option is on), from the
  WhatsApp button on each job, and for offers (`offerMessage`, no recipient — the user picks a chat/group).
- Android `<queries>` in `AndroidManifest.xml` allow opening https/tel/mailto and WhatsApp packages.

### Language (`mobile/lib/core/l10n/app_strings.dart`, `features/language/`)
- English + the ten most-spoken Indian languages: Hindi, Bengali, Marathi, Telugu, Tamil, Gujarati, Urdu (RTL),
  Kannada, Odia, Malayalam. `LanguageScreen` lists them in their own script; reachable from the home app bar,
  the drawer and Settings. Choice is saved in Hive (`LocalCache.setLanguage`) and applied app-wide at once via
  `localeProvider` → `MaterialApp.locale` (+ `flutter_localizations` for date pickers etc.).
- Strings: add a key to the `S` enum and an entry per language in `_strings`; use `context.tr(S.key)`. Missing
  entries fall back to English. Translated today: home, drawer, job card, job list, offers, help headings, language.
  Not yet translated: login/sign-up, settings form labels, FAQ bodies, WhatsApp message text.
  Translations were machine-authored — have a native speaker review before a wide release.

### Offers (`mobile/lib/features/offers/presentation/offers_screen.dart`)
- Add / edit / delete offers (title*, discount text, details, valid-till date, active switch); expired offers show
  the date in red. Share any offer on WhatsApp.
- Stored in the local `Offers` table only (not synced to the server, wiped on sign-out).

### Help & Support (`mobile/lib/features/help/presentation/help_support_screen.dart`)
- FAQ list plus Call / WhatsApp / Email support and "Report a problem" (email with app version and platform).
- Support contacts come from build-time defines; any left empty is hidden:
  `--dart-define=SUPPORT_PHONE=+91… --dart-define=SUPPORT_WHATSAPP=+91… --dart-define=SUPPORT_EMAIL=…`
  (`core/config/support_config.dart`). **Set these in the APK build** (`.github/workflows/android-apk.yml`) or the
  contact section will not appear.

### Settings (`mobile/lib/features/settings/presentation/settings_screen.dart`)
- Shop profile (saved to the server, `PUT /shop`), dark mode, language (opens `LanguageScreen`), force sync,
  re-download all orders from the server.

### Sync & storage details
- Money is stored in minor units (paise) locally, decimals on the API (`core/money.dart`).
- Local DB schema version: **3** (v2 → v3 adds job card columns, `order_photos`, `offers`; covered by
  `test/database_migration_test.dart`). Server schema: Flyway V1 + V2. Never edit an applied migration.
- `orderFromJson` treats the job card fields as optional so the app still syncs with a server that predates V2.

## Conventions
- Deploy order for schema changes: backend (Flyway migration) first, then the app.
- Keep business logic out of widgets where it can be unit-tested (see `JobFilters`, `WhatsAppService.normalizeNumber`).
- New user-visible text goes through `S` / `context.tr`.

# Flutter Hotel Management System

Flutter application for hotel customers, administrators, and hotel staff.

## Features

- Customer login, registration, room search, room details, booking, PayOS QR payment, promotions, and reviews.
- Administration for staff, customers, rooms, room types, bookings, services, promotions, invoices, and revenue.
- Staff workspace for room information, services, promotions, daily revenue, and ratings.
- Shared API configuration through `ApiEndpoints`.

## Login Roles

- Local demo admin opens `AdminScreen` without a database account.
- Backend users with `is_staff = true` open `StaffHomeScreen`.
- Other password and Google users open the customer home.

Create a local admin configuration from `admin.demo.example.json`, set
`DEMO_ADMIN_PASSWORD`, and keep the resulting `admin.demo.json` untracked.

## API

The application currently uses:

```text
http://54.91.41.3:5000/api
```

## Run

```powershell
flutter pub get
flutter run --dart-define-from-file=admin.demo.json
flutter run -d chrome --web-port 8080
```

For Google login on Flutter Web, add `http://localhost:8080` to the OAuth
client's Authorized JavaScript origins in Google Cloud Console.

## Verify

```powershell
flutter analyze --no-fatal-infos
flutter test --no-pub
flutter build apk --debug --dart-define-from-file=admin.demo.json
```

The Android debug APK is generated at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

# Flutter Hotel Management System

Flutter application for hotel customers and administrators.

## Features

- Customer login, registration, room search, room details, booking, PayOS QR payment, promotions, and reviews.
- Administration for staff, customers, rooms, room types, bookings, services, promotions, invoices, and revenue.
- Shared API configuration through `ApiEndpoints`.

## API

The application currently uses:

```text
http://54.91.41.3:5000/api
```

## Run

```powershell
flutter pub get
flutter run
```

## Verify

```powershell
flutter analyze --no-fatal-infos
flutter test
flutter build apk --debug
```

The Android debug APK is generated at:

```text
build/app/outputs/flutter-apk/app-debug.apk
```

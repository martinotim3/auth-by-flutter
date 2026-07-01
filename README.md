# Flutter Firebase Auth

Flutter app with Firebase email/password authentication, email verification enforcement, and role-based routing (Admin vs User via custom claims).

## Stack

- Flutter 3.x / Dart 3.x
- Firebase Auth — email/password, email verification
- Cloud Firestore — user profiles
- No state management library — plain Dart service classes

## Features

- Register with email/password — sends verification email, rolls back on failure
- Login blocked until email verified — resend verification option
- Forgot password — sends reset email
- Role-based routing — `role: 'admin'` custom claim → AdminHomeScreen, else UserHomeScreen
- Firestore security rules — users read/write own doc only; role field immutable from client

## Project Structure

```
lib/
├── main.dart                        # Firebase init, runApp
├── app.dart                         # MaterialApp + StreamBuilder auth routing
├── firebase_options.dart            # FlutterFire CLI generated
│
├── features/
│   ├── auth/
│   │   ├── auth_service.dart        # register, login, logout, getRole, sendPasswordReset
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   └── widgets/
│   │       ├── auth_button.dart
│   │       └── auth_text_field.dart
│   ├── admin/
│   │   └── admin_home_screen.dart
│   └── user/
│       └── user_home_screen.dart
│
└── shared/
    ├── models/
    │   └── app_user.dart
    └── services/
        └── firestore_service.dart
```

## Setup

**Prerequisites:** Flutter SDK, Firebase project with Email/Password auth and Firestore enabled.

```powershell
flutter pub get
flutterfire configure   # generates lib/firebase_options.dart
flutter run
```

## Running Tests

```powershell
flutter test
```

Tests use `firebase_auth_mocks` and `fake_cloud_firestore` — no emulator required.

## Assigning Admin Role

Custom claims can only be set server-side. Use Firebase Admin SDK:

```js
const admin = require('firebase-admin');
admin.auth().setCustomUserClaims(uid, { role: 'admin' });
```

Or via Firebase Console: Authentication → Users → select user → Edit → Custom claims: `{"role": "admin"}`

New users default to `role: 'user'` (set by Firestore on registration).

## Firestore Security Rules

See `firestore.rules`. Key constraints:
- Users read/write own document only (`request.auth.uid == uid`)
- `create` enforces `role == 'user'` — clients cannot self-assign admin
- `update` blocks changes to the `role` field

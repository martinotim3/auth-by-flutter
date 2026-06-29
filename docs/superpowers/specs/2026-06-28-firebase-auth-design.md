# Firebase Auth — Flutter Design Spec

**Date:** 2026-06-28  
**Stack:** Flutter + Firebase Auth + Firestore + Riverpod (state) + StreamBuilder (routing)

---

## 1. Scope

Email/password authentication with role-based routing (Admin vs User), email verification enforcement, and password reset. No third-party OAuth providers.

---

## 2. Architecture

### Routing Strategy

`MaterialApp` uses a `StreamBuilder` on `FirebaseAuth.instance.authStateChanges()` at the root (`app.dart`):

- **Unauthenticated** → `LoginScreen`
- **Authenticated** → `FutureBuilder(getIdTokenResult())` to read custom claims:
  - `role == "admin"` → `AdminHomeScreen`
  - `role == "user"` → `UserHomeScreen`
  - Email not verified → block, show verification prompt

### Project Structure

```
lib/
├── main.dart                        # Firebase.initializeApp, runApp
├── app.dart                         # MaterialApp + StreamBuilder root
├── firebase_options.dart            # FlutterFire CLI generated
│
├── features/
│   ├── auth/
│   │   ├── screens/
│   │   │   ├── login_screen.dart
│   │   │   ├── register_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   ├── widgets/                 # Shared form fields, auth button
│   │   └── auth_service.dart        # All Firebase Auth calls
│   │
│   ├── admin/
│   │   └── admin_home_screen.dart
│   │
│   └── user/
│       └── user_home_screen.dart
│
└── shared/
    ├── models/
    │   └── app_user.dart            # uid, email, role, displayName, emailVerified
    └── services/
        └── firestore_service.dart   # User doc read/write
```

---

## 3. Data

### Firestore Schema

```
users/{uid}/
  email: string
  role: "admin" | "user"
  displayName: string
  createdAt: timestamp
  emailVerified: boolean
```

### Firebase Custom Claims

Set via Firebase console or Cloud Function triggered on user creation:

```json
{ "role": "admin" }
```

- Claims read via `user.getIdTokenResult()` — server-authoritative, not spoofable client-side
- Cached per token (~1hr expiry); refreshed automatically on next request
- Firestore doc used for display data only (name, profile info, etc.)

### AppUser Model

```dart
class AppUser {
  final String uid;
  final String email;
  final String role;         // sourced from custom claims
  final String displayName;  // sourced from Firestore
  final bool emailVerified;
}
```

### AuthService Responsibilities

| Method | Action |
|---|---|
| `register(email, password)` | Create user → send verification email → write Firestore doc (`role: "user"`) |
| `login(email, password)` | Sign in → check `emailVerified` → block if false |
| `logout()` | `FirebaseAuth.instance.signOut()` |
| `sendPasswordReset(email)` | Firebase built-in reset email |
| `getRole()` | `getIdTokenResult().claims['role']` |

---

## 4. Screens & UX

### LoginScreen
- Fields: email, password
- Actions: Login, "Forgot password?" (→ ForgotPasswordScreen), "Register" (→ RegisterScreen)
- Errors handled: `wrong-password`, `user-not-found`, `email-not-verified`

### RegisterScreen
- Fields: email, password, confirm password
- On submit: register → show "verify your email" dialog → navigate back to Login
- Errors handled: `email-already-in-use`, `weak-password`

### ForgotPasswordScreen
- Field: email
- On submit: `sendPasswordReset` → success SnackBar → back to Login
- Errors handled: `user-not-found`

### AdminHomeScreen
- Placeholder content + logout button

### UserHomeScreen
- Placeholder content + logout button

---

## 5. Error Handling

- All `FirebaseAuthException` error codes mapped to user-friendly strings inside `AuthService`
- Errors surfaced via `SnackBar` on each auth screen
- Per-button loading state: disable button + show `CircularProgressIndicator` during async ops
- Email not verified: block login, show "Check your inbox" message with "Resend verification" option

---

## 6. Security

- Email verification enforced before any authenticated screen is accessible
- Roles sourced from custom claims (server-side) — not from Firestore or client state
- Firestore security rules:
  ```
  match /users/{uid} {
    allow read, write: if request.auth != null && request.auth.uid == uid;
  }
  ```
- Admin role assignment done outside the app (Firebase console or Cloud Function) — no client-side role elevation

---

## 7. Dependencies

```yaml
dependencies:
  firebase_core: ^latest
  firebase_auth: ^latest
  cloud_firestore: ^latest
  flutter_riverpod: ^latest
  go_router: ^latest   # optional, not used for routing but useful for named routes within role screens
```

> Note: Routing between auth states uses `StreamBuilder`, not GoRouter. GoRouter can be added later for in-app navigation within role screens.

---

## 8. Out of Scope

- Third-party OAuth (Google, Apple)
- Phone/OTP authentication
- Anonymous auth
- Multi-factor authentication
- User profile editing screen
- Admin dashboard functionality (placeholder only)

# Sprint 13 runtime matrix

The following must be executed against the Firebase Emulator Suite before production configuration is accepted:

| Case | Expected |
|---|---|
| Register valid email/password | Auth user created |
| Sign in / sign out | Auth state changes and session restores |
| Unauthenticated Firestore read | Denied |
| User A reads User B | Denied |
| Owner valid item CRUD | Allowed |
| Invalid mode/status | Denied |

This file is a test contract only; it does not access production Firebase.

# Firebase Emulator smoke plan

Run against `firebase/firebase.json` Emulator Suite before enabling sync:

- unauthenticated read/write denied
- user A cannot read/write user B
- owner can CRUD valid items
- invalid `mode` or `status` rejected
- preferences remain user-scoped

This plan is intentionally emulator-only; no production Firestore data is modified.

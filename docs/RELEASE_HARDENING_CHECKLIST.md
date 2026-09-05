# Release hardening checklist

Sprint 4 adds a value-safe environment validator and records the final verification contract.

Before a release-like build:

1. Supply `FIREBASE_PROJECT_ID`, `RAWG_API_KEY` and `GOOGLE_BOOKS_API_KEY` through CI/environment only.
2. Supply Android signing secrets and generate `key.properties` only in CI.
3. Run Firebase Auth/Firestore Emulator rules tests (unauthenticated, cross-user, invalid enum and owner CRUD).
4. Run auth, relaunch/persistence and controlled network-failure smoke flows on a release-like build.
5. Verify App Check configuration and privacy/Data Safety declarations.
6. Confirm Firebase remains Spark; do not enable Blaze or deploy Cloud Functions.

The validator reports missing variable names only and never prints values.

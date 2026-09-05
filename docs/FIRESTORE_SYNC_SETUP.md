# Firestore sync setup

Sprint 3 adds the user-scoped Firestore adapter and sync engine. Drift remains the local source of truth; writes should be committed locally first and represented as outbox operations before remote application.

Remote paths are restricted to `users/{uid}/items/{itemId}`. The existing rules enforce authentication, owner access and allowed mode/status values. Retries and conflict policy must be driven by the Drift outbox and tested against the Firebase Emulator before enabling production sync.

Required next verification (not performed automatically): Auth + Firestore Emulator integration, reconnect retry, duplicate operation idempotency, tombstone deletes and cross-user rules tests. No production data was accessed.

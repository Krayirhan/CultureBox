# Backend release gate

The backend is release-ready only when all of the following are evidenced:

- Drift is the active local source of truth and every mutation creates an outbox operation.
- Firebase Auth is initialized with environment config; guest mode remains local-only.
- Firestore Emulator rules tests pass for unauthenticated, cross-user, invalid enum and owner CRUD cases.
- Outbox drain succeeds after reconnect and removes only successfully applied operations.
- Failed operations remain queued after bounded retries; no infinite retry loop occurs.
- Production values come from CI/environment; no secret is committed.
- Firebase remains on Spark; no Cloud Functions or billing-dependent path exists.

This checklist is a gate, not a claim that the unavailable production credentials have been configured locally.

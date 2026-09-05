# Offline sync runbook

Local mutations are committed to Drift first and represented in the outbox. `SyncEngine.drain` applies each operation with bounded retries and removes it only after success. A failed operation remains queued for the next reconnect attempt.

Conflict policy: the explicitly newer user mutation wins; equal timestamps prefer local data deterministically. Provider metadata must not overwrite user status/progress.

Required release verification: disable emulator network, add/update an item, force-stop/relaunch, restore network, drain the outbox, and verify the owner-scoped Firestore document in the Emulator UI. This runbook is emulator-only and does not touch production.

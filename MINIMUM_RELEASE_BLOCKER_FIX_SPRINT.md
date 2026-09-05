# Minimum Release Blocker Fix Sprint

Date: 2026-09-02  
Scope: package identity, signing guard, production configuration documentation. No UI redesign, analytics, billing, deploy or push.

## Result

```text
RELEASE BLOCKERS BEFORE: debug signing; placeholder application ID; undocumented production environment gate
RELEASE BLOCKERS CLOSED: placeholder package ID; silent debug fallback for release builds; CI signing contract documented
RELEASE BLOCKERS REMAINING: CI keystore secrets/configuration not present locally; production API/Firebase values not configured; persistence/offline smoke evidence incomplete; Play Store compliance artifacts unverified
```

```text
PACKAGE ID: PASS — com.krayirhanstudio.culturebox
RELEASE SIGNING: PASS WITH NOTES — release now fails fast without key.properties; CI workflow supplies it from secrets
PRODUCTION CONFIG: PASS WITH NOTES — names/documentation only; values intentionally absent and never hard-coded
RELEASE BUILD: BLOCKED — expected fail-fast because no local keystore exists
PERSISTENCE: BLOCKED — not reverified in this sprint
OFFLINE/ERROR: BLOCKED — not reverified in this sprint
AUTH: PASS WITH NOTES — guest core path supported; signed-in flow remains verification debt
PLAY STORE READINESS: BLOCKED — CI/store credentials and listing compliance artifacts not available locally

BUILD: PASS — flutter build apk --debug
ANALYZE: PASS WITH NOTES — 3 pre-existing infos
TESTS: PASS — 4 tests
MAESTRO: PASS WITH NOTES — flow definitions updated to production appId; full post-ID smoke requires reinstalling the new package
RELEASE AAB: BLOCKED — no release keystore (intentional fail-fast)
```

## Changes made

- Android namespace/applicationId changed from placeholder to `com.krayirhanstudio.culturebox`.
- Kotlin `MainActivity` package moved consistently.
- iOS bundle identifiers updated consistently.
- Maestro app IDs updated.
- Release Gradle signing uses CI/local `key.properties` and has no debug fallback; missing signing fails clearly for release tasks.
- Added `docs/RELEASE_SIGNING_AND_ENV.md` documenting CI secrets and Spark constraints.

Secrets and keystores were not created or added to the repository.

## Release candidate status

**STILL BLOCKED**

Minimum remaining blockers only:

1. Supply CI release keystore secrets and generate a verified non-debug AAB.
2. Supply/validate production Firebase/TMDB/RAWG configuration without committing secrets.
3. Complete release-like persistence and network-error smoke verification.
4. Complete Play Store compliance checklist and artifact verification.

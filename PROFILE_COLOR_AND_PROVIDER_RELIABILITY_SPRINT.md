# Profile Color and Provider Reliability Sprint

Date: 2026-09-04  
Status: READY  
Scope: mobile profile visual language and repeatable provider-enabled debug builds. No secret values are stored in this document or the repository.

## Sprint outcome

Create one coherent visual hierarchy across İzle / Oyna / Oku / Profil while making local debug builds reliably include Firebase, RAWG, and Google Books configuration.

## Problems confirmed

1. Mode colors currently control chips, card outlines, CTAs, FABs, and glows at once. This makes lime, cyan, and terracotta compete as primary colors.
2. Profile has a useful community surface, but it needs to remain a local semantic treatment rather than a fourth global accent system.
3. Provider keys use compile-time Dart defines. A build made without `.env.local` removes RAWG and Google Books support even if the local environment has valid keys.
4. Google Books keys restricted to Android apps also require the debug signing SHA-1 to be supplied as `ANDROID_CERT_SHA1` in local debug builds.

## Non-goals

- Do not commit API keys, Firebase identifiers, SHA-1 values, or keystores.
- Do not alter provider contracts, Firestore rules, or content data models.
- Do not change the existing İzle / Oyna / Oku information architecture.
- Do not publish an AAB or change CI secrets in this sprint.

## Work items

### P-01 — Define semantic color roles

- Introduce tokens for background, surface, card, ink, muted text, border, brand action, destructive action, and community surface.
- Keep the brand action color constant across navigation, CTA buttons, and FABs.
- Use mode colors only for compact category cues such as an icon, label, or small chip; they must not recolor every CTA, border, and glow.

Acceptance:

- A selected bottom-nav item, primary CTA, and FAB share one brand-action token.
- Card outlines remain neutral on all three modes.
- Community is the only view allowed to use community-surface tokens.

### P-02 — Reduce mode-color saturation

- Replace full mode-colored cards, large glows, and colored card borders with neutral card chrome.
- Retain a restrained mode identifier near the selected İzle / Oyna / Oku control.
- Remove competing colored glows from the selected chip and FAB.

Acceptance:

- No home mode shows more than one strong mode-colored element above the fold.
- Posters remain the dominant color source in content cards.
- Text and primary actions remain readable against all dark surfaces.

### P-03 — Complete profile color treatment

- Keep the account card neutral.
- Keep the community card as a low-saturation sage surface, with warm-ivory iconography and text.
- Use the brand-action token for enabled switches, rather than a separate neon or category color.

Acceptance:

- Profile uses three color layers only: neutral chrome, brand action, community surface.
- Username, visibility states, and destructive action remain visually distinct.

### P-04 — Make provider-enabled builds the default local path

- Update the local debug build/run workflow to always use root `.env.local` when it exists.
- Compute and pass the debug signing SHA-1 for Android-restricted Google Books keys.
- Add a safe preflight that reports only whether required keys are present, never their values.
- Document the exact provider-enabled command in the mobile README.

Acceptance:

- `RAWG_API_KEY` and `GOOGLE_BOOKS_API_KEY` are present in the compiled debug build.
- Oyun shows RAWG results on the emulator.
- Oku shows Google Books results on the emulator.
- Missing configuration fails with an actionable message before installation.

### P-05 — Verification and regression evidence

- Run Flutter analyzer and focused widget tests.
- Capture evidence for İzle, Oyna, Oku, and Profil on the same emulator build.
- Confirm missing-key states only occur when configuration is intentionally omitted.

Acceptance:

- No analyzer errors.
- All three content modes load at least one provider result.
- Profile username and community card render after authenticated startup.

## Order of execution

1. P-04 provider build guard — protects working content before UI work.
2. P-01 color roles — establishes the tokens.
3. P-02 home mode hierarchy.
4. P-03 profile refinement.
5. P-05 verification evidence.

## Definition of done

- Providers work in a provider-enabled debug APK without exposing secrets.
- The UI has one global brand-action color, neutral card chrome, restrained mode cues, and a local community treatment.
- The APK is installed and checked on `emulator-5554` using the same provider-enabled build command documented for developers.

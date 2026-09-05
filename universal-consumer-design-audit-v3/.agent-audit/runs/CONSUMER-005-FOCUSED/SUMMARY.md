# CultureBox — Focused Consumer Design Audit v3

```text
MODE: FOCUSED
FOCUS: Ana Sayfa
AGENT: Codex
DATE: 2026-09-02
RUBRIC: CONSUMER-RUBRIC-v3.0
DEVICE: Pixel_9_Pro / emulator-5554
RUNTIME TOOL: Maestro CLI 2.9.0 + adb
RUNTIME EVIDENCE: VERIFIED
CONFIDENCE: MEDIUM
```

## Runtime route

Cold launch → onboarding → İzle selection → notification step → guest entry → Ana Sayfa.
Maestro `onboarding_guest.yaml` completed its Home assertions. A focused Home screenshot and UI hierarchy were captured in `evidence/`.

## Focused scorecard — Ana Sayfa only

| Dimension | Score |
|---|---:|
| First impression & product clarity | 9/10 |
| Visual hierarchy & readability | 8/10 |
| User intent clarity | 9/10 |
| Target-user fit | 8/10 |
| Interaction & micro-UX | 7/10 |
| Copy | 8/10 |
| Spacing & layout | 8/10 |
| Typography | 8/10 |
| Accessibility in real use | 7/10 |
| Consistency | 8/10 |
| AI/template risk (separate) | 25/100 |

**Focused Home quality:** **8.0/10**

## What works

- “Sırada ne var?” is an immediately understandable primary question for the decision-fatigued target user.
- One hero item creates a clear attention order and reduces choice overload.
- İzle/Oyna/Oku/Git context chips make the product’s scope memorable.
- “Başla” and “Değiştir” are concrete next actions; progress cards communicate return value.
- Olive/cream palette and serif display typography provide a recognizable, calm identity.

## Findings

### H-001
SCREEN: Ana Sayfa
SEVERITY: P2 Medium
OBSERVATION: Home is vertically dense; hero, continuing cards, ranked row and resurfaced items compete below the first viewport.
EVIDENCE: `evidence/home.png`.
USER IMPACT: The first action is clear, but secondary content can increase scroll/choice load.
TARGET USER IMPACT: Decision-fatigued users may defer action after the hero.
WHY IT MATTERS: The product promise is one clear next choice.
RECOMMENDED FIX: Keep the hero dominant and validate section order/visible count with user sessions before changing layout.
CONFIDENCE: MEDIUM.

### H-002
SCREEN: Ana Sayfa
SEVERITY: P2 Medium
OBSERVATION: Search/profile controls are icon-led; their intent depends on tooltip/semantics rather than visible text.
EVIDENCE: `evidence/home-hierarchy.xml`; runtime screenshot.
USER IMPACT: First-time users may not immediately know which icon opens search versus profile.
TARGET USER IMPACT: General consumers need low-explanation discoverability.
WHY IT MATTERS: Search is the primary route to adding new content.
RECOMMENDED FIX: Validate icon comprehension; retain stable accessibility labels.
CONFIDENCE: MEDIUM.

### H-003
SCREEN: Ana Sayfa
SEVERITY: P3 Polish
OBSERVATION: Some horizontal cards truncate titles on narrow viewport widths.
EVIDENCE: runtime screenshot of populated Home.
USER IMPACT: Minor scan friction; content remains identifiable in most cases.
TARGET USER IMPACT: Lower confidence when choosing among saved items.
WHY IT MATTERS: Title recognition supports quick return.
RECOMMENDED FIX: Test text scale/narrow widths and adjust only if truncation harms recognition.
CONFIDENCE: MEDIUM.

## Not assessed in this focused run

Search/detail/Listem/Profile behavior, offline/error states, relaunch persistence and global app quality are outside this focus and receive no new global score.

## Verdict

```text
STRONG CORE HOME — clear next action and distinctive identity; secondary density and icon discoverability need user validation.
```

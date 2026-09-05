# Universal Consumer Audit Workflow

## Phase 0 — Preflight

Kaydet:

```text
MODE: BASELINE | REAUDIT | FOCUSED
AGENT:
DATE:
REVISION:
WORKING TREE:
APP ID:
PLATFORM:
DEVICE:
RUNTIME TOOL:
FIGMA:
RUBRIC: CONSUMER-RUBRIC-v3.0
```

Doğrula:
- PRODUCT_PROFILE
- current revision
- emulator/device
- runtime automation
- previous compatible audit
- varsa Figma

---

## Phase 1 — Product Understanding

Ana soru:

> Genel halk sever mi?

değil:

> Tanımlanmış hedef kullanıcı ürünü anlayabilir, güvenebilir, kullanabilir ve yeniden kullanmak ister mi?

PRODUCT_PROFILE'dan:
- target
- promise
- core journeys
- desired emotions
- forbidden emotions
- brand constraints

çıkar.

---

## Phase 2 — Runtime Baseline

Mümkünse gerçek runtime:

1. cold launch
2. first-time state
3. onboarding
4. first useful action
5. primary core flow
6. repeat action
7. populated state
8. navigation/back
9. keyboard/input
10. scroll/gesture
11. relaunch/state restore
12. relevant error/offline state

Screenshot sadece meaningful states'te alınır.

Örnek:

```text
01-launch.png
02-onboarding.png
03-home-empty.png
04-first-action.png
05-home-populated.png
06-core-flow.png
07-return-state.png
```

---

## Phase 3 — Journey Evaluation

Her journey:

```text
GOAL:
EXPECTED:
OBSERVED:
FRICTION:
CONFUSION:
POSITIVE:
EMOTIONAL EFFECT:
EVIDENCE:
VERDICT:
```

Mümkünse gerçekten execute et.

---

## Phase 4 — Consumer Score

`.agent-audit/RUBRIC.md` kullan.

Çıktı:

```text
CONSUMER APPEAL: XX/100
AI/TEMPLATE RISK: XX/100
TARGET FIT: STRONG | MEDIUM | WEAK
CONFIDENCE: HIGH | MEDIUM | LOW
RUNTIME EVIDENCE: VERIFIED | PARTIAL | BLOCKED
```

AI/template skoru actual AI detection değildir.

---

## Phase 5 — Figma Drift

Figma/source design varsa:

```text
INTENDED
OBSERVED
DELTA
USER IMPACT
```

kontrol et.

Figma otomatik olarak “iyi UX” kabul edilmez.
Sadece intended source'tur.

---

## Phase 6 — External Evidence

Sadece gerektiğinde:

- competitor conventions
- store reviews
- Reddit/community
- product analytics provided by user

Research output'u şişirmek için gereksiz kaynak toplama.

---

## Phase 7 — Findings

Severity:

- P0 Critical
- P1 High
- P2 Medium
- P3 Polish

Her finding:

```text
ID:
SCREEN:
SEVERITY:
OBSERVATION:
EVIDENCE:
USER IMPACT:
TARGET USER IMPACT:
WHY IT MATTERS:
RECOMMENDED FIX:
CONFIDENCE:
```

---

## Phase 8 — Audit-only default

Varsayılan audit source code değiştirmez.

Önce rapor +:

```text
TOP 5 HIGHEST-IMPACT CHANGES
```

---

## Phase 9 — Fix

Kullanıcı açıkça isterse:

```text
audit
→ fix plan
→ implementation
→ runtime verification
→ re-audit
```

---

## Phase 10 — Re-audit

Karşılaştırılabilirlik için mümkünse aynı:
- rubric version
- device class
- clean-state
- core journeys
- evidence points

kullan.

5+ score delta concrete evidence ister.

---

## Phase 11 — Persist history

Yeni run:

```text
.agent-audit/runs/
└─ CONSUMER-00X-BASELINE|REAUDIT|FOCUSED/
   ├─ SUMMARY.md
   └─ evidence/
```

Update:
- `CURRENT_CONSUMER_STATE.md`
- `RUN_REGISTRY.md`

Eski run overwrite edilmez.

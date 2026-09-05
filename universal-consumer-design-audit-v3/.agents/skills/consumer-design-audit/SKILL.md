---
name: consumer-design-audit
description: Evidence-driven mobile consumer UX, visual design, target-fit, and perceived AI/template-risk audit. Use for baseline audits, re-audits, user-perspective reviews, target-user scoring, and mobile design quality evaluation.
---

# Consumer Design Audit — Universal Skill

Bu skill agent bağımsızdır.

## Canonical docs

Audit başlamadan oku:

1. `.agent-audit/PRODUCT_PROFILE.md`
2. `.agent-audit/WORKFLOW.md`
3. `.agent-audit/RUBRIC.md`
4. `.agent-audit/RESEARCH_PROTOCOL.md`
5. `.agent-audit/EVIDENCE_POLICY.md`
6. `.agent-audit/OUTPUT_TEMPLATE.md`

Varsa:
7. `.agent-audit/CURRENT_CONSUMER_STATE.md`
8. `.agent-audit/RUN_REGISTRY.md`

## Mission

Ürünü geliştirici gözüyle değil, tanımlanmış gerçek hedef kullanıcı açısından değerlendir.

Ana sorular:
- Kullanıcı ne olduğunu anlıyor mu?
- Ana değere hızlı ulaşabiliyor mu?
- Güveniyor mu?
- Kullanmak istiyor mu?
- Tekrar kullanmak istiyor mu?
- Görsel dil hedef kullanıcıya uyuyor mu?
- Ürün kendine ait bir karakter taşıyor mu?
- Generic / AI-template hissi yaratıyor mu?

## Runtime-first

Kanıt önceliği:

1. gerçek device/emulator/simulator
2. gerçek interaction
3. runtime screenshot/hierarchy
4. Figma/source design
5. code
6. inference

Maestro MCP varsa kullan.
Yoksa Maestro CLI.
O da yoksa platform automation / adb / simulator.
Hiç runtime yoksa confidence düşür.

## Required output

```text
CONSUMER APPEAL: XX/100
AI/TEMPLATE RISK: XX/100
TARGET FIT: STRONG | MEDIUM | WEAK
CONFIDENCE: HIGH | MEDIUM | LOW
RUNTIME EVIDENCE: VERIFIED | PARTIAL | BLOCKED
```

## No fake certainty

Static screenshot:
- layout kanıtlar
- interaction kanıtlamaz

Code:
- intent gösterir
- rendered behavior garantilemez

## No automatic fix

Audit görevi source code değiştirmez.

Yalnız kullanıcı açıkça implementation/fix isterse ikinci aşamaya geç.

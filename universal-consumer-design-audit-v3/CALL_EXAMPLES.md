# Agent Call Examples

## Baseline

```text
Bu uygulamaya consumer-design-audit v3 ile tam BASELINE audit yap.

Kurallar:
- `.agent-audit/PRODUCT_PROFILE.md` oku.
- Gerçek emulator/device varsa Maestro ile kullan.
- Core journeys'i gerçekten çalıştır.
- Screenshot/hierarchy kanıtı topla.
- CONSUMER-RUBRIC-v3.0 ile puanla.
- AI/template risk'i ayrı puanla.
- Koda dokunma.
- Audit history'yi kaydet.
```

## Re-audit

```text
consumer-design-audit REAUDIT yap.

Son compatible baseline'ı RUN_REGISTRY'den bul.
Aynı rubric ve mümkünse aynı device/journey setini kullan.
Önceki bulguların hangilerinin gerçekten kapandığını kanıtla.
Score delta >=5 ise somut evidence ver.
Koda dokunma.
```

## Focused screen audit

```text
consumer-design-audit FOCUSED mode.

Sadece Bugün ekranını ve add-task journey'sini değerlendir.
Target user fit, hierarchy, micro-UX ve AI/template risk'e odaklan.
Gerçek runtime varsa Maestro kullan.
Genel uygulamaya ait skor uydurma.
```

## Fix after approval

```text
Son consumer audit'teki P1 ve seçili P2 sorunları için implementation plan hazırla.
Henüz kod değiştirme.
Dosya bazlı fix plan + doğrulama planı ver.
```

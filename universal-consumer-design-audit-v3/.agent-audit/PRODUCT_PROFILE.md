# PRODUCT PROFILE — CultureBox

## Identity

**Product name:** CultureBox (SUPPORTED: `MaterialApp.title`, docs)
**Platform:** Android Flutter app; iOS project scaffold also present (SUPPORTED)
**Category:** personal culture/content backlog and “what next” tracker (INFERRED from docs/runtime)
**Package / Bundle ID:** `com.example.mobile` (VERIFIED: Android Gradle + runtime)
**Current stage:** MVP/prototype (SUPPORTED: profile copy and demo catalog)

## Core Promise

> Kültür içeriklerini (İzle/Oyna/Oku/Git) tek yerde biriktirip kullanıcının geri dönmesini ve sıradaki seçimini kolaylaştırmak. (SUPPORTED/INFERRED)

## Primary Target User

**Who:** Kültür içeriği biriktiren ve karar yorgunluğu yaşayan kullanıcı. (SUPPORTED: PERSONAS_JTBD)
**Situation:** Birçok içerik/aktiviteyi kaydediyor, sonra geri dönmek istiyor. (SUPPORTED)
**Main need:** Hızlı kaydetmek, ilerlemeyi görmek, tek net sıradaki seçimi bulmak. (SUPPORTED)
**Experience level:** Genel tüketici; teknik beceri gerektirmemeli. (INFERRED)

## Secondary Target User

Optional.

## Problems To Solve

1. Kaydedilen içeriklere geri dönememe.
2. Yarım kalanları ve sıradaki seçimi tek yerde görememe.
3. İzle/oyna/oku/git listelerini dağınık tutma.

## Primary User Goal

> Hesap açmadan bile bir içeriği bulup listesine eklemek ve daha sonra kaldığı yerden devam etmek. (INFERRED from runtime/core flows)

## Product / Business Goal

> Kullanıcının kültür tüketimindeki geri dönüş oranını artırmak; sosyal feed veya AI öneri motoru değil. (SUPPORTED: PRODUCT.md)

## Desired Emotional Experience

- sakin ve kontrol sahibi
- meraklı
- suçlanmadan ilerleyen

## Must NOT Feel

- 
- 
- 

## Product Personality

```text
sakin, kişisel, kültür odaklı, yön gösteren; dashboard veya sosyal feed gibi hissettirmemeli.
```

## Core Journeys

### J1
Name: İlk kullanım → kategori → misafir → Home
Success definition: Hesapsız şekilde yararlı ana ekrana ulaşmak.

### J2
Name: Search → detail → save
Success definition: İçeriği bulup detayını görerek listeye eklemek.

### J3
Name: Queue → start → progress → complete
Success definition: Sıradakini başlatmak ve ilerlemeyi güncellemek.

## Critical Screens

- Onboarding / GuestEntry
- Home (“Sırada ne var?”)
- Search / results / detail
- Listem
- Profil / settings

## Critical States

- first launch
- empty
- populated
- loading
- success
- error
- offline, if relevant

## Accessibility Needs

Metin okunabilirliği, yeterli dokunma hedefi, anlamlı Semantics labels, renk dışında durum göstergeleri. Runtime semantics/reader kapsamı henüz tam doğrulanmadı.

## Visual / Brand Constraints

- Flutter Material 3, özel zeytin/kremsi renk dili ve serif başlıklar (SUPPORTED: runtime/code)
- tek hero + sınırlı devam edenler; kullanıcıyı suçlayan copy yok (SUPPORTED: UX_SPEC)

## Known Competitors

1.
2.
3.

## Figma Source

URL / none: none found in repository (UNKNOWN)

## Audit Device Preference

Primary: Pixel_9_Pro Android emulator
Secondary: unknown

## Notes

Evidence sources: CultureBox `docs/PRODUCT.md`, `PERSONAS_JTBD.md`, `UX_SPEC.md`, `USER_FLOWS.md`, Android manifest/Gradle, Flutter runtime and Maestro flow execution. Claims not marked VERIFIED are supported or inferred.

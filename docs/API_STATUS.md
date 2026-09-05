# CultureBox API durumu (2026-09-03)

## Kaynaklar

- **TVMaze:** İzle arama ve keşif için kullanılan public, anahtarsız REST kaynağıdır; Türkçe özet garantisi yoktur.
- **RAWG:** Key gerektirir. Ücretsiz kullanım attribution şartlarıyla mümkündür; mevcut `RAWG_API_KEY` yerel environment'tadır.
- **Google Books:** Volumes API kullanılmaktadır; kitap açıklamaları kaynağın dilinde gelir ve günlük ~1000 istek quota'sı uygulanır. Konu (`subject:`) etiketleri yalnızca İngilizce indekslendiği için `langRestrict=tr` kullanılmaz; Türkçe kitaplar sonuç sıralamasında öne alınır. Anahtar Google Cloud Console'da "Android apps" ile kısıtlıysa (mevcut proje anahtarı böyledir), istek `X-Android-Package`/`X-Android-Cert` başlıklarını taşımazsa `403 API_KEY_ANDROID_APP_BLOCKED` döner — bkz. aşağıdaki "Android kısıtlı anahtarlar".

### Android kısıtlı anahtarlar

Google Cloud Console'da bir API anahtarı "Android apps" ile kısıtlandığında, istek yalnızca imzalayan sertifikanın SHA-1'ini `X-Android-Cert` başlığında taşıyorsa kabul edilir (normalde bunu Play Services SDK'sı ekler; düz `http` paketi eklemez). `content_providers.dart` bu başlıkları `ANDROID_CERT_SHA1` / `ANDROID_PACKAGE_NAME` dart-define'larından okuyup Google Books isteğine ekler:

- Yerel (`scripts/run-mobile.ps1`, debug run): debug keystore'un SHA-1'i otomatik hesaplanıp geçirilir.
- CI debug build (`android-build.yml`): debug keystore build öncesi oluşturulup SHA-1'i çıkarılır.
- CI release build (`release.yml`): upload keystore'un SHA-1'i çıkarılır.

Google Cloud Console'daki anahtarın "Application restrictions" listesine hem debug makinelerin hem de upload keystore'un SHA-1 + paket adı (`com.krayirhanstudio.culturebox`) kombinasyonunun eklenmiş olması gerekir; aksi halde o ortamdan gelen istekler yine reddedilir.

## Anahtarların build'e geçirilmesi

`RAWG_API_KEY` ve `GOOGLE_BOOKS_API_KEY` kod içinde `String.fromEnvironment` ile okunur; bu
**derleme zamanı** bir değerdir ve işletim sistemi environment'ından ya da `.env.local`'dan
otomatik okunmaz. Anahtar geçirilmeyen bir build'de Oyna ve Oku modları çalışmaz.

- Yerel: `scripts/run-mobile.ps1` (veya `flutter run --dart-define-from-file=.env.local`)
- Test: `scripts/run-tests.ps1` / `scripts/run-checks.ps1` aynı dosyayı geçirir
- CI: `.github/workflows/*.yml` secret'lardan `dart-defines.env` üretip
  `--dart-define-from-file` ile geçirir

## CultureBox bağlantısı

`apps/mobile/lib/data/content_providers.dart` provider soyutlamasını kullanır. İzle için TVMaze, oyunlar için RAWG, kitaplar için Google Books kullanılır. Secret değerleri repository'ye yazılmaz.

## Eksikler / manuel adımlar

1. RAWG attribution metni ürün içinde görünür hale getirilmeli.
2. TVMaze ve RAWG açıklamaları Türkçe değilse UI bunu açıkça belirtmeli; uydurma çeviri yapılmamalı.
4. `RAWG_API_KEY` ve `GOOGLE_BOOKS_API_KEY` GitHub Secrets'a eklenmeli; release workflow bunları zorunlu tutar.

Kaynaklar: [TVMaze API](https://www.tvmaze.com/api), [RAWG API terms](https://rawg.io/tos_api), [Google Books volumes](https://developers.google.com/books/docs/v1/reference/volumes/list).

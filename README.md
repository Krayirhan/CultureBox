<div align="center">

# 🌍 CultureBox

### Film, Dizi, Oyun ve Kitaplarını Tek Yerde Takip Et — Flutter

*Offline-first Drift + Firebase senkronizasyonu · Sosyal profil ve inceleme*

[![Flutter](https://img.shields.io/badge/Flutter-Dart-02569B?style=flat-square&logo=flutter&logoColor=white)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Auth%20%2B%20Firestore-FFCA28?style=flat-square&logo=firebase&logoColor=black)](https://firebase.google.com)
[![Drift](https://img.shields.io/badge/Drift-Offline--first-4285F4?style=flat-square)](https://drift.simonbinder.eu)
[![Riverpod](https://img.shields.io/badge/State-Riverpod-1B1B1B?style=flat-square)](https://riverpod.dev)

</div>

---

Kullanıcının izlediği filmleri/dizileri, oynadığı oyunları ve okuduğu kitapları tek bir kütüphanede toplayıp puanlayabildiği, inceleme yazabildiği ve herkese açık bir profil üzerinden paylaşabildiği bir Flutter uygulaması. Yerelde **Drift** (SQLite) ile tamamen offline çalışır; **Firebase** (Auth + Firestore) ile hesap ve sosyal özellikler senkronize olur.

## ✨ Özellikler

| Ekran | Açıklama |
|---|---|
| `OnboardingPage` | İlk açılış tanıtımı |
| `AuthPage` / `GuestEntryPage` | Google ile giriş veya misafir modu |
| `HomePage` | Kişisel akış ve öne çıkanlar |
| `SearchPage` | Film / dizi / oyun / kitap kataloğunda arama |
| `LibraryPage` | Kullanıcının kütüphanesi — izlenen, oynanan, okunan içerikler |
| `ProfilePage` / `PublicProfilePage` | Kişisel ve herkese açık profil, incelemeler |

## 🧰 Teknoloji Yığını

Flutter · Dart · Drift (offline-first SQLite) · Firebase Auth · Cloud Firestore · Google Sign-In · Riverpod · ML Kit Translation

## 📁 Proje Yapısı

```
apps/mobile/lib/
├── data/        Drift veritabanı ve repository katmanı
├── models/      catalog · review · public_profile
├── screens/     auth · home · library · search · profile · onboarding
├── shell/       Navigasyon iskeleti
├── state/       Riverpod provider'ları
└── theme/       Tasarım sistemi
```

## 🚀 Geliştirme Ortamı

```bash
cd apps/mobile
flutter pub get
flutter run
```

Provider API anahtarlarıyla (Google Books vb.) yerel debug build almak için repo kökünden:

```powershell
.\scripts\build-mobile-debug.ps1
```

> Bu script kök dizindeki (gitignore'lu) `.env.local` dosyasını okur ve provider anahtarlarını build'e gömer. Anahtar gerektiren sağlayıcı testleri için düz `flutter build apk` yeterli değildir.

---

<div align="center">

**Stack:** Flutter · Dart · Firebase · Drift · Riverpod

</div>

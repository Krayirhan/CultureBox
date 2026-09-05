# Release signing and production environment

Release builds require `apps/mobile/android/key.properties`, generated only in CI from GitHub Secrets. The file and keystore are gitignored. There is no debug-signing fallback for a release task; Gradle fails fast when the file is absent.

Required CI secrets: `ANDROID_KEYSTORE_BASE64`, `ANDROID_KEYSTORE_PASSWORD`, `ANDROID_KEY_ALIAS`, `ANDROID_KEY_PASSWORD`.

Production API/Firebase values are supplied by the CI environment (`RAWG_API_KEY`, `GOOGLE_BOOKS_API_KEY`, `FIREBASE_PROJECT_ID`, and any provider-specific configuration). Never commit values; `.env.example` documents names only. Firebase remains on Spark and no billing change is required.

Production package ID: `com.krayirhanstudio.culturebox`. Version is currently `1.0.0+1` and must be incremented deliberately for each Play upload.

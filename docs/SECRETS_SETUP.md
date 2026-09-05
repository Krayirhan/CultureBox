# Secrets Setup
Never commit Play JSON, keystore, private API keys. GitHub Secrets: PLAY_SERVICE_ACCOUNT_JSON, ANDROID_KEYSTORE_BASE64/PASSWORD/ALIAS/KEY_PASSWORD, RAWG_API_KEY, GOOGLE_BOOKS_API_KEY. RAWG ve Google Books anahtarları build'e `--dart-define-from-file` ile geçirilir (bkz. docs/API_STATUS.md); geçirilmezse Oyna ve Oku modları çalışmaz.

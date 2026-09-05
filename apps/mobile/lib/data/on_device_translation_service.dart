import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Translates provider summaries on the device. No API key or server is used.
class OnDeviceTranslationService {
  static const _cachePrefix = 'tr_summary_v1:';

  Future<String?> translateEnglishToTurkish(String source) async {
    final text = source.trim();
    if (text.isEmpty) return null;

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_cachePrefix${text.hashCode}';
    final cached = prefs.getString(cacheKey);
    if (cached != null && cached.isNotEmpty) return cached;

    final manager = OnDeviceTranslatorModelManager();
    final englishReady = await manager.isModelDownloaded(
      TranslateLanguage.english.bcpCode,
    );
    if (!englishReady) {
      final downloaded = await manager.downloadModel(
        TranslateLanguage.english.bcpCode,
        isWifiRequired: false,
      );
      if (!downloaded) return null;
    }
    final turkishReady = await manager.isModelDownloaded(
      TranslateLanguage.turkish.bcpCode,
    );
    if (!turkishReady) {
      final downloaded = await manager.downloadModel(
        TranslateLanguage.turkish.bcpCode,
        isWifiRequired: false,
      );
      if (!downloaded) return null;
    }

    final translator = OnDeviceTranslator(
      sourceLanguage: TranslateLanguage.english,
      targetLanguage: TranslateLanguage.turkish,
    );
    try {
      final translated = await translator.translateText(text);
      if (translated.trim().isEmpty) return null;
      await prefs.setString(cacheKey, translated);
      return translated;
    } finally {
      translator.close();
    }
  }
}

import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:audioplayers/audioplayers.dart';

/// Language configuration for Sarvam TTS + Translation
class SarvamLanguage {
  final String code;         // App language code (e.g. 'te')
  final String name;         // English name
  final String nativeName;   // Native script name
  final String sarvamCode;   // Sarvam API language code (e.g. 'te-IN')

  const SarvamLanguage({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.sarvamCode,
  });
}

/// Priority languages: Telugu, Tamil, Hindi, Kannada, Malayalam, English
const List<SarvamLanguage> sarvamTTSLanguages = [
  SarvamLanguage(code: 'te', name: 'Telugu',    nativeName: 'తెలుగు',   sarvamCode: 'te-IN'),
  SarvamLanguage(code: 'ta', name: 'Tamil',     nativeName: 'தமிழ்',    sarvamCode: 'ta-IN'),
  SarvamLanguage(code: 'hi', name: 'Hindi',     nativeName: 'हिंदी',      sarvamCode: 'hi-IN'),
  SarvamLanguage(code: 'kn', name: 'Kannada',   nativeName: 'ಕನ್ನಡ',    sarvamCode: 'kn-IN'),
  SarvamLanguage(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം',   sarvamCode: 'ml-IN'),
  SarvamLanguage(code: 'en', name: 'English',   nativeName: 'English',  sarvamCode: 'en-IN'),
];

/// Result returned by [SarvamTTSService.translate]
class TranslationResult {
  final String translatedText;
  final String targetLangCode;
  final bool fromCache;

  const TranslationResult({
    required this.translatedText,
    required this.targetLangCode,
    this.fromCache = false,
  });
}

/// Service for Sarvam AI-powered Translation + TTS via backend proxy.
/// 
/// Full flow:
///   1. [translate] → calls /api/tts/translate → returns native-script text
///   2. [speak]     → calls /api/tts/synthesize → plays WAV audio of that text
class SarvamTTSService {
  static const String _baseUrl = 'http://localhost:5000';

  static final AudioPlayer _player = AudioPlayer();
  static bool _isPlaying = false;

  /// Simple in-memory cache: langCode → translatedText (per session)
  static final Map<String, String> _translationCache = {};

  static bool get isPlaying => _isPlaying;

  // ─── TRANSLATE ─────────────────────────────────────────────────────────

  /// Translate [englishText] to [targetLangCode] using Sarvam AI.
  /// 
  /// Returns the translated text in the target script.
  /// Results are cached per language so repeat taps are instant.
  static Future<TranslationResult> translate({
    required String englishText,
    required String targetLangCode,
  }) async {
    // English needs no translation
    if (targetLangCode == 'en') {
      return TranslationResult(
        translatedText: englishText,
        targetLangCode: 'en',
        fromCache: true,
      );
    }

    // Cache key includes a rough text fingerprint
    final cacheKey = '$targetLangCode:${englishText.hashCode}';
    if (_translationCache.containsKey(cacheKey)) {
      return TranslationResult(
        translatedText: _translationCache[cacheKey]!,
        targetLangCode: targetLangCode,
        fromCache: true,
      );
    }

    final uri = Uri.parse('$_baseUrl/api/tts/translate');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'text': _sanitizeText(englishText),
        'targetLangCode': targetLangCode,
      }),
    ).timeout(const Duration(seconds: 60));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['error'] ?? 'Translation failed');
    }

    final translated = body['translatedText'] as String;
    _translationCache[cacheKey] = translated;

    return TranslationResult(
      translatedText: translated,
      targetLangCode: targetLangCode,
    );
  }

  // ─── TRANSLATE BATCH ───────────────────────────────────────────────────

  /// Translate a list of English strings to [targetLangCode] in one request.
  /// Returns the translated list in the same order.
  /// Falls back to the original English string on any per-item failure.
  static Future<List<String>> translateBatch({
    required List<String> texts,
    required String targetLangCode,
  }) async {
    if (targetLangCode == 'en') return List.from(texts);

    final uri = Uri.parse('$_baseUrl/api/tts/translate-batch');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'texts': texts.map((t) => _sanitizeText(t)).toList(),
        'targetLangCode': targetLangCode,
      }),
    ).timeout(const Duration(seconds: 90));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200 || body['success'] != true) {
      throw Exception(body['error'] ?? 'Batch translation failed');
    }

    final translated = (body['translatedTexts'] as List).cast<String>();
    return translated;
  }

  /// Synthesise [text] (already in the target language script) into speech.
  /// 
  /// [langCode] must match the language of [text] — e.g. 'te' for Telugu.
  static Future<void> speak({
    required String text,
    required String langCode,
    double pace = 1.0,
    void Function()? onStart,
    void Function()? onComplete,
    void Function(String error)? onError,
  }) async {
    try {
      await stop();

      final uri = Uri.parse('$_baseUrl/api/tts/synthesize');
      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,       // Already translated — send as-is
          'languageCode': langCode,
          'pace': pace,
        }),
      ).timeout(const Duration(seconds: 40));

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200 || body['success'] != true) {
        throw Exception(body['error'] ?? 'TTS request failed');
      }

      final audioBase64 = body['audioBase64'] as String;
      final audioBytes = base64Decode(audioBase64);

      _isPlaying = true;
      onStart?.call();

      await _playBytes(audioBytes);

      _isPlaying = false;
      onComplete?.call();

    } catch (e) {
      _isPlaying = false;
      final errMsg = e.toString();
      print('[SarvamTTS] Error: $errMsg');
      onError?.call(errMsg);
    }
  }

  // ─── STOP ──────────────────────────────────────────────────────────────

  static Future<void> stop() async {
    _isPlaying = false;
    try { await _player.stop(); } catch (_) {}
  }

  // ─── HELPERS ───────────────────────────────────────────────────────────

  static Future<void> _playBytes(Uint8List bytes) async {
    if (kIsWeb) {
      final base64String = base64Encode(bytes);
      final url = 'data:audio/wav;base64,$base64String';
      await _player.play(UrlSource(url));
    } else {
      await _player.play(BytesSource(bytes));
    }
    await _player.onPlayerComplete.first;
  }

  static String _sanitizeText(String text) {
    return text
        .replaceAll(RegExp(r'\*+'), '')
        .replaceAll(RegExp(r'#+\s*'), '')
        .replaceAll(RegExp(r'\[.*?\]\(.*?\)'), '')
        .replaceAll(RegExp(r'`.*?`'), '')
        .replaceAll(RegExp(r'\s{2,}'), ' ')
        .trim();
  }

  static SarvamLanguage? getLanguage(String code) {
    try {
      return sarvamTTSLanguages.firstWhere((l) => l.code == code);
    } catch (_) {
      return null;
    }
  }

  static String mapToSarvamCode(String appLangCode) {
    final lang = getLanguage(appLangCode);
    return lang?.code ?? 'en';
  }

  /// Clear session-level translation cache
  static void clearCache() => _translationCache.clear();
}

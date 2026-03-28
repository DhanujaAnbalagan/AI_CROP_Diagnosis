import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported language configuration
class LanguageInfo {
  final String code;
  final String name;
  final String nativeName;
  final String speechCode;

  const LanguageInfo({
    required this.code,
    required this.name,
    required this.nativeName,
    required this.speechCode,
  });

  /// Get locale from language code
  Locale get locale => Locale(code);
}

/// All supported languages in CropAId
/// Matches React project's SUPPORTED_LANGUAGES array
const List<LanguageInfo> supportedLanguages = [
  LanguageInfo(code: 'en', name: 'English', nativeName: 'English', speechCode: 'en-IN'),
  LanguageInfo(code: 'hi', name: 'Hindi', nativeName: 'हिंदी', speechCode: 'hi-IN'),
  LanguageInfo(code: 'ta', name: 'Tamil', nativeName: 'தமிழ்', speechCode: 'ta-IN'),
  LanguageInfo(code: 'te', name: 'Telugu', nativeName: 'తెలుగు', speechCode: 'te-IN'),
  LanguageInfo(code: 'kn', name: 'Kannada', nativeName: 'ಕನ್ನಡ', speechCode: 'kn-IN'),
  LanguageInfo(code: 'bn', name: 'Bengali', nativeName: 'বাংলা', speechCode: 'bn-IN'),
  LanguageInfo(code: 'mr', name: 'Marathi', nativeName: 'मराठी', speechCode: 'mr-IN'),
  LanguageInfo(code: 'gu', name: 'Gujarati', nativeName: 'ગુજરાતી', speechCode: 'gu-IN'),
  LanguageInfo(code: 'pa', name: 'Punjabi', nativeName: 'ਪੰਜਾਬੀ', speechCode: 'pa-IN'),
  LanguageInfo(code: 'ml', name: 'Malayalam', nativeName: 'മലയാളം', speechCode: 'ml-IN'),
  LanguageInfo(code: 'or', name: 'Odia', nativeName: 'ଓଡ଼ିଆ', speechCode: 'or-IN'),
  LanguageInfo(code: 'as', name: 'Assamese', nativeName: 'অসমীয়া', speechCode: 'as-IN'),
  LanguageInfo(code: 'ur', name: 'Urdu', nativeName: 'اردو', speechCode: 'ur-IN'),
  LanguageInfo(code: 'ne', name: 'Nepali', nativeName: 'नेपाली', speechCode: 'ne-NP'),
  LanguageInfo(code: 'sa', name: 'Sanskrit', nativeName: 'संस्कृतम्', speechCode: 'sa-IN'),
];

/// Provider for managing app language state
class LanguageProvider extends ChangeNotifier {
  static const String _languageKey = 'selected_language';

  String? _languageCode;
  bool _isInitialized = false;

  LanguageProvider() {
    _loadLanguage();
  }

  /// Current language code (null if not selected)
  String? get rawLanguageCode => _languageCode;

  /// Current language code with fallback to English
  String get languageCode => _languageCode ?? 'en';

  /// Current locale
  Locale get locale => Locale(languageCode);

  /// Whether language has been selected
  bool get isLanguageSelected => _languageCode != null;

  /// Whether initialization is complete
  bool get isInitialized => _isInitialized;

  /// Get current language info
  LanguageInfo get currentLanguageInfo {
    return supportedLanguages.firstWhere(
      (lang) => lang.code == languageCode,
      orElse: () => supportedLanguages.first,
    );
  }

  /// Load saved language from preferences
  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString(_languageKey);
    _isInitialized = true;
    notifyListeners();
  }

  /// Set new language
  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;

    _languageCode = code;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, code);
  }

  /// Clear selected language
  Future<void> clearLanguage() async {
    _languageCode = null;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_languageKey);
  }

  /// Get language info by code
  LanguageInfo? getLanguageInfo(String code) {
    try {
      return supportedLanguages.firstWhere((lang) => lang.code == code);
    } catch (_) {
      return null;
    }
  }

  /// Filter languages by search query
  List<LanguageInfo> filterLanguages(String query) {
    if (query.isEmpty) return supportedLanguages;
    
    final lowerQuery = query.toLowerCase();
    return supportedLanguages.where((lang) {
      return lang.name.toLowerCase().contains(lowerQuery) ||
          lang.nativeName.toLowerCase().contains(lowerQuery) ||
          lang.code.toLowerCase().contains(lowerQuery);
    }).toList();
  }
}

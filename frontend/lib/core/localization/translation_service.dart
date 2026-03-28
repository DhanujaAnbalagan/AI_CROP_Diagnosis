import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../providers/language_provider.dart';

/// Translation service for loading and accessing translations
class TranslationService {
  final Locale locale;
  late Map<String, dynamic> _translations;
  late Map<String, dynamic> _fallbackTranslations;
  bool _isLoaded = false;

  TranslationService(this.locale);

  /// Load translations from JSON file
  Future<void> loadTranslations() async {
    // Always load English as fallback first
    try {
      final englishJson = await rootBundle.loadString(
        'assets/translations/en.json',
      );
      _fallbackTranslations = json.decode(englishJson) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('Error loading fallback translations: $e');
      _fallbackTranslations = {};
    }

    // Load the selected language
    if (locale.languageCode == 'en') {
      _translations = _fallbackTranslations;
    } else {
      try {
        final jsonString = await rootBundle.loadString(
          'assets/translations/${locale.languageCode}.json',
        );
        _translations = json.decode(jsonString) as Map<String, dynamic>;
      } catch (e) {
        debugPrint('Error loading translations for ${locale.languageCode}: $e');
        // Use English if translation file not found
        _translations = _fallbackTranslations;
      }
    }
    _isLoaded = true;
  }

  /// Translate a key (supports nested keys like 'homeView.greeting')
  /// Falls back to English if key not found in current language
  String translate(String key) {
    if (!_isLoaded) return key;

    // Try to get from current language
    String? value = _getNestedValue(_translations, key);
    
    // Fall back to English if not found
    if (value == null && _translations != _fallbackTranslations) {
      value = _getNestedValue(_fallbackTranslations, key);
    }

    return value ?? key;
  }

  /// Get nested value from translations map
  String? _getNestedValue(Map<String, dynamic> translations, String key) {
    final keys = key.split('.');
    dynamic value = translations;

    for (final k in keys) {
      if (value is Map<String, dynamic>) {
        value = value[k];
      } else {
        return null;
      }
    }

    return value?.toString();
  }

  /// Static loader for LocalizationsDelegate
  static Future<TranslationService> create(Locale locale) async {
    final service = TranslationService(locale);
    await service.loadTranslations();
    return service;
  }

  /// Get TranslationService from context
  static TranslationService of(BuildContext context) {
    return Localizations.of<TranslationService>(context, TranslationService)!;
  }
}

/// Localizations delegate for TranslationService
class TranslationDelegate extends LocalizationsDelegate<TranslationService> {
  const TranslationDelegate();

  @override
  bool isSupported(Locale locale) {
    return supportedLanguages.any((lang) => lang.code == locale.languageCode);
  }

  @override
  Future<TranslationService> load(Locale locale) {
    return TranslationService.create(locale);
  }

  @override
  bool shouldReload(TranslationDelegate old) => false;
}

/// Extension for easy translation access
extension TranslationExtension on BuildContext {
  /// Translate a key
  String t(String key) => TranslationService.of(this).translate(key);
}

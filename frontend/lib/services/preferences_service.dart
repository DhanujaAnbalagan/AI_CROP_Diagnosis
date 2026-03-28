import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user preferences
/// Equivalent to React's preferencesService.js
class PreferencesService {
  static const String _userIdKey = 'user_id';
  static const String _languageKey = 'selected_language';
  static const String _selectedCropsKey = 'selected_crops';
  static const String _soundEnabledKey = 'sound_enabled';
  static const String _voiceEnabledKey = 'voice_enabled';
  static const String _onboardingCompleteKey = 'onboarding_complete';
  static const String _regionKey = 'user_region';

  SharedPreferences? _prefs;

  /// Initialize preferences
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Get SharedPreferences instance
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  // ============================================
  // USER ID
  // ============================================
  Future<String?> getUserId() async {
    final p = await prefs;
    return p.getString(_userIdKey);
  }

  Future<void> setUserId(String userId) async {
    final p = await prefs;
    await p.setString(_userIdKey, userId);
  }

  Future<void> clearUserId() async {
    final p = await prefs;
    await p.remove(_userIdKey);
  }

  // ============================================
  // LANGUAGE
  // ============================================
  Future<String?> getLanguage() async {
    final p = await prefs;
    return p.getString(_languageKey);
  }

  Future<void> setLanguage(String code) async {
    final p = await prefs;
    await p.setString(_languageKey, code);
  }

  // ============================================
  // REGION
  // ============================================
  Future<String?> getRegion() async {
    final p = await prefs;
    return p.getString(_regionKey);
  }

  Future<void> setRegion(String region) async {
    final p = await prefs;
    await p.setString(_regionKey, region);
  }

  // ============================================
  // SELECTED CROPS
  // ============================================
  Future<List<String>> getSelectedCrops() async {
    final p = await prefs;
    return p.getStringList(_selectedCropsKey) ?? [];
  }

  Future<void> setSelectedCrops(List<String> crops) async {
    final p = await prefs;
    await p.setStringList(_selectedCropsKey, crops);
  }

  // ============================================
  // AUDIO SETTINGS
  // ============================================
  Future<bool> isSoundEnabled() async {
    final p = await prefs;
    return p.getBool(_soundEnabledKey) ?? true;
  }

  Future<void> setSoundEnabled(bool enabled) async {
    final p = await prefs;
    await p.setBool(_soundEnabledKey, enabled);
  }

  Future<bool> isVoiceEnabled() async {
    final p = await prefs;
    return p.getBool(_voiceEnabledKey) ?? true;
  }

  Future<void> setVoiceEnabled(bool enabled) async {
    final p = await prefs;
    await p.setBool(_voiceEnabledKey, enabled);
  }

  // ============================================
  // ONBOARDING
  // ============================================
  Future<bool> isOnboardingComplete() async {
    final p = await prefs;
    return p.getBool(_onboardingCompleteKey) ?? false;
  }

  Future<void> setOnboardingComplete(bool complete) async {
    final p = await prefs;
    await p.setBool(_onboardingCompleteKey, complete);
  }

  // ============================================
  // ANALYSIS HISTORY
  // ============================================
  static const String _historyKey = 'analysis_history';

  Future<List<String>> _getHistoryList() async {
    final p = await prefs;
    return p.getStringList(_historyKey) ?? [];
  }

  Future<void> saveAnalysisResult(Map<String, dynamic> resultJson) async {
    final p = await prefs;
    final history = await _getHistoryList();
    // Add new result at the beginning
    history.insert(0, json.encode(resultJson));
    
    // Limit to 20 most recent entries
    if (history.length > 20) {
      history.removeRange(20, history.length);
    }
    
    await p.setStringList(_historyKey, history);
  }

  Future<List<Map<String, dynamic>>> getAnalysisHistory() async {
    final history = await _getHistoryList();
    return history
        .map((item) => json.decode(item) as Map<String, dynamic>)
        .toList();
  }

  Future<void> clearHistory() async {
    final p = await prefs;
    await p.remove(_historyKey);
  }

  // ============================================
  // SYNC (placeholder for server sync)
  // ============================================
  Future<void> syncWithServer(String userId) async {
    // TODO: Implement server sync
    await setUserId(userId);
  }

  /// Clear all preferences
  Future<void> clearAll() async {
    final p = await prefs;
    await p.clear();
  }
}

/// Global singleton instance
final preferencesService = PreferencesService();

// Unit 158 by Akshith1413

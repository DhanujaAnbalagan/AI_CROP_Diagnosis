import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'preferences_service.dart';

/// Service for managing audio feedback and text-to-speech.
/// 
/// This service handles:
/// - Text-to-Speech (TTS) announcements.
/// - Sound effects for user interactions (success, error, click).
/// - Managing global sound and voice preferences.
class AudioService {
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  
  bool _soundEnabled = true;
  bool _voiceEnabled = true;
  bool _isInitialized = false;
  String _currentLanguage = 'en-IN';

  /// Initialize the audio service.
  /// 
  /// Loads preferences and configures TTS settings.
  Future<void> init() async {
    if (_isInitialized) return;

    _soundEnabled = await preferencesService.isSoundEnabled();
    _voiceEnabled = await preferencesService.isVoiceEnabled();

    // Default configuration
    await _tts.setLanguage(_currentLanguage);
    await _tts.setSpeechRate(0.5);
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);

    _isInitialized = true;
  }

  /// Sets the TTS language.
  /// 
  /// [speechCode] should be a valid locale code (e.g., 'en-US', 'hi-IN').
  Future<void> setLanguage(String speechCode) async {
    _currentLanguage = speechCode;
    await _tts.setLanguage(speechCode);
  }

  /// Enables or disables sound effects.
  /// 
  /// Persists the preference using [PreferencesService].
  Future<void> setSoundEnabled(bool enabled) async {
    _soundEnabled = enabled;
    await preferencesService.setSoundEnabled(enabled);
  }

  /// Enables or disables voice feedback (TTS).
  /// 
  /// Persists the preference using [PreferencesService].
  Future<void> setVoiceEnabled(bool enabled) async {
    _voiceEnabled = enabled;
    await preferencesService.setVoiceEnabled(enabled);
  }

  /// Returns true if sound effects are enabled.
  bool get isSoundEnabled => _soundEnabled;
  
  /// Returns true if voice feedback is enabled.
  bool get isVoiceEnabled => _voiceEnabled;

  /// Speaks the given [text] using TTS.
  /// 
  /// Does nothing if voice is disabled or text is empty.
  /// Stops any currently playing speech before speaking new text.
  Future<void> speak(String text) async {
    if (!_voiceEnabled || text.isEmpty) return;
    await _tts.stop();
    await _tts.speak(text);
  }

  /// Speaks a predefined guidance message identified by [part].
  /// 
  /// This is used for standard voice prompts like 'welcome', 'phone', etc.
  Future<void> speakGuidance(String part) async {
    // US2: Voice guidance for registration
    // In a real app, these would come from localization files
    Map<String, String> prompts = {
      'welcome': 'Welcome to Crop AId. Let\'s get you registered.',
      'phone': 'Please enter your ten digit mobile number.',
      'otp': 'Please enter the six digit code sent to your phone.',
      'name': 'What is your full name?',
      'success': 'Registration successful. Welcome to the community.',
    };
    
    final prompt = prompts[part];
    if (prompt != null) {
      await speak(prompt);
    }
  }

  /// Plays a sound effect identified by [type].
  /// 
  /// Supported types: 'success', 'error', 'click'.
  /// Uses placeholder URLs for now.
  Future<void> playSound(String type) async {
    if (!_soundEnabled) return;

    // Mapping types to placeholder sound URLs (using some generic beep sounds)
    String url = '';
    switch (type) {
      case 'success':
        url = 'https://assets.mixkit.co/active_storage/sfx/2568/2568-preview.mp3';
        break;
      case 'error':
        url = 'https://assets.mixkit.co/active_storage/sfx/2571/2571-preview.mp3';
        break;
      case 'click':
      default:
        url = 'https://assets.mixkit.co/active_storage/sfx/2567/2567-preview.mp3';
    }

    try {
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      debugPrint('Error playing sound: $e');
    }
  }

  /// Confirms an action by playing a sound and optionally speaking a message.
  Future<void> confirmAction(String type, {String? message}) async {
    await playSound(type);
    if (message != null) {
      await speak(message);
    }
  }

  /// Disposes of audio resources.
  Future<void> dispose() async {
    await _tts.stop();
    await _audioPlayer.dispose();
  }
}

/// Global singleton instance of [AudioService].
final audioService = AudioService();

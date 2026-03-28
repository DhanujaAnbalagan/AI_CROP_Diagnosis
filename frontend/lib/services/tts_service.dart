import 'package:flutter_tts/flutter_tts.dart';
import 'translation_service.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:math';

class TTSService {
  static final FlutterTts _tts = FlutterTts();
  static bool _isInitialized = false;
  static String? _currentSessionId;

  /// Initializes the TTS engine with robust defaults.
  static Future<void> _init() async {
    if (_isInitialized) return;
    
    await _tts.setVolume(1.0);
    await _tts.setPitch(1.0);
    await _tts.setSpeechRate(0.35); // Slower rate for better clarity
    
    if (kIsWeb) {
      // Warm up the engine
      await _tts.getLanguages; 
    }
    
    // Attempt to enable completion awaiting. 
    // Note: This is sometimes flaky on Web, hence the explicit session management.
    try {
      await _tts.awaitSpeakCompletion(true);
    } catch (e) {
      print("TTS: awaitSpeakCompletion initialization error: $e");
    }
    
    _isInitialized = true;
  }

  /// Sets the language and explicitly finds a matching voice.
  static Future<bool> _setupLanguage(String languageCode) async {
    await _init();
    
    final baseCode = languageCode.split('-').first.toLowerCase();
    
    // Try setting the language explicitly first
    await _tts.setLanguage(languageCode);
    
    // Finding a specific voice is the most reliable way on Web (Chrome/Safari)
    try {
      List<dynamic>? voices = await _tts.getVoices;
      if (voices != null && voices.isNotEmpty) {
        dynamic bestVoice;
        
        // Search for a voice that explicitly supports the language
        for (var voice in voices) {
          String vName = (voice['name'] ?? '').toString().toLowerCase();
          String vLocale = (voice['locale'] ?? voice['lang'] ?? '').toString().toLowerCase();
          
          if (vLocale.contains(baseCode) || vName.contains(baseCode)) {
            bestVoice = voice;
            // Prefer voices that mention the language in their name (e.g. "Google Tamil")
            if (vName.contains(baseCode)) break; 
          }
        }
        
        if (bestVoice != null) {
          await _tts.setVoice({"name": bestVoice["name"], "locale": bestVoice["locale"]});
        }
      }
    } catch (e) {
      print("TTS: Voice search error: $e");
    }

    return true;
  }

  static Future speakText(
      String text,
      String languageCode
  ) async {
    _currentSessionId = null; // Cancel any active sequence
    await _tts.stop();
    await _setupLanguage(languageCode);
    await _tts.speak(text);
  }

  static Future speakSteps(
      List<String> steps,
      String languageCode
  ) async {
    // Generate a unique session ID for this playback
    final sessionId = Random().nextInt(1000000).toString();
    _currentSessionId = sessionId;

    await _tts.stop();
    await _setupLanguage(languageCode);
    
    // Brief pause for the engine to settle
    await Future.delayed(const Duration(milliseconds: 300));
    if (_currentSessionId != sessionId) return;

    // Get localized "Step" word
    String stepLabel = await TranslationService.translate("Step", languageCode);

    for (int i = 0; i < steps.length; i++) {
      // Check if we've been cancelled by a new request
      if (_currentSessionId != sessionId) {
        print("TTS: Session $sessionId cancelled at step $i");
        return;
      }

      String cleanText = steps[i].replaceAll(RegExp(r'[^\w\s\u0B80-\u0BFF\u0900-\u097F]'), ' ');
      String sentence = "$stepLabel ${i + 1}. $cleanText";
      
      print("TTS Play Session $sessionId: $sentence");
      
      await _tts.speak(sentence);
      
      // On many browsers, speak returns immediately. 
      // We use a dynamic delay based on character count to prevent overlaps.
      int delayMs = (sentence.length * 120).clamp(2500, 8000);
      await Future.delayed(Duration(milliseconds: delayMs));
    }
    
    // Clear session if we finished naturally
    if (_currentSessionId == sessionId) {
      _currentSessionId = null;
    }
  }

  static Future stop() async {
    _currentSessionId = null;
    await _tts.stop();
  }
}

import 'dart:convert';
import 'package:http/http.dart' as http;

class TranslationService {
  // Hardcoded fallbacks for common UI elements to ensure they never fail
  static final Map<String, Map<String, String>> _fallbacks = {
    'ta': {'Step': 'படி', 'Recommended Actions': 'பரிந்துரைக்கப்பட்ட நடவடிக்கைகள்'},
    'hi': {'Step': 'चरण', 'Recommended Actions': 'अनुशंसित क्रियाएं'},
    'te': {'Step': 'దశ', 'Recommended Actions': 'సిఫార్సు చేసిన చర్యలు'},
    'kn': {'Step': 'ಹಂತ', 'Recommended Actions': 'ಶಿಫಾರಸು ಮಾಡಿದ ಕ್ರಮಗಳು'},
  };

  static Future<String> translate(
      String text,
      String targetLanguage
  ) async {
    final baseCode = targetLanguage.split('-').first.toLowerCase();
    
    // Check fallback first for simple common words
    if (_fallbacks.containsKey(baseCode) && _fallbacks[baseCode]!.containsKey(text)) {
      return _fallbacks[baseCode]![text]!;
    }

    if (baseCode == "en") {
      return text;
    }

    final url = Uri.parse(
      "https://translate.googleapis.com/translate_a/single"
      "?client=gtx"
      "&sl=en"
      "&tl=$baseCode"
      "&dt=t"
      "&q=${Uri.encodeComponent(text)}"
    );

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data[0][0][0];
      }
    } catch (e) {
      print("Translation API error: $e");
    }

    return text;
  }
}

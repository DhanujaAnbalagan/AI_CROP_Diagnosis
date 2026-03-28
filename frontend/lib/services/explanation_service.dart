import '../models/analysis_result.dart';

/// Service for mapping technical AI output to simple farmer-friendly language (US23).
class ExplanationService {
  /// Maps technical labels to simple, descriptive explanations.
  static final Map<String, String> _simpleExplanations = {
    'Apple___Apple_scab': 'Small dark spots on leaves that look like scabs.',
    'Apple___Black_rot': 'Leaves turn yellow with purple spots, eventually rotting.',
    'Apple___Cedar_apple_rust': 'Bright orange-yellow spots on the upper leaf surface.',
    'Cherry_(including_sour)___Powdery_mildew': 'White powdery dust covering the leaves.',
    'Corn_(maize)___Cercospora_leaf_spot': 'Grayish, rectangular spots on the leaves.',
    'Corn_(maize)___Common_rust': 'Small cinnamon-brown pustules on both leaf surfaces.',
    'Corn_(maize)___Northern_Leaf_Blight': 'Large cigar-shaped grayish-green lesions.',
    'Grape___Black_rot': 'Small circular reddish-brown spots on leaves and fruit.',
    'Potato___Early_blight': 'Small dark brown spots with concentric rings.',
    'Potato___Late_blight': 'Dark, water-soaked patches on leaves that expand rapidly.',
    'Tomato___Bacterial_spot': 'Tiny water-soaked spots that turn brown and scabby.',
    'Tomato___Early_blight': 'Brown spots with rings, starting from bottom leaves.',
    'Tomato___Late_blight': 'Pale green or brown melting patches on leaves.',
    'Tomato___Yellow_Leaf_Curl_Virus': 'Leaves curl upwards and turn yellow around edges.',
    'Tomato___Spider_mites': 'Tiny yellow or white speckles on leaves, with fine webs.',
    'healthy': 'The plant looks strong and free from visible diseases.',
  };

  /// Returns a simple explanation for the given [diseaseClass].
  static String getSimpleExplanation(String diseaseClass) {
    if (_simpleExplanations.containsKey(diseaseClass)) {
      return _simpleExplanations[diseaseClass]!;
    }

    // Generic fallback if not explicitly mapped
    if (diseaseClass.toLowerCase().contains('healthy')) {
      return _simpleExplanations['healthy']!;
    }

    // Attempt to format the technical name into something readable
    final internalName = diseaseClass.split('___').last.replaceAll('_', ' ');
    return 'The leaves show signs of $internalName, which may affect plant growth.';
  }

  /// Formats a list of treatment steps into a simplified single string for TTS.
  static String formatForSpeech(AnalysisResult result) {
    final crop = result.crop;
    final disease = result.disease.split('___').last.replaceAll('_', ' ');
    final simple = getSimpleExplanation(result.disease);
    
    return 'Diagnosis for $crop: $disease. $simple Here are the treatment steps: ${result.treatmentSteps.join('. ')}';
  }
}

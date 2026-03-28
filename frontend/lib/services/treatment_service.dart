import 'dart:convert';
import 'package:flutter/services.dart';

/// Service for retrieving dosage information based on detected disease.
class TreatmentService {
  /// Fetches treatment information for a given disease and region.
  /// 
  /// Parameters:
  /// - [disease]: The detected disease (class label).
  /// - [region]: The farmer's region (optional).
  /// 
  /// Returns a [Map] containing 'organic' and 'chemical' treatment lists, or [null].
  static Future<Map<String, dynamic>?> getTreatment(String disease, {String? region}) async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/treatment_database.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (data.containsKey(disease)) {
        final diseaseData = data[disease] as Map<String, dynamic>;
        
        // 1. Check for Regional Override
        if (region != null && diseaseData.containsKey('regional')) {
          final regionalData = diseaseData['regional'] as Map<String, dynamic>;
          if (regionalData.containsKey(region)) {
            final specificOverride = regionalData[region] as Map<String, dynamic>;
            final defaultData = diseaseData['default'] as Map<String, dynamic>;
            
            // Merge: Override keys provided in regional, keep others from default
            return {
              'organic': specificOverride['organic'] ?? defaultData['organic'],
              'chemical': specificOverride['chemical'] ?? defaultData['chemical'],
            };
          }
        }
        
        // 2. Fallback to Default
        return diseaseData['default'] as Map<String, dynamic>?;
      }
    } catch (e) {
      print('Error loading treatment database: $e');
    }

    return null;
  }
}

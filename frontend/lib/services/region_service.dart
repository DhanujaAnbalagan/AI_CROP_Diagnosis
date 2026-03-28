import 'dart:convert';
import 'package:flutter/services.dart';

/// Service for retrieving region-specific advice from a local JSON database.
class RegionService {
  /// Maps latitude and longitude to a supported region name.
  /// 
  /// Returns the region name if it falls within the approximate bounding boxes, or [null].
  static String? getRegionFromCoordinates(double lat, double lon) {
    // Approximate Bounding Boxes for demonstration
    // Tamil Nadu: 8.08°N to 13.5°N, 76.15°E to 80.35°E
    if (lat >= 8.08 && lat <= 13.5 && lon >= 76.15 && lon <= 80.35) {
      return 'Tamil Nadu';
    }
    // Punjab: 29.5°N to 32.5°N, 73.8°E to 76.8°E
    if (lat >= 29.5 && lat <= 32.5 && lon >= 73.8 && lon <= 76.8) {
      return 'Punjab';
    }
    // Maharashtra: 15.6°N to 22.1°N, 72.6°E to 80.9°E
    if (lat >= 15.6 && lat <= 22.1 && lon >= 72.6 && lon <= 80.9) {
      return 'Maharashtra';
    }
    
    return null;
  }

  /// Fetches region-specific advice for a given region and disease.
  /// 
  /// Parameters:
  /// - [region]: The farmer's selected region.
  /// - [disease]: The detected disease (class label).
  /// 
  /// Returns a [String] with the advice, or [null] if no specific advice is available.
  static Future<String?> getRegionAdvice(
    String region,
    String disease
  ) async {
    try {
      final jsonString = await rootBundle.loadString('assets/data/region_advice.json');
      final Map<String, dynamic> data = jsonDecode(jsonString);

      if (data[region] != null && data[region][disease] != null) {
        return data[region][disease];
      }
    } catch (e) {
      print('Error loading region advice: $e');
    }

    return null;
  }
}

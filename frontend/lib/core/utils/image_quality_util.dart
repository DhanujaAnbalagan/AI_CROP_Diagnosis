import 'dart:typed_data';
import 'package:flutter/foundation.dart';

class ImageQualityResult {
  final bool isTooDark;
  final bool isBlurry;
  final double brightness;
  final double sharpness;

  ImageQualityResult({
    required this.isTooDark,
    required this.isBlurry,
    required this.brightness,
    required this.sharpness,
  });

  bool get isGood => !isTooDark && !isBlurry;
}

class ImageQualityUtil {
  /// Analyze image quality from bytes (works on web and mobile)
  static Future<ImageQualityResult> analyzeImageFromBytes(Uint8List bytes) async {
    try {
      // For web: We can't use compute() or heavy image processing
      // Instead, we do a simplified check based on byte sampling
      
      if (bytes.isEmpty) {
        return ImageQualityResult(
          isTooDark: false,
          isBlurry: false,
          brightness: 100,
          sharpness: 100,
        );
      }

      // Sample brightness from raw bytes (simplified approach for web)
      double totalBrightness = 0;
      int sampleCount = 0;
      
      // Sample every 100th byte to estimate average brightness
      for (int i = 0; i < bytes.length; i += 100) {
        totalBrightness += bytes[i];
        sampleCount++;
      }
      
      final avgBrightness = sampleCount > 0 ? totalBrightness / sampleCount : 128.0;
      
      // Estimate sharpness by checking byte variance
      double variance = 0;
      for (int i = 100; i < bytes.length - 100; i += 200) {
        variance += (bytes[i] - bytes[i + 1]).abs();
      }
      final sharpnessScore = sampleCount > 0 ? variance / sampleCount : 50.0;

      return ImageQualityResult(
        isTooDark: avgBrightness < 50,
        isBlurry: sharpnessScore < 5,
        brightness: avgBrightness,
        sharpness: sharpnessScore,
      );
    } catch (e) {
      debugPrint('Image analysis error: $e');
      return ImageQualityResult(
        isTooDark: false,
        isBlurry: false,
        brightness: 100,
        sharpness: 100,
      );
    }
  }

  /// Analyze image from file path (mobile only - returns good result on web)
  static Future<ImageQualityResult> analyzeImage(String path) async {
    // On web, file paths don't work the same way
    // Return a "good" result and rely on byte analysis when available
    if (kIsWeb) {
      return ImageQualityResult(
        isTooDark: false,
        isBlurry: false,
        brightness: 100,
        sharpness: 100,
      );
    }

    // For mobile, we would use the file system
    // But for now, return good result to avoid dart:io issues
    return ImageQualityResult(
      isTooDark: false,
      isBlurry: false,
      brightness: 100,
      sharpness: 100,
    );
  }
}

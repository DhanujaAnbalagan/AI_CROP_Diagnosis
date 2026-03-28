import 'dart:math';
import 'package:camera/camera.dart' show XFile;
import 'package:flutter/foundation.dart';
import '../models/analysis_result.dart';
import 'preferences_service.dart';
import 'ai_prediction_service.dart';
import 'crop_advice_service.dart';
import 'database_service.dart';

/// Service for crop disease analysis.
///
/// Sends images to the AI model, receives predictions with severity, confidence,
/// top-N predictions, and Grad-CAM heatmaps, then enriches with LLM advice.
class CropService {
  // Fixed class labels that exactly match the CNN training order from the backend.
  static const List<String> classLabels = [
    "Apple___Apple_scab",
    "Apple___Black_rot",
    "Apple___Cedar_apple_rust",
    "Apple___healthy",
    "Blueberry___healthy",
    "Cherry_(including_sour)___Powdery_mildew",
    "Cherry_(including_sour)___healthy",
    "Corn_(maize)___Cercospora_leaf_spot",
    "Corn_(maize)___Common_rust",
    "Corn_(maize)___Northern_Leaf_Blight",
    "Corn_(maize)___healthy",
    "Grape___Black_rot",
    "Grape___Esca_(Black_Measles)",
    "Grape___Leaf_blight",
    "Grape___healthy",
    "Orange___Haunglongbing",
    "Peach___Bacterial_spot",
    "Peach___healthy",
    "Pepper,_bell___Bacterial_spot",
    "Pepper,_bell___healthy",
    "Potato___Early_blight",
    "Potato___Late_blight",
    "Potato___healthy",
    "Raspberry___healthy",
    "Soybean___healthy",
    "Squash___Powdery_mildew",
    "Strawberry___Leaf_scorch",
    "Strawberry___healthy",
    "Tomato___Bacterial_spot",
    "Tomato___Early_blight",
    "Tomato___Late_blight",
    "Tomato___Leaf_Mold",
    "Tomato___Septoria_leaf_spot",
    "Tomato___Spider_mites",
    "Tomato___Target_Spot",
    "Tomato___Yellow_Leaf_Curl_Virus",
    "Tomato___Tomato_mosaic_virus",
    "Tomato___healthy"
  ];

  /// Analyzes an image to detect crop diseases.
  /// 
  /// - [imagePath]: Path to the image file.
  /// 
  /// Returns an [AnalysisResult] with diagnostic data including enhanced fields:
  /// topPredictions, severity classification, and Grad-CAM heatmap.
  Future<AnalysisResult> analyzeImage(String imagePath) async {
    Map<String, dynamic>? prediction;

    try {
      // 1. Read the image as bytes (Web-compatible using XFile)
      final List<int> imageBytes = await XFile(imagePath).readAsBytes();

      // 2. Send the image bytes to the AI model
      prediction = await AIPredictionService.predict(imageBytes);
    } catch (e) {
      debugPrint('AI prediction request failed: $e');
      throw Exception('Could not connect to AI service. Please check your internet connection.');
    }

    // 3. Handle explicit AI rejection (e.g., non-leaf)
    if (prediction != null && prediction["success"] == false) {
      // Use the specific human-readable message from the backend gates
      final errorMsg = prediction["message"] ?? prediction["error"] ?? "Could not identify a leaf in the image.";
      throw Exception(errorMsg);
    }

    // 4. Check if we have a valid AI response with class_index
    if (prediction != null && prediction.containsKey("class_index")) {
      // 5. Extract the prediction
      final int classIndex = prediction["class_index"];
      final double confidence = prediction["confidence"];
      // Note: Confidence threshold is now handled purely on the backend.

      // 7. Use server-provided class name or fall back to local mapping
      final String diseaseName = prediction["class_name"] ?? classLabels[classIndex];
      
      print("Predicted disease: $diseaseName");
      print("Confidence: $confidence");

      // 8. Extract crop name — prefer server-provided, fallback to parsing
      final String cropName = prediction["crop_name"] ??
          diseaseName.split('___').first.replaceAll('_', ' ');

      // 9. Extract enhanced fields from AI response
      final List<Map<String, dynamic>> topPredictions = prediction["top_predictions"] != null
          ? List<Map<String, dynamic>>.from(
              (prediction["top_predictions"] as List).map((e) => Map<String, dynamic>.from(e)))
          : [];

      final String? heatmapBase64 = prediction["heatmap_base64"];

      // Severity from AI service
      final Map<String, dynamic>? severityData = prediction["severity"] is Map
          ? Map<String, dynamic>.from(prediction["severity"])
          : null;

      final String severityLevel = severityData?["level"] ?? "moderate";
      final String severityLabel = severityData?["label"] ?? 
          (confidence > 0.8 ? "High" : (confidence > 0.6 ? "Moderate" : "Low"));
      final String severityDescription = severityData?["description"] ?? "";

      // 10. Call the CropAdviceService with mapped disease name
      final result = await CropAdviceService.getCropAdvice(
        crop: cropName,
        disease: diseaseName,
        severity: severityLabel,
        confidence: confidence,
      );

      // 11. Update image URL and finalize with enhanced fields
      final finalResult = result.copyWith(
        imageUrl: imagePath,
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        date: DateTime.now(),
        topPredictions: topPredictions,
        heatmapBase64: heatmapBase64,
        severityLevel: severityLevel,
        severityDescription: severityDescription,
      );

      // Save to history (SQLite - US 24)
      if (!kIsWeb) {
        await databaseService.saveDiagnosis(finalResult);
      }
      
      // Keep SharedPreferences save for current session if needed
      await preferencesService.saveAnalysisResult(finalResult.toJson());

      return finalResult;
    }

    // 12. Final fallback for unexpected states
    throw Exception('An unexpected error occurred during analysis. Please try again.');
  }
}

final cropService = CropService();

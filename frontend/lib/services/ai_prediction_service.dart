import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service for communicating with the Python AI disease prediction model.
///
/// Sends image bytes to the FastAPI `/predict` endpoint and returns the full
/// enhanced prediction result including class name, top-N predictions,
/// severity classification, and Grad-CAM heatmap.
class AIPredictionService {
  static const String aiUrl = "http://localhost:5001/predict";

  /// Sends [imageBytes] to the AI model and returns the full prediction map.
  ///
  /// Response fields:
  /// - `success` (bool)
  /// - `class_index` (int)
  /// - `class_name` (String) — full label, e.g. "Tomato___Late_blight"
  /// - `crop_name` (String) — e.g. "Tomato"
  /// - `disease_name` (String) — e.g. "Late blight"
  /// - `confidence` (double)
  /// - `top_predictions` (List) — top-5 predictions with names+scores
  /// - `severity` (Map) — { level, label, description }
  /// - `heatmap_base64` (String?) — Grad-CAM overlay as base64 PNG
  static Future<Map<String, dynamic>> predict(List<int> imageBytes) async {
    var request = http.MultipartRequest(
      "POST",
      Uri.parse(aiUrl),
    );

    request.files.add(
      http.MultipartFile.fromBytes(
        "file",
        imageBytes,
        filename: "leaf.jpg",
      ),
    );

    var response = await request.send();
    var responseBody = await response.stream.bytesToString();

    print("AI RAW RESPONSE length: ${responseBody.length}");

    if (response.statusCode != 200) {
      throw Exception('Failed to get prediction from AI model: ${response.statusCode}');
    }

    final result = jsonDecode(responseBody);
    
    if (result is Map<String, dynamic>) {
      print("AI class_name: ${result['class_name']}");
      print("AI confidence: ${result['confidence']}");
      print("AI severity: ${result['severity']?['level']}");
      print("AI top_predictions count: ${(result['top_predictions'] as List?)?.length ?? 0}");
      print("AI heatmap_base64 present: ${result['heatmap_base64'] != null}");
    }

    return result;
  }
}

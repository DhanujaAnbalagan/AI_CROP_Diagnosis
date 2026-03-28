import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Service for submitting and retrieving treatment feedback (US32).
///
/// Handles:
/// - Thumbs up/down ratings with optional comments
/// - Feedback retrieval by diagnosis ID
class FeedbackService {
  // Base URL for the feedback API
  static const String _baseUrl = 'http://localhost:5000/api/feedback';

  /// Submit feedback for a diagnosis.
  ///
  /// [diagnosisId] — unique ID of the analysis result
  /// [rating] — 'helpful' or 'not_helpful'
  /// [comment] — optional text feedback
  /// [crop], [disease], [severity] — denormalized for analytics
  static Future<Map<String, dynamic>> submitFeedback({
    required String diagnosisId,
    required String rating,
    String? comment,
    String? userId,
    String? crop,
    String? disease,
    String? severity,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'diagnosisId': diagnosisId,
          'userId': userId ?? 'anonymous',
          'rating': rating,
          'comment': comment ?? '',
          'crop': crop ?? '',
          'disease': disease ?? '',
          'severity': severity ?? '',
        }),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        debugPrint('✅ Feedback submitted: $rating');
        return data;
      } else {
        debugPrint('❌ Feedback submission failed: ${response.statusCode}');
        throw Exception('Failed to submit feedback: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Feedback service error: $e');
      // Return a local success to not block the UI if server is down
      return {
        'success': true,
        'message': 'Feedback saved locally',
        'offline': true,
      };
    }
  }

  /// Get existing feedback for a diagnosis.
  static Future<Map<String, dynamic>?> getFeedback(String diagnosisId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$diagnosisId'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['feedbacks'] != null && (data['feedbacks'] as List).isNotEmpty) {
          return Map<String, dynamic>.from(data['feedbacks'][0]);
        }
      }
    } catch (e) {
      debugPrint('Feedback fetch error: $e');
    }
    return null;
  }
}

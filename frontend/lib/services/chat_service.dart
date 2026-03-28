import 'dart:convert';
import 'package:http/http.dart' as http;
import 'crop_advice_service.dart';
import '../core/constants/app_constants.dart';
import '../models/analysis_result.dart';

/// System prompt for CropAID agriculture assistant persona.
const String _systemPrompt = '''You are CropAID – Smart Farming Assistant. You answer ONLY agriculture-related topics such as: crop diseases, pest control, soil health, irrigation, fertilizers, weather impact on crops, organic farming, crop rotation, plant health, and yield improvement. If the user asks a non-farming question, politely respond that you are here to help with farming and agriculture only. Keep responses helpful, clear, and concise.''';

/// Service for the in-app farming chatbot.
/// Integrates with backend LLM for dynamic, contextual responses.
class ChatService {
  // Use centralized base API URL
  static String get _baseUrl => AppConstants.baseApiUrl;

  /// Gets a dynamic LLM response for the user's question.
  /// Uses chat API when available, otherwise falls back to llm-advice with question as context.
  static Future<String> getResponse(String message, {AnalysisResult? context}) async {
    final query = message.trim().toLowerCase();
    if (query.isEmpty) {
      return "Please ask a question about farming, crops, or plant health.";
    }

    // Handle Greetings
    if (query == 'hi' || query == 'hello' || query == 'hey' || query == 'namaste') {
      return "Hello! I’m your AI Crop Doctor. How can I help you today?";
    }

    // Try chat endpoint first (for backends that support it)
    final chatResponse = await _tryChatApi(message, context: context);
    if (chatResponse != null) return chatResponse;

    // Fallback: use llm-advice with user's question as disease context
    final llmResponse = await _tryLlmAdvice(message, context: context);
    if (llmResponse != null) return llmResponse;

    return "I'm having trouble connecting right now. Please check your internet and try again.";
  }

  static Future<String?> _tryChatApi(String message, {AnalysisResult? context}) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/api/crop-advice/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': message,
          'systemPrompt': _systemPrompt,
          if (context != null) 'context': {
            'crop': context.crop,
            'disease': context.disease,
            'severity': context.severity,
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final text = data['response'] ?? data['message'] ?? data['text'];
        if (text != null && text.toString().trim().isNotEmpty) {
          return text.toString();
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _tryLlmAdvice(String message, {AnalysisResult? context}) async {
    try {
      final result = await CropAdviceService.getCropAdvice(
        crop: context?.crop ?? "General",
        disease: context != null ? "${context.disease} (Question: $message)" : (message.length > 200 ? message.substring(0, 200) : message),
        severity: context?.severity ?? "medium",
        confidence: context?.confidence ?? 0.85,
      );

      final parts = <String>[];
      if (result.cause.isNotEmpty && result.cause != 'Unknown cause') {
        parts.add(result.cause);
      }
      if (result.symptoms.isNotEmpty) {
        parts.add("\n\n**Symptoms:** ${result.symptoms}");
      }
      if (result.immediate.isNotEmpty) {
        parts.add("\n\n**Immediate action:** ${result.immediate}");
      }
      if (result.organic.isNotEmpty) {
        parts.add("\n\n**Organic solutions:** ${result.organic}");
      }
      if (result.prevention.isNotEmpty) {
        parts.add("\n\n**Prevention:** ${result.prevention}");
      }

      if (parts.isNotEmpty) return parts.join();
    } catch (_) {}
    return null;
  }
}

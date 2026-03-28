
/// Represents the result of a crop analysis.
/// 
/// Contains details about detected diseases, confidence level, and recommended treatments.
class AnalysisResult {
  /// Unique identifier for the analysis result.
  final String id;
  
  /// The date and time when the analysis was performed.
  final DateTime date;
  
  /// URL of the image analyzed.
  final String imageUrl;
  
  /// The name of the crop (e.g., 'Tomato', 'Potato').
  final String crop;
  
  /// The detected disease or condition (e.g., 'Late Blight').
  final String disease;
  
  /// Confidence score of the diagnosis (0.0 to 1.0).
  final double confidence;
  
  /// Severity level of the disease (e.g., 'High', 'Moderate').
  final String severity;
  
  /// The underlying cause of the disease.
  final String cause;
  
  /// Visible symptoms associated with the disease.
  final String symptoms;
  
  /// Immediate actions to take.
  final String immediate;
  
  /// Recommended chemical treatments.
  final String chemical;
  
  /// Recommended organic treatments.
  final String organic;
  
  /// Preventive measures to avoid future occurrences.
  final String prevention;

  /// Step-by-step treatment instructions.
  final List<String> treatmentSteps;

  /// Organic treatment steps.
  final List<String> organicSteps;

  /// Chemical treatment steps.
  final List<String> chemicalSteps;

  // =============================================
  // US17-20: Enhanced diagnosis fields
  // =============================================

  /// Top-N predictions from the model (US18).
  final List<Map<String, dynamic>> topPredictions;

  /// Base64-encoded Grad-CAM heatmap overlay image (US20).
  final String? heatmapBase64;

  /// Structured severity from the AI service (US19).
  final String severityLevel;
  final String severityDescription;

  // =============================================
  // US30-32: Recovery, Prevention, Feedback fields
  // =============================================

  /// Recovery timeline (US30).
  /// { "initialDays": "3-5", "fullRecoveryDays": "14-21", "monitoringDays": "30", "description": "..." }
  final Map<String, dynamic> recoveryTimeline;

  /// Prevention checklist from AI (US31).
  /// List of actionable prevention tips specific to the crop/disease.
  final List<String> preventionChecklist;

  /// Creates an [AnalysisResult] instance.
  AnalysisResult({
    required this.id,
    required this.date,
    required this.imageUrl,
    required this.crop,
    required this.disease,
    required this.confidence,
    required this.severity,
    required this.cause,
    required this.symptoms,
    required this.immediate,
    required this.chemical,
    required this.organic,
    required this.prevention,
    required this.treatmentSteps,
    required this.organicSteps,
    required this.chemicalSteps,
    this.topPredictions = const [],
    this.heatmapBase64,
    this.severityLevel = 'moderate',
    this.severityDescription = '',
    this.recoveryTimeline = const {},
    this.preventionChecklist = const [],
  });

  /// Converts the [AnalysisResult] instance to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'date': date.toIso8601String(),
      'imageUrl': imageUrl,
      'crop': crop,
      'disease': disease,
      'confidence': confidence,
      'severity': severity,
      'cause': cause,
      'symptoms': symptoms,
      'immediate': immediate,
      'chemical': chemical,
      'organic': organic,
      'prevention': prevention,
      'treatmentSteps': treatmentSteps,
      'organicSteps': organicSteps,
      'chemicalSteps': chemicalSteps,
      'topPredictions': topPredictions,
      'heatmapBase64': heatmapBase64,
      'severityLevel': severityLevel,
      'severityDescription': severityDescription,
      'recoveryTimeline': recoveryTimeline,
      'preventionChecklist': preventionChecklist,
    };
  }

  /// Creates an [AnalysisResult] instance from a JSON map.
  factory AnalysisResult.fromJson(Map<String, dynamic> json) {
    return AnalysisResult(
      id: json['id'],
      date: DateTime.parse(json['date']),
      imageUrl: json['imageUrl'],
      crop: json['crop'],
      disease: json['disease'],
      confidence: json['confidence'].toDouble(),
      severity: json['severity'],
      cause: json['cause'] ?? '',
      symptoms: json['symptoms'] ?? '',
      immediate: json['immediate'] ?? '',
      chemical: json['chemical'] ?? '',
      organic: json['organic'] ?? '',
      prevention: json['prevention'] ?? '',
      treatmentSteps: json['treatmentSteps'] != null 
          ? List<String>.from(json['treatmentSteps']) 
          : [],
      organicSteps: json['organicSteps'] != null
          ? List<String>.from(json['organicSteps'])
          : [],
      chemicalSteps: json['chemicalSteps'] != null
          ? List<String>.from(json['chemicalSteps'])
          : [],
      topPredictions: json['topPredictions'] != null
          ? List<Map<String, dynamic>>.from(
              (json['topPredictions'] as List).map((e) => Map<String, dynamic>.from(e)))
          : [],
      heatmapBase64: json['heatmapBase64'],
      severityLevel: json['severityLevel'] ?? 'moderate',
      severityDescription: json['severityDescription'] ?? '',
      recoveryTimeline: json['recoveryTimeline'] != null
          ? Map<String, dynamic>.from(json['recoveryTimeline'])
          : {},
      preventionChecklist: json['preventionChecklist'] != null
          ? List<String>.from(json['preventionChecklist'])
          : [],
    );
  }

  /// Creates a copy of this [AnalysisResult] with the given fields replaced.
  AnalysisResult copyWith({
    String? id,
    DateTime? date,
    String? imageUrl,
    String? crop,
    String? disease,
    double? confidence,
    String? severity,
    String? cause,
    String? symptoms,
    String? immediate,
    String? chemical,
    String? organic,
    String? prevention,
    List<String>? treatmentSteps,
    List<String>? organicSteps,
    List<String>? chemicalSteps,
    List<Map<String, dynamic>>? topPredictions,
    String? heatmapBase64,
    String? severityLevel,
    String? severityDescription,
    Map<String, dynamic>? recoveryTimeline,
    List<String>? preventionChecklist,
  }) {
    return AnalysisResult(
      id: id ?? this.id,
      date: date ?? this.date,
      imageUrl: imageUrl ?? this.imageUrl,
      crop: crop ?? this.crop,
      disease: disease ?? this.disease,
      confidence: confidence ?? this.confidence,
      severity: severity ?? this.severity,
      cause: cause ?? this.cause,
      symptoms: symptoms ?? this.symptoms,
      immediate: immediate ?? this.immediate,
      chemical: chemical ?? this.chemical,
      organic: organic ?? this.organic,
      prevention: prevention ?? this.prevention,
      treatmentSteps: treatmentSteps ?? this.treatmentSteps,
      organicSteps: organicSteps ?? this.organicSteps,
      chemicalSteps: chemicalSteps ?? this.chemicalSteps,
      topPredictions: topPredictions ?? this.topPredictions,
      heatmapBase64: heatmapBase64 ?? this.heatmapBase64,
      severityLevel: severityLevel ?? this.severityLevel,
      severityDescription: severityDescription ?? this.severityDescription,
      recoveryTimeline: recoveryTimeline ?? this.recoveryTimeline,
      preventionChecklist: preventionChecklist ?? this.preventionChecklist,
    );
  }
}

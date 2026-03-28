/// Alert system models for the CropAId application.
enum AlertType {
  warning,
  info,
  success,
}

enum UrgencyLevel {
  high,
  medium,
  low,
}

class AlertFeedback {
  final String alertId;
  final String feedbackType; // 'helpful' or 'not_helpful'
  final int timestamp;

  AlertFeedback({
    required this.alertId,
    required this.feedbackType,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'alertId': alertId,
      'feedbackType': feedbackType,
      'timestamp': timestamp,
    };
  }

  factory AlertFeedback.fromJson(Map<String, dynamic> json) {
    return AlertFeedback(
      alertId: json['alertId'],
      feedbackType: json['feedbackType'],
      timestamp: json['timestamp'],
    );
  }
}

import 'package:flutter/material.dart';
import '../models/alert_models.dart';
import '../services/alert_tone_manager.dart';
import '../widgets/alert_banner.dart';

/// Central alert management service for the CropAId application.
class AlertManager {
  static OverlayEntry? _currentAlertOverlay;
  static bool _isShowing = false;

  /// Show an alert with the specified type, urgency, and message.
  static void showAlert(
    BuildContext context, {
    required AlertType type,
    required UrgencyLevel urgency,
    required String message,
    String? alertId,
    VoidCallback? onDismiss,
  }) {
    if (_isShowing) {
      // Dismiss current alert before showing new one
      dismissAlert();
    }

    _isShowing = true;
    
    // Generate unique alert ID if not provided
    final finalAlertId = alertId ?? 'alert_${DateTime.now().millisecondsSinceEpoch}';

    // Create overlay entry
    _currentAlertOverlay = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 8,
        left: 16,
        right: 16,
        child: AlertBanner(
          type: type,
          urgency: urgency,
          message: message,
          alertId: finalAlertId,
          onDismiss: () {
            dismissAlert();
            onDismiss?.call();
          },
        ),
      ),
    );

    // Insert overlay
    Overlay.of(context).insert(_currentAlertOverlay!);

    // Play alert tone
    AlertToneManager.playAlertTone(urgency);
  }

  /// Show success alert (green background)
  static void showSuccess(
    BuildContext context,
    String message, {
    UrgencyLevel urgency = UrgencyLevel.low,
    VoidCallback? onDismiss,
  }) {
    showAlert(
      context,
      type: AlertType.success,
      urgency: urgency,
      message: message,
      onDismiss: onDismiss,
    );
  }

  /// Show warning alert (yellow background)
  static void showWarning(
    BuildContext context,
    String message, {
    UrgencyLevel urgency = UrgencyLevel.medium,
    VoidCallback? onDismiss,
  }) {
    showAlert(
      context,
      type: AlertType.warning,
      urgency: urgency,
      message: message,
      onDismiss: onDismiss,
    );
  }

  /// Show info alert (green background)
  static void showInfo(
    BuildContext context,
    String message, {
    UrgencyLevel urgency = UrgencyLevel.low,
    VoidCallback? onDismiss,
  }) {
    showAlert(
      context,
      type: AlertType.info,
      urgency: urgency,
      message: message,
      onDismiss: onDismiss,
    );
  }

  /// Show error alert (red background)
  static void showError(
    BuildContext context,
    String message, {
    UrgencyLevel urgency = UrgencyLevel.high,
    VoidCallback? onDismiss,
  }) {
    showAlert(
      context,
      type: AlertType.warning,
      urgency: urgency,
      message: message,
      onDismiss: onDismiss,
    );
  }

  /// Show disease detected alert
  static void showDiseaseDetected(
    BuildContext context,
    String diseaseName, {
    VoidCallback? onDismiss,
  }) {
    showWarning(
      context,
      'Disease Detected: $diseaseName',
      urgency: UrgencyLevel.high,
      onDismiss: onDismiss,
    );
  }

  /// Show analysis complete alert
  static void showAnalysisComplete(
    BuildContext context,
    String result, {
    VoidCallback? onDismiss,
  }) {
    showSuccess(
      context,
      'Analysis Complete: $result',
      urgency: UrgencyLevel.low,
      onDismiss: onDismiss,
    );
  }

  /// Show network error alert
  static void showNetworkError(
    BuildContext context, {
    VoidCallback? onDismiss,
  }) {
    showError(
      context,
      'Network Error: Please check your connection',
      urgency: UrgencyLevel.medium,
      onDismiss: onDismiss,
    );
  }

  /// Dismiss the current alert
  static void dismissAlert() {
    if (_currentAlertOverlay != null) {
      _currentAlertOverlay?.remove();
      _currentAlertOverlay = null;
      _isShowing = false;
    }
  }

  /// Check if an alert is currently showing
  static bool get isShowing => _isShowing;

  /// Initialize the alert manager
  static void initialize() {
    // Initialize alert tone manager if needed
  }

  /// Dispose resources
  static void dispose() {
    dismissAlert();
    AlertToneManager.dispose();
  }
}

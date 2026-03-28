import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/theme/app_colors.dart';
import '../models/alert_models.dart';

/// Widget for collecting user feedback on alerts.
class AlertFeedbackWidget extends StatefulWidget {
  final String alertId;
  final String alertMessage;
  final VoidCallback onClose;

  const AlertFeedbackWidget({
    Key? key,
    required this.alertId,
    required this.alertMessage,
    required this.onClose,
  }) : super(key: key);

  @override
  State<AlertFeedbackWidget> createState() => _AlertFeedbackWidgetState();
}

class _AlertFeedbackWidgetState extends State<AlertFeedbackWidget> {
  String? _selectedFeedback;
  bool _isSubmitting = false;

  Future<void> _submitFeedback() async {
    if (_selectedFeedback == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final feedbackList = prefs.getStringList('alert_feedbacks') ?? [];
      
      final feedback = AlertFeedback(
        alertId: widget.alertId,
        feedbackType: _selectedFeedback!,
        timestamp: DateTime.now().millisecondsSinceEpoch,
      );

      feedbackList.add(jsonEncode(feedback.toJson()));
      await prefs.setStringList('alert_feedbacks', feedbackList);

      widget.onClose();
    } catch (e) {
      // Handle error
      print('Error submitting feedback: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Icon(Icons.feedback_outlined, color: AppColors.nature600),
              const SizedBox(width: 8),
              const Text(
                'Alert Feedback',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray800,
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: widget.onClose,
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Alert message
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.gray100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              widget.alertMessage,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.gray700,
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Feedback question
          const Text(
            'Was this alert helpful?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 12),

          // Feedback options
          Row(
            children: [
              Expanded(
                child: _buildFeedbackOption(
                  'helpful',
                  '👍 Helpful',
                  Icons.thumb_up,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFeedbackOption(
                  'not_helpful',
                  '👎 Not Helpful',
                  Icons.thumb_down,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Submit button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedFeedback != null && !_isSubmitting
                  ? _submitFeedback
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.nature600,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Submit Feedback'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeedbackOption(String value, String label, IconData icon) {
    final isSelected = _selectedFeedback == value;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFeedback = value;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.nature100 : AppColors.gray100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppColors.nature600 : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? AppColors.nature600 : AppColors.gray600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? AppColors.nature600 : AppColors.gray700,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

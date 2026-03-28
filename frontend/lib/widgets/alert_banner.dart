import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/alert_models.dart';
import '../services/alert_manager.dart';
import '../widgets/alert_feedback_widget.dart';

/// Reusable alert banner widget for displaying notifications.
class AlertBanner extends StatefulWidget {
  final AlertType type;
  final UrgencyLevel urgency;
  final String message;
  final VoidCallback? onDismiss;
  final String? alertId;

  const AlertBanner({
    Key? key,
    required this.type,
    required this.urgency,
    required this.message,
    this.onDismiss,
    this.alertId,
  }) : super(key: key);

  @override
  State<AlertBanner> createState() => _AlertBannerState();
}

class _AlertBannerState extends State<AlertBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    ));

    _controller.forward();

    // Auto-dismiss based on urgency
    final dismissDuration = _getDismissDuration();
    if (dismissDuration > 0) {
      Future.delayed(Duration(seconds: dismissDuration), () {
        if (mounted) {
          _dismiss();
        }
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _getDismissDuration() {
    switch (widget.urgency) {
      case UrgencyLevel.high:
        return 8; // 8 seconds for high urgency
      case UrgencyLevel.medium:
        return 6; // 6 seconds for medium urgency
      case UrgencyLevel.low:
        return 4; // 4 seconds for low urgency
    }
  }

  Color _getBackgroundColor() {
    switch (widget.urgency) {
      case UrgencyLevel.high:
        return AppColors.red500;
      case UrgencyLevel.medium:
        return AppColors.amber500;
      case UrgencyLevel.low:
        return AppColors.nature600;
    }
  }

  IconData _getIcon() {
    switch (widget.type) {
      case AlertType.warning:
        return Icons.warning_rounded;
      case AlertType.info:
        return Icons.info_rounded;
      case AlertType.success:
        return Icons.check_circle_rounded;
    }
  }

  void _dismiss() {
    _controller.reverse().then((_) {
      if (mounted) {
        widget.onDismiss?.call();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _getBackgroundColor(),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              // Large icon for low-literacy users
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _getIcon(),
                  color: Colors.white,
                  size: 32,
                ),
              ),
              const SizedBox(width: 12),
              // Message text
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.message,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _getUrgencyText(),
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Feedback buttons
              if (widget.alertId != null) ...[
                const SizedBox(width: 8),
                AlertFeedbackButton(
                  alertId: widget.alertId!,
                  onFeedback: (feedbackType) {
                    // Handle feedback
                    print('Feedback: $feedbackType for alert ${widget.alertId}');
                  },
                ),
              ],
              // Dismiss button
              IconButton(
                onPressed: _dismiss,
                icon: const Icon(Icons.close, color: Colors.white),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(
                  minWidth: 32,
                  minHeight: 32,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getUrgencyText() {
    switch (widget.urgency) {
      case UrgencyLevel.high:
        return 'High Priority';
      case UrgencyLevel.medium:
        return 'Medium Priority';
      case UrgencyLevel.low:
        return 'Information';
    }
  }
}

/// Feedback button for alerts
class AlertFeedbackButton extends StatelessWidget {
  final String alertId;
  final Function(String) onFeedback;

  const AlertFeedbackButton({
    Key? key,
    required this.alertId,
    required this.onFeedback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Helpful button
        GestureDetector(
          onTap: () => onFeedback('helpful'),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.thumb_up,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
        const SizedBox(width: 4),
        // Not helpful button
        GestureDetector(
          onTap: () => onFeedback('not_helpful'),
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.thumb_down,
              color: Colors.white,
              size: 16,
            ),
          ),
        ),
      ],
    );
  }
}

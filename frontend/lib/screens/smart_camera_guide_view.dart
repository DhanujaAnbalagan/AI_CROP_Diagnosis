import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/translation_service.dart';
import '../services/audio_service.dart';

/// A guide screen that appears before the camera to explain smart features.
/// Redesigned with AgriTech Light theme.
class SmartCameraGuideView extends StatelessWidget {
  final VoidCallback onBack;
  final VoidCallback onStart;

  const SmartCameraGuideView({
    super.key,
    required this.onBack,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background soft gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE8F5E9),
                  AppColors.background,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Container(
                  constraints: const BoxConstraints(maxWidth: 450),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: AppColors.mediumShadow,
                    border: Border.all(color: AppColors.primary.withOpacity(0.05), width: 1),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Section
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              LucideIcons.scan,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  context.t('smartCameraGuide.title'),
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: AppColors.textPrimary,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  context.t('smartCameraGuide.subtitle'),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 36),

                      // Professional Guide Items
                      _buildGuideItem(
                        context,
                        icon: LucideIcons.leaf,
                        iconColor: AppColors.primary,
                        title: context.t('smartCameraGuide.autoLeafDetection'),
                        description: context.t('smartCameraGuide.autoLeafDetectionDesc'),
                      ),
                      const SizedBox(height: 24),
                      _buildGuideItem(
                        context,
                        icon: LucideIcons.gauge,
                        iconColor: AppColors.info,
                        title: context.t('smartCameraGuide.qualityMeter'),
                        description: context.t('smartCameraGuide.qualityMeterDesc'),
                      ),
                      const SizedBox(height: 24),
                      _buildGuideItem(
                        context,
                        icon: LucideIcons.mic2,
                        iconColor: AppColors.forest600,
                        title: context.t('smartCameraGuide.voiceGuidance'),
                        description: context.t('smartCameraGuide.voiceGuidanceDesc'),
                      ),
                      const SizedBox(height: 24),
                      _buildGuideItem(
                        context,
                        icon: LucideIcons.alertCircle,
                        iconColor: AppColors.warning,
                        title: context.t('smartCameraGuide.qualityWarnings'),
                        description: context.t('smartCameraGuide.qualityWarningsDesc'),
                      ),
                      
                      const SizedBox(height: 48),

                      // Primary Action
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton(
                          onPressed: () {
                            audioService.playSound('click');
                            onStart();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 0,
                          ),
                          child: Text(
                            context.t('smartCameraGuide.startSmartCamera').toUpperCase(),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Cancel Button
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: TextButton(
                          onPressed: onBack,
                          child: Text(
                            context.t('common.cancel').toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.textHint,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.1,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGuideItem(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            icon,
            color: iconColor,
            size: 20,
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                  height: 1.5,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


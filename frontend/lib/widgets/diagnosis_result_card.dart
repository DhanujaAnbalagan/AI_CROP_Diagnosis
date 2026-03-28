import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';

class DiagnosisResultCard extends StatelessWidget {
  final String diseaseName;
  final String cropName;
  final double confidence;
  final String? imagePath;
  final VoidCallback? onHeatmapTap;

  const DiagnosisResultCard({
    Key? key,
    required this.diseaseName,
    required this.cropName,
    required this.confidence,
    this.imagePath,
    this.onHeatmapTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(28),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.primary.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imagePath != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              child: Image.network(
                imagePath!,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: AppColors.tan50,
                  child: const Icon(LucideIcons.imageOff, color: AppColors.textHint, size: 32),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(100),
                      ),
                      child: Text(
                        cropName.toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 11,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ),
                    if (onHeatmapTap != null)
                      TextButton.icon(
                        onPressed: onHeatmapTap,
                        icon: const Icon(LucideIcons.layout, size: 16),
                        label: const Text("VIEW HEATMAP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  diseaseName,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    const Text(
                      "AI Confidence",
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      "${(confidence * 100).toStringAsFixed(0)}%",
                      style: TextStyle(
                        color: confidence > 0.8 ? AppColors.success : AppColors.warning,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: confidence,
                    backgroundColor: AppColors.tan100,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      confidence > 0.8 ? AppColors.success : AppColors.warning,
                    ),
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

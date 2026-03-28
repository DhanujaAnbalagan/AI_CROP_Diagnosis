import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

enum TreatmentType { chemical, organic }

class TreatmentCard extends StatelessWidget {
  final String title;
  final List<String> instructions;
  final String? dosage;
  final TreatmentType type;

  const TreatmentCard({
    Key? key,
    required this.title,
    required this.instructions,
    this.dosage,
    this.type = TreatmentType.chemical,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bool isChemical = type == TreatmentType.chemical;
    final Color accentColor = isChemical ? AppColors.info : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FDF9), // Soft light green/white background
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
        border: Border.all(
          color: accentColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                Icon(
                  isChemical ? Icons.science_outlined : Icons.eco_outlined,
                  color: accentColor,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  isChemical ? "Chemical Treatment" : "Organic Remedy",
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: accentColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1B1B1B), // Dark primary text
                      ),
                ),
                const SizedBox(height: 16),
                ...instructions.asMap().entries.map((entry) {
                  final index = entry.key;
                  final step = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              "${index + 1}",
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            step,
                            style: const TextStyle(
                              color: Color(0xFF4F4F4F), // Dark secondary text
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (dosage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.accent.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: Colors.orange, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Dosage: $dosage",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF5D4037),
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

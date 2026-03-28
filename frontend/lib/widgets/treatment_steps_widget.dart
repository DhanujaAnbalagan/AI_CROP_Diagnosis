import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// UI component to display numbered treatment steps with icons (US25).
class TreatmentStepsWidget extends StatelessWidget {
  final List<String> steps;
  final String title;
  final Color themeColor;

  const TreatmentStepsWidget({
    super.key,
    required this.steps,
    this.title = 'Treatment Steps',
    this.themeColor = const Color(0xFF10B981),
  });

  @override
  Widget build(BuildContext context) {
    if (steps.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.listOrdered, size: 20, color: themeColor),
            const SizedBox(width: 10),
            Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1B1B1B),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...steps.asMap().entries.map((entry) {
          final index = entry.key;
          final step = entry.value;
          final isLast = index == steps.length - 1;

          return IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Number column with connector line
                Column(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: themeColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                        border: Border.all(color: themeColor.withOpacity(0.5), width: 2),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: themeColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    if (!isLast)
                      Expanded(
                        child: Container(
                          width: 2,
                          color: themeColor.withOpacity(0.15),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 16),
                // Content column
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          step,
                          style: const TextStyle(
                            color: Color(0xFF4F4F4F),
                            fontSize: 15,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }
}

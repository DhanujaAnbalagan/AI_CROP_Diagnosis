import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Displays a time-based greeting and weather information.
class WeatherGreetingCard extends StatelessWidget {
  final String greeting;
  final String farmerName;

  const WeatherGreetingCard({
    super.key,
    required this.greeting,
    this.farmerName = 'Farmer',
  });

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final timeStr = _formatTime();
    final weatherIcon = hour >= 6 && hour < 18 ? Icons.wb_cloudy_rounded : Icons.nights_stay_rounded;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF1A7F3C).withOpacity(0.9),
            const Color(0xFF2E7D32).withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  timeStr,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$greeting, $farmerName 🌱',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  Icon(weatherIcon, color: Colors.white.withOpacity(0.9), size: 22),
                  const SizedBox(width: 6),
                  const Text(
                    '28°C',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Cloudy',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }
}

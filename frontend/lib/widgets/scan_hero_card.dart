import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A large hero card to trigger the crop scan action.
class ScanHeroCard extends StatelessWidget {
  final VoidCallback onTap;

  const ScanHeroCard({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 200,
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
          ),
          image: const DecorationImage(
            image: NetworkImage(
              'https://images.unsplash.com/photo-1464226184884-fa280b87c399?q=80&w=1000&auto=format&fit=crop',
            ),
            fit: BoxFit.cover,
            opacity: 0.25,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0xFF2E7D32),
              blurRadius: 20,
              offset: Offset(0, 8),
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
              ),
              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 32),
            ),
            const SizedBox(height: 14),
            const Text(
              'SCAN CROP',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap to diagnose with AI',
              style: TextStyle(
                color: Colors.white.withOpacity(0.8),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

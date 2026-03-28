import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../core/constants/app_constants.dart';

/// Screen for displaying privacy policy and collecting user consent.
/// 
/// explains:
/// - Why data is collected (Image analysis).
/// - Local storage usage.
/// - Requires user agreement before proceeding.
/// 
/// Equivalent to React's `ConsentScreen.jsx`.
class ConsentScreen extends StatefulWidget {
  final VoidCallback onConsent;

  const ConsentScreen({
    super.key,
    required this.onConsent,
  });

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primaryGreen, AppColors.secondaryGreen],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 400),
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: AppColors.nature100, borderRadius: BorderRadius.circular(50)),
                          child: const Icon(Icons.shield_outlined, size: 32, color: AppColors.nature600),
                        ),
                        const SizedBox(width: 12),
                        Text('Privacy & Data', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.nature900)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text('To provide accurate diagnoses, we need your permission to analyze plant images.', style: TextStyle(fontWeight: FontWeight.w500)),
                    const SizedBox(height: 24),

                    _buildFeatureItem(context, icon: Icons.cloud_outlined, title: 'Image Analysis', description: 'Images are processed to identify diseases.'),
                    const SizedBox(height: 16),
                    _buildFeatureItem(context, icon: Icons.storage_outlined, title: 'Local Storage', description: 'We store crop preferences on your device.'),
                    const SizedBox(height: 24),

                    // Mandatory Checkbox
                    Row(
                      children: [
                        Checkbox(
                          value: _agreed,
                          activeColor: AppColors.nature600,
                          onChanged: (val) => setState(() => _agreed = val ?? false),
                        ),
                        const Expanded(
                          child: Text('I understand that my data will be used for diagnosis purposes.', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Agree Button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _agreed ? widget.onConsent : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.nature600,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          disabledBackgroundColor: AppColors.gray300,
                        ),
                        child: const Text('I Agree & Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(BuildContext context, {required IconData icon, required String title, required String description}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 24, color: AppColors.earth500),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.nature800)),
              Text(description, style: const TextStyle(fontSize: 12, color: AppColors.nature600)),
            ],
          ),
        ),
      ],
    );
  }
}

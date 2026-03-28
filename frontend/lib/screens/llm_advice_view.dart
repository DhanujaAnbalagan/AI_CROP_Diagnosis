import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive_layout.dart';
import '../core/localization/translation_service.dart';
import '../services/crop_advice_service.dart';
import '../widgets/crop_advice_card.dart';

/// LLM Advice View.
/// Redesigned with AgriTech Premium Light theme.
class LlmAdviceView extends StatefulWidget {
  final VoidCallback onBack;

  const LlmAdviceView({super.key, required this.onBack});

  @override
  State<LlmAdviceView> createState() => _LlmAdviceViewState();
}

class _LlmAdviceViewState extends State<LlmAdviceView> {
  final _cropController = TextEditingController(text: 'Tomato');
  final _diseaseController = TextEditingController(text: 'Early Blight');
  String _severity = 'medium';
  double _confidence = 0.93;
  bool _isLoading = false;
  String? _error;

  @override
  void dispose() {
    _cropController.dispose();
    _diseaseController.dispose();
    super.dispose();
  }

  Future<void> _getAdvice() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final result = await CropAdviceService.getCropAdvice(
        crop: _cropController.text,
        disease: _diseaseController.text,
        severity: _severity,
        confidence: _confidence,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => Container(
          height: MediaQuery.of(context).size.height * 0.9,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
            child: CropAdviceCard(
              result: result,
              onClose: () => Navigator.pop(context),
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: IconButton(
            icon: const Icon(LucideIcons.chevronLeft, size: 24),
            onPressed: widget.onBack,
            color: AppColors.textPrimary,
          ),
        ),
        title: Text(
          context.t('llmAdvice.title'),
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w900,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Background soft gradient
          Container(
            height: 250,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFFE8F5E9), AppColors.background],
              ),
            ),
          ),
          
          SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: ResponsiveBody(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 24),
                  
                  // Header Card
                  Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: AppColors.mediumShadow,
                            border: Border.all(color: AppColors.primary.withOpacity(0.05)),
                          ),
                          child: const Icon(LucideIcons.brain, size: 56, color: AppColors.primary),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          context.t('llmAdvice.subtitle'),
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Input Form
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: AppColors.softShadow,
                      border: Border.all(color: AppColors.primary.withOpacity(0.05)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.t('llmAdvice.diseaseInfo').toUpperCase(),
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            color: AppColors.primary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Crop Name
                        _buildLabel(context.t('llmAdvice.cropName')),
                        const SizedBox(height: 10),
                        _buildTextField(_cropController, context.t('llmAdvice.cropHint'), LucideIcons.leaf),
                        const SizedBox(height: 24),

                        // Disease
                        _buildLabel(context.t('llmAdvice.diseaseDetected')),
                        const SizedBox(height: 10),
                        _buildTextField(_diseaseController, context.t('llmAdvice.diseaseHint'), LucideIcons.bug),
                        const SizedBox(height: 24),

                        // Severity & Confidence Row
                        LayoutBuilder(
                          builder: (context, constraints) {
                            if (constraints.maxWidth > 500) {
                              return Row(
                                children: [
                                  Expanded(child: _buildSeverityDropdown()),
                                  const SizedBox(width: 20),
                                  Expanded(child: _buildConfidenceField()),
                                ],
                              );
                            }
                            return Column(
                              children: [
                                _buildSeverityDropdown(),
                                const SizedBox(height: 20),
                                _buildConfidenceField(),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 40),

                        // Error message
                        if (_error != null)
                          Container(
                            padding: const EdgeInsets.all(16),
                            margin: const EdgeInsets.only(bottom: 24),
                            decoration: BoxDecoration(
                              color: AppColors.error.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.error.withOpacity(0.2)),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.alertCircle, color: AppColors.error, size: 20),
                                const SizedBox(width: 12),
                                Expanded(child: Text(_error!, style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w500))),
                              ],
                            ),
                          ),

                        // Main Action Button
                        SizedBox(
                          width: double.infinity,
                          height: 64,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _getAdvice,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 0,
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    width: 24, height: 24,
                                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(LucideIcons.sparkles, size: 20),
                                      const SizedBox(width: 12),
                                      Text(
                                        context.t('llmAdvice.getAdvice').toUpperCase(),
                                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w900, letterSpacing: 1.1),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Helper Instruction Card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.info.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.info.withOpacity(0.1)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(LucideIcons.info, size: 18, color: AppColors.info),
                            const SizedBox(width: 12),
                            Text(
                              context.t('llmAdvice.howToUse'),
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.info),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          context.t('llmAdvice.instructions'),
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.textSecondary,
                            height: 1.6,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textSecondary),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, IconData icon) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w500),
          prefixIcon: Icon(icon, size: 20, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildSeverityDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context.t('llmAdvice.severity')),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _severity,
              isExpanded: true,
              dropdownColor: AppColors.surface,
              style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
              icon: const Icon(LucideIcons.chevronDown, size: 20, color: AppColors.primary),
              items: ['low', 'medium', 'high'].map((s) {
                return DropdownMenuItem(
                  value: s,
                  child: Text(s[0].toUpperCase() + s.substring(1)),
                );
              }).toList(),
              onChanged: (v) => setState(() => _severity = v!),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildConfidenceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(context.t('llmAdvice.confidence')),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
          ),
          child: TextField(
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: const TextStyle(color: AppColors.textPrimary, fontSize: 16, fontWeight: FontWeight.w700),
            decoration: const InputDecoration(
              hintText: '0.00 - 1.00',
              hintStyle: TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w500),
              prefixIcon: Icon(LucideIcons.gauge, size: 20, color: AppColors.info),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            ),
            onChanged: (v) {
              final val = double.tryParse(v);
              if (val != null && val >= 0 && val <= 1) setState(() => _confidence = val);
            },
            controller: TextEditingController(text: _confidence.toStringAsFixed(2)),
          ),
        ),
      ],
    );
  }
}


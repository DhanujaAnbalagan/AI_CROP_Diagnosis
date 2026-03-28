import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../models/analysis_result.dart';
import '../services/preferences_service.dart';
import '../services/tts_service.dart';
import '../services/translation_service.dart';
import '../services/region_service.dart';
import '../services/treatment_service.dart';
import '../services/explanation_service.dart';
import 'treatment_steps_widget.dart';

/// A sophisticated advice card matching the React application's high-end UI.
/// Redesigned with AgriTech Premium Light theme.
class CropAdviceCard extends StatefulWidget {
  final AnalysisResult result;
  final VoidCallback onClose;

  const CropAdviceCard({
    super.key,
    required this.result,
    required this.onClose,
  });

  @override
  State<CropAdviceCard> createState() => _CropAdviceCardState();
}

class _CropAdviceCardState extends State<CropAdviceCard> {
  bool _copied = false;
  List<String> _translatedSteps = [];
  List<String> _translatedOrganicSteps = [];
  List<String> _translatedChemicalSteps = [];
  String _targetLanguage = 'en-US';
  bool _isTranslating = false;
  String? _regionAdvice;
  String? _translatedRegionAdvice;
  Map<String, dynamic>? _structuredTreatments;
  bool _showOrganic = true;
  bool _showHeatmapOverlay = false;

  @override
  void initState() {
    super.initState();
    _initializeTranslations();
  }

  Future<void> _initializeTranslations() async {
    setState(() => _isTranslating = true);
    
    _targetLanguage = await preferencesService.getLanguage() ?? 'en-US';
    
    if (_targetLanguage.startsWith('en')) {
      _translatedSteps = List.from(widget.result.treatmentSteps);
      _translatedOrganicSteps = List.from(widget.result.organicSteps);
      _translatedChemicalSteps = List.from(widget.result.chemicalSteps);
    } else {
      _translatedSteps = await _translateList(widget.result.treatmentSteps);
      _translatedOrganicSteps = await _translateList(widget.result.organicSteps);
      _translatedChemicalSteps = await _translateList(widget.result.chemicalSteps);
    }

    final region = await preferencesService.getRegion() ?? 'Tamil Nadu';
    _regionAdvice = await RegionService.getRegionAdvice(region, widget.result.disease);
    
    if (_regionAdvice != null && !_targetLanguage.startsWith('en')) {
      _translatedRegionAdvice = await TranslationService.translate(_regionAdvice!, _targetLanguage);
    }

    _structuredTreatments = await TreatmentService.getTreatment(
      widget.result.disease,
      region: region,
    );

    if (mounted) {
      setState(() => _isTranslating = false);
    }
  }

  Future<List<String>> _translateList(List<String> list) async {
    final List<String> translated = [];
    for (final item in list) {
      final t = await TranslationService.translate(item, _targetLanguage);
      translated.add(t);
    }
    return translated;
  }

  void _handleCopy() {
    final text = '''
Crop: ${widget.result.crop}
Disease: ${widget.result.disease}
Severity: ${widget.result.severity}
Confidence: ${(widget.result.confidence * 100).toStringAsFixed(0)}%
Analysis: ${widget.result.cause}
''';
    Clipboard.setData(ClipboardData(text: text));
    setState(() => _copied = true);
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _copied = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // 1. Image Header
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.background,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  _buildImage(),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.background,
                        ],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 20,
                    right: 20,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.result.crop.toUpperCase(),
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.result.disease,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton(
                  icon: const Icon(LucideIcons.x, color: AppColors.textPrimary),
                  onPressed: widget.onClose,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white70,
                    elevation: 4,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),

          // 2. Main Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Metrics Row
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          'Confidence',
                          '${(widget.result.confidence * 100).toInt()}%',
                          LucideIcons.target,
                          color: AppColors.success,
                          progress: widget.result.confidence,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          'Severity',
                          widget.result.severity.toUpperCase(),
                          LucideIcons.alertTriangle,
                          color: _getSeverityColor(widget.result.severity),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Heatmap (if available)
                  if (widget.result.heatmapBase64 != null) ...[
                    _buildSectionTitle(LucideIcons.layers, 'AFFECTED AREAS', Colors.redAccent),
                    _buildHeatmapViewer(),
                    const SizedBox(height: 32),
                  ],

                  // AI Insight Section
                  _buildSectionTitle(LucideIcons.sparkles, 'AI INSIGHT & CAUSE', AppColors.primary),
                  _buildGlassInfoCard(
                    widget.result.cause,
                    icon: LucideIcons.lightbulb,
                    iconColor: Colors.amber,
                  ),

                  const SizedBox(height: 32),

                  // Symptoms
                  _buildSectionTitle(LucideIcons.list, 'DETECTED SYMPTOMS', AppColors.info),
                  _buildSymptomsTags(),

                  const SizedBox(height: 32),

                  // Treatment Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildSectionTitle(LucideIcons.shieldCheck, 'RECOMMENDED ACTIONS', AppColors.success),
                      IconButton(
                        onPressed: _isTranslating ? null : () {
                          TTSService.speakSteps(_translatedSteps, _targetLanguage);
                        },
                        icon: Icon(
                          _isTranslating ? LucideIcons.loader : LucideIcons.volume2, 
                          size: 20, 
                          color: AppColors.primary
                        ),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          padding: const EdgeInsets.all(10),
                        ),
                      ),
                    ],
                  ),
                  _buildTreatmentList(),

                  const SizedBox(height: 32),

                  // Treatment Tabs (Organic vs Chemical)
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: AppColors.softShadow,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _showOrganic = true),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: _showOrganic ? AppColors.primary : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.leaf, size: 18, color: _showOrganic ? Colors.white : AppColors.textHint),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Organic',
                                    style: TextStyle(
                                      color: _showOrganic ? Colors.white : AppColors.textHint,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _showOrganic = false),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              decoration: BoxDecoration(
                                color: !_showOrganic ? const Color(0xFFF59E0B) : Colors.transparent,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(LucideIcons.flaskConical, size: 18, color: !_showOrganic ? Colors.white : AppColors.textHint),
                                  const SizedBox(width: 10),
                                  Text(
                                    'Chemical',
                                    style: TextStyle(
                                      color: !_showOrganic ? Colors.white : AppColors.textHint,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 15,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  
                  if (_showOrganic)
                    _buildStepsList(
                      _translatedOrganicSteps.isEmpty ? widget.result.organicSteps : _translatedOrganicSteps,
                      type: 'organic',
                    )
                  else
                    _buildStepsList(
                      _translatedChemicalSteps.isEmpty ? widget.result.chemicalSteps : _translatedChemicalSteps,
                      type: 'chemical',
                    ),

                  const SizedBox(height: 32),

                  // Recovery Timeline
                  if (widget.result.recoveryTimeline.isNotEmpty) ...[
                    _buildSectionTitle(LucideIcons.calendar, 'RECOVERY TIMELINE', AppColors.info),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: AppColors.softShadow,
                      ),
                      child: Column(
                        children: [
                          _buildTimelineRow(
                            'Initial Improvement',
                            '${widget.result.recoveryTimeline['initialDays'] ?? '3-5'} days',
                            LucideIcons.trendingUp,
                            AppColors.info,
                          ),
                          const Divider(height: 32, thickness: 0.5),
                          _buildTimelineRow(
                            'Full Recovery',
                            '${widget.result.recoveryTimeline['fullRecoveryDays'] ?? '14-21'} days',
                            LucideIcons.heart,
                            AppColors.success,
                          ),
                          const Divider(height: 32, thickness: 0.5),
                          _buildTimelineRow(
                            'Monitoring Period',
                            '${widget.result.recoveryTimeline['monitoringDays'] ?? '30'} days',
                            LucideIcons.eye,
                            AppColors.primary,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  // Share/Copy Report
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: OutlinedButton.icon(
                      onPressed: _handleCopy,
                      icon: Icon(_copied ? LucideIcons.check : LucideIcons.share2, size: 18),
                      label: Text(_copied ? 'COPIED!' : 'SHARE ANALYSIS REPORT'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary, width: 2),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 60),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImage() {
    if (kIsWeb) {
      if (widget.result.imageUrl.startsWith('blob:') || widget.result.imageUrl.startsWith('data:')) {
        return Image.network(widget.result.imageUrl, fit: BoxFit.cover);
      }
    }
    
    final file = File(widget.result.imageUrl);
    if (!kIsWeb && file.existsSync()) {
      return Image.file(file, fit: BoxFit.cover);
    }
    return Container(
      color: AppColors.background,
      child: const Center(
        child: Icon(LucideIcons.leaf, size: 80, color: AppColors.textHint),
      ),
    );
  }

  Widget _buildMetricCard(String title, String value, IconData icon, {required Color color, double? progress}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(title, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                value,
                style: TextStyle(color: AppColors.textPrimary, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: -0.5),
              ),
              if (progress != null)
                SizedBox(
                  width: 36, height: 36,
                  child: CircularProgressIndicator(
                    value: progress,
                    strokeWidth: 4,
                    backgroundColor: AppColors.background,
                    valueColor: AlwaysStoppedAnimation<Color>(color),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(IconData icon, String title, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassInfoCard(String content, {required IconData icon, required Color iconColor}) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.primary.withOpacity(0.05)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              content,
              style: const TextStyle(
                color: AppColors.textPrimary,
                fontSize: 15,
                height: 1.6,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSymptomsTags() {
    final symptoms = widget.result.symptoms.split(',');
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: symptoms.map((s) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: AppColors.softShadow,
          border: Border.all(color: AppColors.primary.withOpacity(0.05)),
        ),
        child: Text(
          s.trim().toUpperCase(), 
          style: const TextStyle(color: AppColors.primary, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.5)
        ),
      )).toList(),
    );
  }

  Widget _buildTreatmentList() {
    final steps = _translatedSteps.isEmpty ? widget.result.treatmentSteps : _translatedSteps;
    
    if (steps.isEmpty) {
      return _buildGlassInfoCard('No specific treatment steps available.', icon: LucideIcons.info, iconColor: AppColors.info);
    }

    return TreatmentStepsWidget(
      steps: steps,
      themeColor: AppColors.primary,
    );
  }


  Widget _buildStepsList(List<String> steps, {String type = 'organic'}) {
    final structuredList = _structuredTreatments != null ? _structuredTreatments![type] as List? : null;

    if (steps.isEmpty && (structuredList == null || structuredList.isEmpty)) {
      return _buildGlassInfoCard('No steps available.', icon: LucideIcons.info, iconColor: AppColors.info);
    }

    return Column(
      children: [
        if (structuredList != null && structuredList.isNotEmpty)
          ...structuredList.map((item) {
            final name = item['name'] as String;
            final dosage = item['dosage'] as String;
            final frequency = item['frequency'] as String;
            
            return _buildDosageCard(name, dosage, frequency);
          }).toList(),
        
        ...List.generate(steps.length, (index) {
          final stepNumber = index + 1;
          final stepText = steps[index];

          return GestureDetector(
            onTap: () {
              TTSService.speakText(stepText, _targetLanguage);
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                boxShadow: AppColors.softShadow,
                border: Border.all(color: AppColors.primary.withOpacity(0.05)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        "$stepNumber",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      stepText,
                      style: TextStyle(
                        color: _isTranslating ? AppColors.textHint : AppColors.textPrimary,
                        fontSize: 15,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(LucideIcons.volume2, size: 18, color: AppColors.primary),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildDosageCard(String name, String dosage, String frequency) {
    final speechText = "Apply $name. Dosage $dosage. Repeat $frequency.";
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: GestureDetector(
        onTap: () => TTSService.speakText(speechText, _targetLanguage),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [AppColors.primary.withOpacity(0.08), AppColors.primary.withOpacity(0.02)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(LucideIcons.beaker, color: AppColors.primary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const Icon(LucideIcons.volume2, color: AppColors.primary, size: 18),
                ],
              ),
              const SizedBox(height: 16),
              _buildDosageInfoRow(LucideIcons.flaskConical, "Dosage: ", dosage),
              const SizedBox(height: 8),
              _buildDosageInfoRow(LucideIcons.calendar, "Frequency: ", frequency),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDosageInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary.withOpacity(0.6), size: 14),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeatmapViewer() {
    return Column(
      children: [
        GestureDetector(
          onTap: () => setState(() => _showHeatmapOverlay = !_showHeatmapOverlay),
          child: Container(
            height: 240,
            width: double.infinity,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              boxShadow: AppColors.softShadow,
              border: Border.all(color: AppColors.primary.withOpacity(0.1)),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (_showHeatmapOverlay && widget.result.heatmapBase64 != null)
                    Image.memory(
                      base64Decode(widget.result.heatmapBase64!),
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    )
                  else
                    _buildImage(),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: _showHeatmapOverlay
                            ? Colors.red.withOpacity(0.9)
                            : AppColors.primary.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showHeatmapOverlay ? LucideIcons.eye : LucideIcons.layers,
                            size: 14,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _showHeatmapOverlay ? 'SHOW ORIGINAL' : 'SHOW HEATMAP',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'TAP IMAGE TO TOGGLE ANALYSIS OVERLAY',
          style: TextStyle(
            color: AppColors.textHint, 
            fontSize: 11, 
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'severe':
      case 'high':
        return AppColors.error;
      case 'moderate':
      case 'medium':
        return AppColors.warning;
      case 'low':
      case 'healthy':
        return AppColors.success;
      default:
        return AppColors.info;
    }
  }

  Widget _buildTimelineRow(String label, String duration, IconData icon, Color color) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(0.1),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.textPrimary,
              fontSize: 15,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            duration,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }
}

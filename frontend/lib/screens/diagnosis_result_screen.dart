import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../models/analysis_result.dart';
import '../widgets/crop_advice_card.dart';
import '../services/feedback_service.dart';
import '../services/explanation_service.dart';
import '../services/preferences_service.dart';
import '../services/sarvam_tts_service.dart';
import '../services/tts_service.dart';
import '../widgets/treatment_steps_widget.dart';
import '../widgets/diagnosis_result_card.dart';
import '../widgets/advice_card.dart';
import '../widgets/treatment_card.dart';
import '../core/theme/app_colors.dart';
import 'chatbot_view.dart';
import 'dart:developer' as dev;

/// Full-screen diagnosis result screen (US17-20).
class DiagnosisResultScreen extends StatefulWidget {
  final AnalysisResult result;
  final VoidCallback onClose;

  const DiagnosisResultScreen({
    super.key,
    required this.result,
    required this.onClose,
  });

  @override
  State<DiagnosisResultScreen> createState() => _DiagnosisResultScreenState();
}

class _DiagnosisResultScreenState extends State<DiagnosisResultScreen>
    with TickerProviderStateMixin {
  bool _showHeatmap = false;
  late AnimationController _confidenceAnimController;
  late Animation<double> _confidenceAnim;
  late AnimationController _fadeController;
  late Animation<double> _fadeAnim;

  final Set<int> _checkedItems = {};

  String? _feedbackRating; 
  bool _showCommentBox = false;
  final TextEditingController _commentController = TextEditingController();
  bool _feedbackSubmitted = false;
  bool _feedbackSubmitting = false;

  String _activeLangCode = 'en';

  Map<String, String>? _translations;          
  List<String>? _txTreatmentSteps;             
  List<String>? _txPreventionChecklist;        
  List<String>? _txTopPredictionNames;         

  bool _isTranslating = false;
  String? _translationError;

  bool _isLoadingAudio = false;
  bool _isPlayingAudio = false;

  @override
  void initState() {
    super.initState();
    _confidenceAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _confidenceAnim = Tween<double>(begin: 0.0, end: widget.result.confidence)
        .animate(CurvedAnimation(
      parent: _confidenceAnimController,
      curve: Curves.easeOutCubic,
    ));
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _fadeController, curve: Curves.easeIn);

    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _confidenceAnimController.forward();
    });

    _loadInitialLanguage();
  }

  Future<void> _loadInitialLanguage() async {
    final langCode = await preferencesService.getLanguage() ?? 'en';
    final mappedCode = SarvamTTSService.mapToSarvamCode(langCode);
    if (mounted && mappedCode != 'en') {
      await Future.delayed(const Duration(milliseconds: 600));
      if (mounted) _changeLanguage(mappedCode);
    } else if (mounted) {
      setState(() => _activeLangCode = mappedCode);
    }
  }

  Future<void> _changeLanguage(String langCode) async {
    if (_isTranslating) return;
    setState(() {
      _activeLangCode = langCode;
      _isTranslating = true;
      _translationError = null;
      if (_isPlayingAudio) {
        SarvamTTSService.stop();
        _isPlayingAudio = false;
        _isLoadingAudio = false;
      }
    });

    try {
      final r = widget.result;
      final simpleExp = ExplanationService.getSimpleExplanation(r.disease);
      final diseaseName = _formatDiseaseName(r.disease);
      final severityDesc = r.severityDescription;
      final timelineDesc = r.recoveryTimeline['description'] as String? ?? '';

      final predNames = r.topPredictions
          .map((p) => p['disease'] as String? ?? '')
          .toList();

      final allTexts = [
        diseaseName,          
        simpleExp,            
        severityDesc,         
        timelineDesc,         
        ...r.treatmentSteps,  
        ...r.preventionChecklist, 
        ...predNames,         
      ];

      if (langCode == 'en') {
        setState(() {
          _translations = null;
          _txTreatmentSteps = null;
          _txPreventionChecklist = null;
          _txTopPredictionNames = null;
          _isTranslating = false;
        });
        return;
      }

      final translated = await SarvamTTSService.translateBatch(
        texts: allTexts,
        targetLangCode: langCode,
      );

      final int stepsLen = r.treatmentSteps.length;
      final int prevLen = r.preventionChecklist.length;
      final int predLen = predNames.length;

      setState(() {
        _translations = {
          'diseaseName':  translated[0],
          'simpleExp':    translated[1],
          'severityDesc': translated[2],
          'timelineDesc': translated[3],
        };
        _txTreatmentSteps = translated.sublist(4, 4 + stepsLen);
        _txPreventionChecklist = translated.sublist(4 + stepsLen, 4 + stepsLen + prevLen);
        _txTopPredictionNames = translated.sublist(4 + stepsLen + prevLen, 4 + stepsLen + prevLen + predLen);
        _isTranslating = false;
      });

    } catch (e) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _translationError = 'Translation failed. Showing English.';
        });
      }
    }
  }

  String _tx(String key, String englishFallback) {
    return _translations?[key] ?? englishFallback;
  }

  String _buildNarrationText() {
    final r = widget.result;
    final disease = _tx('diseaseName', _formatDiseaseName(r.disease));
    final simple  = _tx('simpleExp',  ExplanationService.getSimpleExplanation(r.disease));
    final sevDesc = _tx('severityDesc', r.severityDescription);
    final steps   = (_txTreatmentSteps ?? r.treatmentSteps).join('. ');
    final prev    = (_txPreventionChecklist ?? r.preventionChecklist).join('. ');

    return [
      if (disease.isNotEmpty) '$disease.',
      if (simple.isNotEmpty)  '$simple.',
      if (sevDesc.isNotEmpty) 'Severity assessment: $sevDesc.',
      if (steps.isNotEmpty)   'Treatment steps: $steps.',
      if (prev.isNotEmpty)    'Prevention tips: $prev.',
    ].join(' ');
  }

  Future<void> _toggleAudio() async {
    if (_isTranslating) return;
    if (_isLoadingAudio) return;

    if (_isPlayingAudio) {
      await SarvamTTSService.stop();
      await TTSService.stop();
      if (mounted) setState(() => _isPlayingAudio = false);
      return;
    }

    setState(() { _isLoadingAudio = true; });

    try {
      await SarvamTTSService.speak(
        text: _buildNarrationText(),
        langCode: _activeLangCode,
        onStart: () {
          if (mounted) setState(() { _isLoadingAudio = false; _isPlayingAudio = true; });
        },
        onComplete: () {
          if (mounted) setState(() => _isPlayingAudio = false);
        },
        onError: (err) async {
          debugPrint('Sarvam TTS failed, falling back to native: $err');
          // Fallback to native TTS if Sarvam fails (e.g. backend down)
          await _playNativeFallback();
        },
      );
    } catch (e) {
      await _playNativeFallback();
    }
  }

  Future<void> _playNativeFallback() async {
    try {
      if (mounted) setState(() { _isLoadingAudio = false; _isPlayingAudio = true; });
      await TTSService.speakText(_buildNarrationText(), _activeLangCode);
      if (mounted) setState(() => _isPlayingAudio = false);
    } catch (e) {
      if (mounted) setState(() { _isLoadingAudio = false; _isPlayingAudio = false; });
    }
  }

  @override
  void dispose() {
    _confidenceAnimController.dispose();
    _fadeController.dispose();
    _commentController.dispose();
    SarvamTTSService.stop();
    super.dispose();
  }

  void _openFullReport() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.92,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          child: CropAdviceCard(
            result: widget.result,
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  Color _severityColor(String level) {
    switch (level.toLowerCase()) {
      case 'severe':
        return AppColors.error;
      case 'moderate':
        return AppColors.warning;
      case 'mild':
        return AppColors.info;
      case 'healthy':
        return AppColors.success;
      default:
        return AppColors.gray400;
    }
  }

  IconData _severityIcon(String level) {
    switch (level.toLowerCase()) {
      case 'severe':
        return LucideIcons.alertOctagon;
      case 'moderate':
        return LucideIcons.alertTriangle;
      case 'mild':
        return LucideIcons.info;
      case 'healthy':
        return LucideIcons.checkCircle2;
      default:
        return LucideIcons.helpCircle;
    }
  }

  Color _confidenceColor(double confidence) {
    if (confidence >= 0.85) return AppColors.success;
    if (confidence >= 0.70) return AppColors.primary;
    if (confidence >= 0.55) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: FadeTransition(
        opacity: _fadeAnim,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildImageHeader(),
            if (widget.result.confidence < 0.70)
              SliverToBoxAdapter(
                child: _buildUncertaintyBanner(),
              ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildLanguageAudioBar(),
                    const SizedBox(height: 24),
                    DiagnosisResultCard(
                      diseaseName: _tx('diseaseName', _formatDiseaseName(widget.result.disease)),
                      cropName: widget.result.crop,
                      confidence: widget.result.confidence,
                      imagePath: widget.result.imageUrl,
                      onHeatmapTap: widget.result.heatmapBase64 != null ? () => setState(() => _showHeatmap = !_showHeatmap) : null,
                    ),
                    const SizedBox(height: 16),
                    AdviceCard(
                      title: "AI Analysis",
                      content: _tx('simpleExp', ExplanationService.getSimpleExplanation(widget.result.disease)),
                      icon: LucideIcons.sparkles,
                    ),
                    const SizedBox(height: 24),
                    _buildMetricsRow(),
                    const SizedBox(height: 24),
                    _buildMultipleDetectionsView(),
                    const SizedBox(height: 24),
                    _buildTreatmentStepsSection(),
                    const SizedBox(height: 24),
                    _buildTopPredictionsChart(),
                    const SizedBox(height: 24),
                    _buildSeverityDetailCard(),
                    const SizedBox(height: 24),
                    _buildRecoveryTimeline(),
                    const SizedBox(height: 24),
                    _buildPreventionChecklist(),
                    const SizedBox(height: 24),
                    _buildFeedbackSection(),
                    const SizedBox(height: 28),
                    _buildFullReportButton(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== LANGUAGE + AUDIO BAR ====================

  Widget _buildLanguageAudioBar() {
    final activeLang = SarvamTTSService.getLanguage(_activeLangCode) ??
        sarvamTTSLanguages.last;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
        border: Border.all(
          color: AppColors.primary.withOpacity(0.05),
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.languages,
                size: 16,
                color: AppColors.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _isTranslating
                      ? 'Translating to ${activeLang.name}...'
                      : _activeLangCode == 'en'
                          ? 'Select your language'
                          : 'Viewing in ${activeLang.nativeName}',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: AppColors.gray600,
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ),
              if (_isTranslating)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                )
              else
                GestureDetector(
                  onTap: _toggleAudio,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isPlayingAudio
                            ? [AppColors.error, AppColors.error.withOpacity(0.8)]
                            : [AppColors.primary, AppColors.nature600],
                      ),
                      borderRadius: BorderRadius.circular(100),
                      boxShadow: [
                        BoxShadow(
                          color: (_isPlayingAudio ? AppColors.error : AppColors.primary)
                              .withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isLoadingAudio
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.6,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(
                                _isPlayingAudio
                                    ? LucideIcons.stopCircle
                                    : LucideIcons.volume2,
                                size: 16,
                                color: Colors.white,
                              ),
                        const SizedBox(width: 6),
                        Text(
                          _isLoadingAudio ? '...' : _isPlayingAudio ? 'Stop' : 'Listen',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          if (_translationError != null) ...[
            const SizedBox(height: 8),
            Text(
              _translationError!,
              style: const TextStyle(color: AppColors.error, fontSize: 12),
            ),
          ],
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sarvamTTSLanguages.map((lang) {
              final isSelected = _activeLangCode == lang.code;
              return GestureDetector(
                onTap: _isTranslating ? null : () => _changeLanguage(lang.code),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.tan100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected ? AppColors.primary : Colors.transparent,
                    ),
                  ),
                  child: Text(
                    lang.nativeName,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.gray800,
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }


  // ==================== IMAGE HEADER WITH HEATMAP TOGGLE ====================

  Widget _buildImageHeader() {
    return SliverAppBar(
      expandedHeight: 340,
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (_showHeatmap && widget.result.heatmapBase64 != null)
              Image.memory(
                base64Decode(widget.result.heatmapBase64!),
                fit: BoxFit.cover,
                gaplessPlayback: true,
              )
            else
              _buildOriginalImage(),

            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black26,
                    Colors.transparent,
                    Colors.black54,
                  ],
                ),
              ),
            ),

            if (widget.result.heatmapBase64 != null)
              Positioned(
                bottom: 80,
                right: 20,
                child: _buildHeatmapToggle(),
              ),

            Positioned(
              bottom: 24,
              left: 20,
              right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(100),
                    ),
                    child: Text(
                      widget.result.crop.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    _formatDiseaseName(widget.result.disease),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      shadows: [Shadow(color: Colors.black45, blurRadius: 10, offset: Offset(0, 2))],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      leading: Padding(
        padding: const EdgeInsets.all(8.0),
        child: CircleAvatar(
          backgroundColor: Colors.white,
          child: IconButton(
            icon: const Icon(Icons.close, color: AppColors.gray800, size: 20),
            onPressed: widget.onClose,
          ),
        ),
      ),
    );
  }


  Widget _buildOriginalImage() {
    if (kIsWeb) {
      if (widget.result.imageUrl.startsWith('blob:') ||
          widget.result.imageUrl.startsWith('data:')) {
        return Image.network(widget.result.imageUrl, fit: BoxFit.cover);
      }
    }
    if (!kIsWeb) {
      final file = File(widget.result.imageUrl);
      if (file.existsSync()) {
        return Image.file(file, fit: BoxFit.cover);
      }
    }
    return Container(
      color: const Color(0xFF1E293B),
      child: const Center(
        child: Icon(Icons.eco, size: 80, color: Colors.white10),
      ),
    );
  }

  Widget _buildHeatmapToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showHeatmap = !_showHeatmap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _showHeatmap
              ? const Color(0xFFEF4444).withOpacity(0.25)
              : Colors.black54,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _showHeatmap
                ? const Color(0xFFEF4444).withOpacity(0.6)
                : Colors.white24,
          ),
          boxShadow: [
            BoxShadow(
              color: _showHeatmap
                  ? const Color(0xFFEF4444).withOpacity(0.3)
                  : Colors.transparent,
              blurRadius: 12,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _showHeatmap ? Icons.layers_clear : Icons.layers,
              color: _showHeatmap ? const Color(0xFFFCA5A5) : Colors.white70,
              size: 18,
            ),
            const SizedBox(width: 6),
            Text(
              _showHeatmap ? 'Hide Heatmap' : 'Show Heatmap',
              style: TextStyle(
                color: _showHeatmap ? const Color(0xFFFCA5A5) : Colors.white70,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== DISEASE IDENTIFICATION CARD (US17) ====================

  Widget _buildDiseaseIdentificationCard() {
    final isHealthy = widget.result.severityLevel.toLowerCase() == 'healthy' ||
        widget.result.disease.toLowerCase().contains('healthy');

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isHealthy
              ? [const Color(0xFF064E3B).withOpacity(0.5), const Color(0xFF065F46).withOpacity(0.3)]
              : [const Color(0xFF7F1D1D).withOpacity(0.3), const Color(0xFF991B1B).withOpacity(0.15)],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isHealthy
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFEF4444).withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isHealthy
                  ? const Color(0xFF10B981).withOpacity(0.2)
                  : const Color(0xFFEF4444).withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              isHealthy ? Icons.check_circle_rounded : LucideIcons.bug,
              color: isHealthy ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isHealthy ? 'No Disease Detected' : 'Disease Identified',
                  style: TextStyle(
                    color: isHealthy ? const Color(0xFF6EE7B7) : const Color(0xFFFCA5A5),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _tx('diseaseName', _formatDiseaseName(widget.result.disease)),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Crop: ${widget.result.crop}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== SIMPLE EXPLANATION (US23) ====================

  Widget _buildSimpleExplanationCard() {
    final simpleExp = _tx('simpleExp',
        ExplanationService.getSimpleExplanation(widget.result.disease));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.sparkles, size: 16, color: Colors.purple.shade300),
              const SizedBox(width: 8),
              Text(
                'Simple Explanation',
                style: TextStyle(
                  color: Colors.purple.shade300,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Text(
              simpleExp,
              key: ValueKey(simpleExp),
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 15,
                height: 1.5,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ],
      ),
    );
  }


  // ==================== TREATMENT STEPS (US25) ====================

  Widget _buildTreatmentStepsSection() {
    final steps = _txTreatmentSteps ?? widget.result.treatmentSteps;
    return TreatmentCard(
      title: "Recovery Plan",
      instructions: steps,
      type: widget.result.disease.toLowerCase().contains('healthy') 
          ? TreatmentType.organic : TreatmentType.chemical,
      dosage: "Follow local agricultural guidelines",
    );
  }


  // ==================== CONFIDENCE + SEVERITY METRICS (US18 + US19) ====================

  Widget _buildMetricsRow() {
    return Row(
      children: [
        // Confidence Score (US18)
        Expanded(child: _buildConfidenceCard()),
        const SizedBox(width: 14),
        // Severity Badge (US19)
        Expanded(child: _buildSeverityBadge()),
      ],
    );
  }

  Widget _buildConfidenceCard() {
    final color = _confidenceColor(widget.result.confidence);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(LucideIcons.activity, size: 14, color: AppColors.gray400),
              const SizedBox(width: 8),
              Text(
                'Confidence',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.gray500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          AnimatedBuilder(
            animation: _confidenceAnim,
            builder: (context, child) {
              return SizedBox(
                width: 80,
                height: 80,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 80,
                      height: 80,
                      child: CircularProgressIndicator(
                        value: _confidenceAnim.value,
                        strokeWidth: 8,
                        backgroundColor: AppColors.tan100,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '${(_confidenceAnim.value * 100).toInt()}%',
                      style: TextStyle(
                        color: color,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(100),
            ),
            child: Text(
              widget.result.confidence >= 0.85 ? 'OPTIMAL' : 'RELIABLE',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBadge() {
    final level = widget.result.severityLevel;
    final color = _severityColor(level);
    final icon = _severityIcon(level);
    final label = widget.result.severity;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(LucideIcons.thermometer, size: 14, color: AppColors.gray400),
              const SizedBox(width: 8),
              Text(
                'Urgency',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.gray500,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withOpacity(0.1),
            ),
            child: Icon(icon, color: color, size: 36),
          ),
          const SizedBox(height: 16),
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }


  // ==================== TOP-5 PREDICTIONS CHART (US18) ====================

  // ==================== MULTIPLE DETECTIONS (US22) ====================

  Widget _buildMultipleDetectionsView() {
    final predictions = widget.result.topPredictions;
    if (predictions.length < 2) return const SizedBox.shrink();

    // Significant secondary diseases (e.g., confidence > 25%)
    final secondaries = predictions.skip(1).where((p) => (p['confidence'] as num? ?? 0) > 0.25).toList();

    if (secondaries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(LucideIcons.binary, size: 18, color: Color(0xFFF472B6)),
            const SizedBox(width: 8),
            Text(
              'Co-occurring Conditions',
              style: TextStyle(
                color: Colors.white,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...secondaries.map((p) => _buildSecondaryDetectionCard(p)).toList(),
      ],
    );
  }

  Widget _buildSecondaryDetectionCard(Map<String, dynamic> pred) {
    final disease = pred['disease'] as String? ?? 'Unknown Condition';
    final conf = (pred['confidence'] as num? ?? 0).toDouble();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.accent.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accent.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.alertCircle, color: AppColors.accent, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  disease,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                Text(
                  'Secondary concern detected',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.gray500,
                      ),
                ),
              ],
            ),
          ),
          Text(
            '${(conf * 100).toInt()}%',
            style: const TextStyle(
              color: AppColors.accent,
              fontWeight: FontWeight.w900,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTopPredictionsChart() {
    final predictions = widget.result.topPredictions;
    if (predictions.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.barChart3, size: 18, color: AppColors.info),
            const SizedBox(width: 8),
            Text(
              'Alternative Possibilities',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            children: predictions.asMap().entries.map((entry) {
              final idx = entry.key;
              final pred = entry.value;
              final conf = (pred['confidence'] as num?)?.toDouble() ?? 0.0;
              final disease = (_txTopPredictionNames != null && idx < _txTopPredictionNames!.length)
                  ? _txTopPredictionNames![idx]
                  : (pred['disease'] as String? ?? 'Unknown');
              final crop = pred['crop'] as String? ?? '';
              final isTop = idx == 0;

              final barColor = isTop ? AppColors.success : AppColors.info;

              return Padding(
                padding: EdgeInsets.only(bottom: idx < predictions.length - 1 ? 16 : 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            disease,
                            style: TextStyle(
                              color: isTop ? AppColors.textPrimary : AppColors.textSecondary,
                              fontSize: 14,
                              fontWeight: isTop ? FontWeight.bold : FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '${(conf * 100).toInt()}%',
                          style: TextStyle(
                            color: isTop ? AppColors.primary : AppColors.textHint,
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: LinearProgressIndicator(
                        value: conf,
                        minHeight: 6,
                        backgroundColor: AppColors.tan100,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          barColor.withOpacity(isTop ? 1.0 : 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }


  // ==================== UNCERTAINTY WARNING (US21) ====================

  Widget _buildUncertaintyBanner() {
    dev.log(
      'Low confidence prediction detected',
      name: 'CropAID.Diagnosis',
      error: {'id': widget.result.id, 'disease': widget.result.disease, 'confidence': widget.result.confidence},
    );

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(LucideIcons.alertTriangle,
                    color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'UNCERTAIN RESULT',
                      style: TextStyle(
                        color: AppColors.warning,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.1,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'AI confidence is lower than usual. We recommend verification.',
                      style: TextStyle(
                        color: AppColors.gray700,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.onClose,
                  icon: const Icon(LucideIcons.refreshCw, size: 16),
                  label: const Text('RETRY'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.gray800,
                    side: const BorderSide(color: AppColors.gray300),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _openExpertConsult,
                  icon: const Icon(LucideIcons.bot, size: 16),
                  label: const Text('EXPERT AI'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }


  void _openExpertConsult() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ChatbotView(
        onClose: () => Navigator.pop(context),
        context: widget.result,
      ),
    );
  }

  // ==================== SEVERITY DETAIL CARD (US19) ====================

  Widget _buildSeverityDetailCard() {
    final level = widget.result.severityLevel;
    final color = _severityColor(level);
    final description = _tx('severityDesc', widget.result.severityDescription);

    if (description.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.1)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.target, color: color, size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Expert Assessment',
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.gray700,
                    fontSize: 15,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  // ==================== RECOVERY TIMELINE (US30) ====================

  Widget _buildRecoveryTimeline() {
    final timeline = widget.result.recoveryTimeline;
    if (timeline.isEmpty) return const SizedBox.shrink();

    final initialDays = timeline['initialDays'] ?? '3-5';
    final fullDays = timeline['fullRecoveryDays'] ?? '14-21';
    final monitorDays = timeline['monitoringDays'] ?? '30';

    final steps = [
      _TimelineStep('Treatment', '$initialDays days', AppColors.info, LucideIcons.droplets),
      _TimelineStep('Recovery', '$fullDays days', AppColors.success, LucideIcons.sprout),
      _TimelineStep('Stability', '$monitorDays days', AppColors.nature600, LucideIcons.shieldCheck),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.calendarDays, size: 18, color: AppColors.primary),
            const SizedBox(width: 8),
            Text(
              'Expected Timeline',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            children: [
              Row(
                children: steps.asMap().entries.expand((entry) {
                  final idx = entry.key;
                  final step = entry.value;
                  final widgets = <Widget>[
                    Expanded(
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: step.color.withOpacity(0.1),
                              border: Border.all(color: step.color.withOpacity(0.2), width: 2),
                            ),
                            child: Icon(step.icon, color: step.color, size: 22),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            step.label,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: AppColors.gray800,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            step.duration,
                            style: TextStyle(
                              color: step.color,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];

                  if (idx < steps.length - 1) {
                    widgets.add(
                      Padding(
                        padding: const EdgeInsets.only(bottom: 50),
                        child: Icon(LucideIcons.chevronRight, 
                          size: 16, color: AppColors.gray300),
                      ),
                    );
                  }
                  return widgets;
                }).toList(),
              ),
              if (timeline['description'] != null && (timeline['description'] as String).isNotEmpty) ...[
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.tan100,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    _tx('timelineDesc', timeline['description'] as String? ?? ''),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.gray600,
                      fontSize: 13,
                      height: 1.5,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }


  // ==================== PREVENTION CHECKLIST (US31) ====================

  Widget _buildPreventionChecklist() {
    final checklist = widget.result.preventionChecklist;
    if (checklist.isEmpty) return const SizedBox.shrink();

    final completedCount = _checkedItems.length;
    final totalCount = checklist.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.shieldCheck, size: 18, color: AppColors.success),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Care Checklist',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                borderRadius: BorderRadius.circular(100),
              ),
              child: Text(
                '$completedCount/$totalCount',
                style: const TextStyle(
                  color: AppColors.success,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.softShadow,
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(100),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: AppColors.tan100,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppColors.success),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...checklist.asMap().entries.map((entry) {
                final idx = entry.key;
                final tip = (_txPreventionChecklist != null && idx < _txPreventionChecklist!.length)
                    ? _txPreventionChecklist![idx] : entry.value;
                final isChecked = _checkedItems.contains(idx);

                return ListTile(
                  onTap: () => setState(() {
                    isChecked ? _checkedItems.remove(idx) : _checkedItems.add(idx);
                  }),
                  leading: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isChecked ? AppColors.success : Colors.transparent,
                      border: Border.all(
                        color: isChecked ? AppColors.success : AppColors.gray300,
                        width: 2,
                      ),
                    ),
                    child: isChecked 
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : const SizedBox(width: 14, height: 14),
                  ),
                  title: Text(
                    tip,
                    style: TextStyle(
                      color: isChecked ? AppColors.gray400 : AppColors.gray800,
                      fontSize: 14,
                      decoration: isChecked ? TextDecoration.lineThrough : null,
                    ),
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ],
    );
  }


  // ==================== TREATMENT FEEDBACK (US32) ====================

  Widget _buildFeedbackSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(LucideIcons.thumbsUp, size: 18, color: AppColors.nature600),
            const SizedBox(width: 8),
            Text(
              'Help us improve',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.softShadow,
          ),
          child: _feedbackSubmitted
              ? _buildFeedbackConfirmation()
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildFeedbackButton(
                            icon: LucideIcons.thumbsUp,
                            label: 'Helpful',
                            selected: _feedbackRating == 'helpful',
                            color: AppColors.success,
                            onTap: () => setState(() {
                              _feedbackRating = 'helpful';
                              _showCommentBox = true;
                            }),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildFeedbackButton(
                            icon: LucideIcons.thumbsDown,
                            label: 'Not Helpful',
                            selected: _feedbackRating == 'not_helpful',
                            color: AppColors.error,
                            onTap: () => setState(() {
                              _feedbackRating = 'not_helpful';
                              _showCommentBox = true;
                            }),
                          ),
                        ),
                      ],
                    ),
                    if (_showCommentBox) ...[
                      const SizedBox(height: 20),
                      TextField(
                        controller: _commentController,
                        maxLines: 3,
                        style: const TextStyle(color: AppColors.gray800, fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Any additional notes...',
                          filled: true,
                          fillColor: AppColors.tan100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _feedbackSubmitting ? null : _submitFeedback,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(100)),
                            elevation: 0,
                          ),
                          child: _feedbackSubmitting
                              ? const CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                              : const Text('SUBMIT FEEDBACK', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                        ),
                      ),
                    ],
                  ],
                ),
        ),
      ],
    );
  }


  Widget _buildFeedbackButton({
    required IconData icon,
    required String label,
    required bool selected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.1) : AppColors.background,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? color : AppColors.gray200,
            width: selected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? color : AppColors.gray400, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? color : AppColors.gray500,
                fontSize: 12,
                fontWeight: selected ? FontWeight.w900 : FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackConfirmation() {
    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.success.withOpacity(0.1),
          ),
          child: const Icon(LucideIcons.checkCircle2, color: AppColors.success, size: 32),
        ),
        const SizedBox(height: 16),
        const Text(
          'Feedback Received!',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Your input helps improve treatment recommendations for everyone.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Future<void> _submitFeedback() async {
    if (_feedbackRating == null) return;

    setState(() => _feedbackSubmitting = true);

    await FeedbackService.submitFeedback(
      diagnosisId: widget.result.id,
      rating: _feedbackRating!,
      comment: _commentController.text.trim(),
      crop: widget.result.crop,
      disease: widget.result.disease,
      severity: widget.result.severity,
    );

    if (mounted) {
      setState(() {
        _feedbackSubmitting = false;
        _feedbackSubmitted = true;
      });
    }
  }

  // ==================== FULL REPORT BUTTON ====================

  Widget _buildFullReportButton() {
    return Container(
      width: double.infinity,
      height: 64,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _openFullReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.fileText, size: 20),
            SizedBox(width: 12),
            Text(
              'VIEW DETAILED ANALYSIS',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ==================== HELPERS ====================

  String _formatDiseaseName(String raw) {
    // "Tomato___Early_blight" → "Early Blight"
    String name = raw;
    if (name.contains('___')) {
      name = name.split('___').last;
    }
    name = name.replaceAll('_', ' ');
    // Title case
    return name
        .split(' ')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

/// Data class for timeline step visualization (US30).
class _TimelineStep {
  final String label;
  final String duration;
  final Color color;
  final IconData icon;

  _TimelineStep(this.label, this.duration, this.color, this.icon);
}

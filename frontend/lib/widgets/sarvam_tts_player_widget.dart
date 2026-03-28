import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/sarvam_tts_service.dart';

/// Full-featured Sarvam AI diagnosis reader widget.
///
/// Flow:
///  1. User picks a language chip → translation is triggered automatically
///  2. The translated text appears inside an expandable card in that language's script
///  3. User presses ▶ to hear the translated text read aloud in that language
class SarvamTTSPlayerWidget extends StatefulWidget {
  /// The English source text (diagnosis summary)
  final String englishText;

  /// Initial language code from user preferences
  final String initialLangCode;

  const SarvamTTSPlayerWidget({
    super.key,
    required this.englishText,
    this.initialLangCode = 'en',
  });

  @override
  State<SarvamTTSPlayerWidget> createState() => _SarvamTTSPlayerWidgetState();
}

class _SarvamTTSPlayerWidgetState extends State<SarvamTTSPlayerWidget>
    with SingleTickerProviderStateMixin {
  // ── State ─────────────────────────────────────────────────────────────
  late String _selectedLangCode;

  // Translation
  bool _isTranslating = false;
  String? _translatedText;
  String? _translationError;
  bool _showTranslatedText = true;

  // Audio
  bool _isLoadingAudio = false;
  bool _isPlaying = false;
  String? _audioError;

  // Animation
  late AnimationController _pulseController;
  late Animation<double> _pulseAnim;

  // Per-language caches (so switching is instant after first load)
  final Map<String, String> _translationCache = {};

  @override
  void initState() {
    super.initState();
    _selectedLangCode = _resolveInitialLang(widget.initialLangCode);

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Trigger translation for the initial language
    _translateForLang(_selectedLangCode);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    SarvamTTSService.stop();
    super.dispose();
  }

  // ── Resolve language ───────────────────────────────────────────────────
  String _resolveInitialLang(String code) {
    return sarvamTTSLanguages.any((l) => l.code == code) ? code : 'en';
  }

  // ── Translation ────────────────────────────────────────────────────────
  Future<void> _translateForLang(String langCode) async {
    // Instantly serve from widget-level cache
    if (_translationCache.containsKey(langCode)) {
      if (mounted) {
        setState(() {
          _translatedText = _translationCache[langCode];
          _translationError = null;
          _audioError = null;
        });
      }
      return;
    }

    if (mounted) {
      setState(() {
        _isTranslating = true;
        _translatedText = null;
        _translationError = null;
        _audioError = null;
      });
    }

    try {
      final result = await SarvamTTSService.translate(
        englishText: widget.englishText,
        targetLangCode: langCode,
      );

      _translationCache[langCode] = result.translatedText;

      if (mounted) {
        setState(() {
          _isTranslating = false;
          _translatedText = result.translatedText;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isTranslating = false;
          _translationError = _friendlyError(e.toString());
        });
      }
    }
  }

  // ── Language selection ─────────────────────────────────────────────────
  void _selectLang(String langCode) {
    if (langCode == _selectedLangCode) return;
    if (_isPlaying || _isLoadingAudio) {
      SarvamTTSService.stop();
    }
    setState(() {
      _selectedLangCode = langCode;
      _isPlaying = false;
      _isLoadingAudio = false;
      _audioError = null;
    });
    _translateForLang(langCode);
  }

  // ── Audio playback ─────────────────────────────────────────────────────
  Future<void> _togglePlay() async {
    if (_isTranslating || _translatedText == null) return;

    if (_isLoadingAudio) return;

    if (_isPlaying) {
      await SarvamTTSService.stop();
      if (mounted) setState(() => _isPlaying = false);
      return;
    }

    setState(() {
      _isLoadingAudio = true;
      _audioError = null;
    });

    await SarvamTTSService.speak(
      text: _translatedText!,   // ← translated text, not English!
      langCode: _selectedLangCode,
      pace: 1.0,
      onStart: () {
        if (mounted) setState(() { _isLoadingAudio = false; _isPlaying = true; });
      },
      onComplete: () {
        if (mounted) setState(() => _isPlaying = false);
      },
      onError: (err) {
        if (mounted) {
          setState(() {
            _isLoadingAudio = false;
            _isPlaying = false;
            _audioError = _friendlyError(err);
          });
        }
      },
    );
  }

  String _friendlyError(String raw) {
    if (raw.contains('SocketException') || raw.contains('Connection refused')) {
      return 'Cannot reach backend server. Is it running on port 5000?';
    }
    if (raw.contains('timeout') || raw.contains('TimeoutException')) {
      return 'Request timed out. Please try again.';
    }
    return 'Something went wrong. Please try again.';
  }

  // ── Build ──────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final selectedLang = SarvamTTSService.getLanguage(_selectedLangCode) ??
        sarvamTTSLanguages.last;

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: const Color(0xFF6366F1).withOpacity(0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withOpacity(0.12),
            blurRadius: 28,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          _buildLanguageChips(),
          _buildTranslatedTextCard(selectedLang),
          if (_audioError != null) _buildErrorBanner(_audioError!),
          _buildPlayControls(selectedLang),
        ],
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(LucideIcons.volume2, size: 18, color: Color(0xFF818CF8)),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Diagnosis in Your Language',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Translated & spoken by Sarvam AI',
                style: TextStyle(
                  color: const Color(0xFF818CF8).withOpacity(0.8),
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: const Color(0xFF6366F1).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
            ),
            child: const Text(
              'bulbul:v3',
              style: TextStyle(color: Color(0xFF818CF8), fontSize: 10, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  // ── Language chips ─────────────────────────────────────────────────────
  Widget _buildLanguageChips() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SELECT LANGUAGE',
            style: TextStyle(
              color: Colors.white.withOpacity(0.4),
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sarvamTTSLanguages.map((lang) {
              final isSelected = _selectedLangCode == lang.code;
              return GestureDetector(
                onTap: () => _selectLang(lang.code),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xFF6366F1).withOpacity(0.3)
                        : Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected
                          ? const Color(0xFF818CF8)
                          : Colors.white.withOpacity(0.1),
                      width: isSelected ? 1.5 : 1,
                    ),
                    boxShadow: isSelected
                        ? [BoxShadow(color: const Color(0xFF6366F1).withOpacity(0.25), blurRadius: 10)]
                        : [],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        lang.nativeName,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.white.withOpacity(0.55),
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                        ),
                      ),
                      if (!isSelected) ...[
                        const SizedBox(height: 1),
                        Text(
                          lang.name,
                          style: TextStyle(color: Colors.white.withOpacity(0.3), fontSize: 10),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ── Translated text card ───────────────────────────────────────────────
  Widget _buildTranslatedTextCard(SarvamLanguage lang) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card header with toggle
            InkWell(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
              onTap: () => setState(() => _showTranslatedText = !_showTranslatedText),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    Icon(LucideIcons.fileText, size: 14, color: const Color(0xFF818CF8).withOpacity(0.8)),
                    const SizedBox(width: 8),
                    Text(
                      '${lang.name} Translation',
                      style: TextStyle(
                        color: const Color(0xFF818CF8).withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const Spacer(),
                    if (_isTranslating)
                      const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF818CF8)),
                        ),
                      )
                    else
                      Icon(
                        _showTranslatedText ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                        size: 18,
                        color: Colors.white.withOpacity(0.4),
                      ),
                  ],
                ),
              ),
            ),

            // Text body
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 250),
              crossFadeState: _showTranslatedText
                  ? CrossFadeState.showFirst
                  : CrossFadeState.showSecond,
              firstChild: _buildTranslationBody(lang),
              secondChild: const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranslationBody(SarvamLanguage lang) {
    if (_isTranslating) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Column(
          children: List.generate(
            3,
            (i) => Container(
              height: 12,
              width: double.infinity,
              margin: EdgeInsets.only(top: 8, right: i == 1 ? 60 : 0),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      );
    }

    if (_translationError != null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        child: Row(
          children: [
            const Icon(LucideIcons.alertCircle, size: 13, color: Color(0xFFFCA5A5)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _translationError!,
                style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12),
              ),
            ),
          ],
        ),
      );
    }

    if (_translatedText == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
      child: Text(
        _translatedText!,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14.5,
          height: 1.65,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  // ── Error banner ───────────────────────────────────────────────────────
  Widget _buildErrorBanner(String msg) {
    return Container(
      margin: const EdgeInsets.fromLTRB(18, 10, 18, 0),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, size: 13, color: Color(0xFFFCA5A5)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(msg, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 12)),
          ),
        ],
      ),
    );
  }

  // ── Play controls ──────────────────────────────────────────────────────
  Widget _buildPlayControls(SarvamLanguage lang) {
    final canPlay = !_isTranslating && _translatedText != null && _translationError == null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
      child: Row(
        children: [
          // Play / loading / stop button
          GestureDetector(
            onTap: canPlay ? _togglePlay : null,
            child: AnimatedBuilder(
              animation: _pulseAnim,
              builder: (context, child) => Transform.scale(
                scale: _isPlaying ? _pulseAnim.value : 1.0,
                child: child,
              ),
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: !canPlay
                        ? [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.03)]
                        : _isLoadingAudio
                            ? [Colors.white.withOpacity(0.12), Colors.white.withOpacity(0.06)]
                            : _isPlaying
                                ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                                : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
                  ),
                  boxShadow: canPlay
                      ? [
                          BoxShadow(
                            color: _isPlaying
                                ? const Color(0xFFEF4444).withOpacity(0.4)
                                : const Color(0xFF6366F1).withOpacity(0.4),
                            blurRadius: 16,
                            spreadRadius: 1,
                          )
                        ]
                      : [],
                ),
                child: _isLoadingAudio
                    ? const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                        ),
                      )
                    : Icon(
                        _isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded,
                        color: canPlay ? Colors.white : Colors.white24,
                        size: 28,
                      ),
              ),
            ),
          ),
          const SizedBox(width: 14),

          // Status text
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isTranslating
                      ? 'Translating to ${lang.nativeName}...'
                      : _isLoadingAudio
                          ? 'Generating ${lang.name} audio...'
                          : _isPlaying
                              ? 'Playing in ${lang.nativeName}'
                              : canPlay
                                  ? 'Tap ▶ to hear in ${lang.nativeName}'
                                  : 'Awaiting translation...',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _isTranslating
                      ? 'Using Sarvam sarvam-translate:v1'
                      : _isLoadingAudio
                          ? 'Calling Sarvam bulbul:v3...'
                          : _isPlaying
                              ? 'Tap ⏹ to stop'
                              : '${lang.name} · Indian voice · bulbul:v3',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 11,
                  ),
                ),
                if (_isPlaying) ...[
                  const SizedBox(height: 6),
                  _buildWaveform(),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Animated waveform ──────────────────────────────────────────────────
  Widget _buildWaveform() {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) => Row(
        children: List.generate(12, (i) {
          final h = 4.0 + 8.0 * (i % 3 == 0
              ? _pulseAnim.value
              : i % 3 == 1
                  ? (1 - _pulseAnim.value + 0.2)
                  : 0.6);
          return Container(
            width: 3,
            height: h.clamp(3.0, 16.0),
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: BoxDecoration(
              color: const Color(0xFF818CF8),
              borderRadius: BorderRadius.circular(2),
            ),
          );
        }),
      ),
    );
  }
}

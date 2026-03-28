import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../services/voice_chat_service.dart';

// ─── Language config ────────────────────────────────────────────────────────
class _Lang {
  final String code;    // 2-letter code sent to backend
  final String name;    // Display name in that script
  final String locale;  // speech_to_text locale id
  const _Lang(this.code, this.name, this.locale);
}

const List<_Lang> _kLangs = [
  _Lang('en', 'English',   'en_IN'),
  _Lang('hi', 'हिन्दी',     'hi_IN'),
  _Lang('te', 'తెలుగు',    'te_IN'),
  _Lang('ta', 'தமிழ்',     'ta_IN'),
  _Lang('kn', 'ಕನ್ನಡ',    'kn_IN'),
  _Lang('ml', 'മലയാളം',   'ml_IN'),
  _Lang('bn', 'বাংলা',     'bn_IN'),
  _Lang('mr', 'मराठी',     'mr_IN'),
];

// ─── Message model ──────────────────────────────────────────────────────────
enum _Role { user, ai }

class _Msg {
  final _Role     role;
  final String    text;
  final Uint8List? audio;
  final DateTime  time;
  _Msg({required this.role, required this.text, this.audio})
      : time = DateTime.now();
}

// ─── View ───────────────────────────────────────────────────────────────────

/// Voice Doctor — multilingual voice chatbot.
///
/// 1. User picks a language from the pill row.
/// 2. Taps & holds the mic → device STT transcribes speech in that language.
/// 3. On release, transcript is sent to /api/speech/text-chat.
/// 4. Backend: Gemini LLM answers → translated to user's language → Sarvam TTS.
/// 5. Answer is shown as a chat bubble and the audio auto-plays.
class VoiceDoctorView extends StatefulWidget {
  final VoidCallback? onBack;
  const VoiceDoctorView({super.key, this.onBack});

  @override
  State<VoiceDoctorView> createState() => _VoiceDoctorViewState();
}

class _VoiceDoctorViewState extends State<VoiceDoctorView>
    with SingleTickerProviderStateMixin {

  // ── Language ──────────────────────────────────────────────────────────────
  int _langIdx = 0;
  _Lang get _lang => _kLangs[_langIdx];

  // ── STT ───────────────────────────────────────────────────────────────────
  final stt.SpeechToText _stt = stt.SpeechToText();
  bool _sttReady    = false;
  bool _isListening = false;
  String _liveText  = '';   // live partial transcript

  // ── Chat ──────────────────────────────────────────────────────────────────
  final List<_Msg> _msgs = [];
  bool _isProcessing = false;

  // ── Audio playback ────────────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();
  String? _playingId;

  // ── Scroll ────────────────────────────────────────────────────────────────
  final ScrollController _scroll = ScrollController();

  // ── Pulse animation ───────────────────────────────────────────────────────
  late AnimationController _pulse;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _initSTT();
  }

  @override
  void dispose() {
    _pulse.dispose();
    _stt.stop();
    _player.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _initSTT() async {
    final ok = await _stt.initialize(
      onError: (e) => debugPrint('[STT] error: $e'),
      onStatus: (s) {
        if (s == 'done' || s == 'notListening') {
          if (mounted && _isListening) _onSpeechDone();
        }
      },
    );
    if (mounted) setState(() => _sttReady = ok);
  }

  // ─── Mic tap ─────────────────────────────────────────────────────────────
  void _onMicTap() {
    if (_isProcessing) return;
    _isListening ? _stopListening() : _startListening();
  }

  void _startListening() async {
    if (!_sttReady) {
      _showSnack('Speech recognition not available on this device.');
      return;
    }
    setState(() {
      _isListening = true;
      _liveText = '';
    });
    await _stt.listen(
      onResult: (r) {
        if (mounted) setState(() => _liveText = r.recognizedWords);
        if (r.finalResult && r.recognizedWords.isNotEmpty) {
          _stopListening();
        }
      },
      localeId: _lang.locale,
      listenFor: const Duration(seconds: 30),
      pauseFor: const Duration(seconds: 3),
      cancelOnError: true,
    );
  }

  void _stopListening() async {
    await _stt.stop();
    if (mounted) setState(() => _isListening = false);
    _onSpeechDone();
  }

  void _onSpeechDone() {
    final text = _liveText.trim();
    setState(() => _liveText = '');
    if (text.isEmpty) return;
    _sendMessage(text);
  }

  // ─── Send message ─────────────────────────────────────────────────────────
  Future<void> _sendMessage(String text) async {
    _addMsg(_Msg(role: _Role.user, text: text));
    _scrollToBottom();

    setState(() => _isProcessing = true);

    try {
      final result = await VoiceChatService.sendTextMessage(
        transcript: text,
        langCode: _lang.code,
      );

      final aiMsg = _Msg(
        role: _Role.ai,
        text: result.answer,
        audio: result.audioData,
      );
      _addMsg(aiMsg);
      _scrollToBottom();

      if (result.audioData != null) {
        await _playAudio(result.audioData!, id: aiMsg.hashCode.toString());
      }
    } on Exception catch (e) {
      final msg = e.toString().replaceFirst('Exception: ', '');
      _addMsg(_Msg(role: _Role.ai, text: '⚠️ $msg'));
      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  // ─── Audio ────────────────────────────────────────────────────────────────
  Future<void> _playAudio(Uint8List bytes, {required String id}) async {
    await _player.stop();
    if (mounted) setState(() => _playingId = id);
    try {
      await _player.play(BytesSource(bytes));
      await _player.onPlayerComplete.first;
    } catch (_) {}
    if (mounted) setState(() => _playingId = null);
  }

  Future<void> _stopAudio() async {
    await _player.stop();
    if (mounted) setState(() => _playingId = null);
  }

  bool get _isAudioPlaying => _playingId != null;

  // ─── Helpers ──────────────────────────────────────────────────────────────
  void _addMsg(_Msg m) { if (mounted) setState(() => _msgs.add(m)); }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent + 160,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: const Color(0xFF1E3A5F),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A1628),
      appBar: _appBar(),
      body: Column(
        children: [
          _langBar(),
          Expanded(child: _chatArea()),
          _micBar(),
        ],
      ),
    );
  }

  // ─── AppBar ───────────────────────────────────────────────────────────────
  PreferredSizeWidget _appBar() => AppBar(
    backgroundColor: const Color(0xFF0D1B2E),
    elevation: 0,
    leading: IconButton(
      icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Colors.white70),
      onPressed: widget.onBack ?? () => Navigator.pop(context),
    ),
    title: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)]),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(LucideIcons.mic, size: 18, color: Colors.white),
        ),
        const SizedBox(width: 10),
        const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voice Doctor',
                style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            Text('Sarvam AI · Gemini',
                style: TextStyle(color: Colors.white38, fontSize: 10)),
          ],
        ),
      ],
    ),
    actions: [
      if (_msgs.isNotEmpty)
        IconButton(
          icon: const Icon(LucideIcons.trash2, size: 18, color: Colors.white30),
          tooltip: 'Clear chat',
          onPressed: () => setState(() => _msgs.clear()),
        ),
    ],
  );

  // ─── Language pills ───────────────────────────────────────────────────────
  Widget _langBar() => Container(
    height: 50,
    color: const Color(0xFF0D1B2E),
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      itemCount: _kLangs.length,
      itemBuilder: (_, i) {
        final sel = i == _langIdx;
        return GestureDetector(
          onTap: () => setState(() => _langIdx = i),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            margin: const EdgeInsets.only(right: 8),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              gradient: sel
                  ? const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF059669)])
                  : null,
              color: sel ? null : Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
              border: sel ? null : Border.all(color: Colors.white.withOpacity(0.1)),
            ),
            child: Text(
              _kLangs[i].name,
              style: TextStyle(
                fontSize: 12,
                fontWeight: sel ? FontWeight.bold : FontWeight.normal,
                color: sel ? Colors.white : Colors.white54,
              ),
            ),
          ),
        );
      },
    ),
  );

  // ─── Chat area ────────────────────────────────────────────────────────────
  Widget _chatArea() {
    if (_msgs.isEmpty && !_isListening && !_isProcessing) return _emptyState();
    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      itemCount: _msgs.length + (_isProcessing ? 1 : 0) + (_isListening ? 1 : 0),
      itemBuilder: (_, i) {
        // Live listening bubble at top if listening
        if (_isListening && i == 0 && _msgs.isEmpty) return _listeningBubble();
        final offset = _isListening && _msgs.isEmpty ? 1 : 0;
        if (_isProcessing && i == _msgs.length + offset) return _thinkingBubble();
        if (_isListening && i == _msgs.length) return _listeningBubble();
        return _bubble(_msgs[i - offset]);
      },
    );
  }

  Widget _emptyState() => Center(
    child: SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 8),
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Transform.scale(
              scale: 1.0 + 0.04 * _pulse.value,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 28, spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(Icons.mic_rounded, size: 36, color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ask anything about your crops',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Colors.white.withOpacity(0.85),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Speak in ${_lang.name} — I\'ll reply in ${_lang.name}\nwith voice & text',
            style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.38), height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          ...[
            '🌿 My tomato leaves have yellow spots',
            '🪲 Remove pests without chemicals?',
            '💧 When to water my rice crop?',
          ].map((s) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.16)),
              ),
              child: Text(s,
                style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.45)),
                textAlign: TextAlign.center,
              ),
            ),
          )),
        ],
      ),
    ),
  );

  // ─── Bubbles ──────────────────────────────────────────────────────────────
  Widget _bubble(_Msg msg) {
    final isUser = msg.role == _Role.user;
    final id = msg.hashCode.toString();
    final playing = _playingId == id;

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[_ava(false), const SizedBox(width: 8)],
          Flexible(
            child: Column(
              crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    gradient: isUser
                        ? const LinearGradient(
                            colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
                            begin: Alignment.topLeft, end: Alignment.bottomRight,
                          )
                        : null,
                    color: isUser ? null : const Color(0xFF162032),
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isUser ? 18 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 18),
                    ),
                    border: isUser ? null
                        : Border.all(color: const Color(0xFF10B981).withOpacity(0.14)),
                    boxShadow: [BoxShadow(
                      color: (isUser ? const Color(0xFF3B82F6) : const Color(0xFF10B981))
                          .withOpacity(0.10),
                      blurRadius: 12, offset: const Offset(0, 4),
                    )],
                  ),
                  child: Text(msg.text,
                    style: TextStyle(
                      fontSize: 14.5,
                      color: Colors.white.withOpacity(isUser ? 0.95 : 0.85),
                      height: 1.55,
                    ),
                  ),
                ),
                // Play button on AI messages
                if (!isUser && msg.audio != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: GestureDetector(
                      onTap: () => _playAudio(msg.audio!, id: id),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: playing
                              ? const Color(0xFF10B981).withOpacity(0.14)
                              : Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: playing
                              ? const Color(0xFF10B981).withOpacity(0.5)
                              : Colors.white.withOpacity(0.09)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              playing ? Icons.stop_rounded : Icons.play_arrow_rounded,
                              size: 16,
                              color: playing ? const Color(0xFF10B981) : Colors.white.withOpacity(0.4),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              playing ? 'Playing…' : 'Play voice',
                              style: TextStyle(
                                fontSize: 11,
                                color: playing ? const Color(0xFF10B981) : Colors.white.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  '${msg.time.hour.toString().padLeft(2,'0')}:${msg.time.minute.toString().padLeft(2,'0')}',
                  style: TextStyle(fontSize: 10, color: Colors.white.withOpacity(0.22)),
                ),
              ],
            ),
          ),
          if (isUser) ...[const SizedBox(width: 8), _ava(true)],
        ],
      ),
    );
  }

  Widget _listeningBubble() => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E3A5F),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(18),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(4),
                  ),
                  border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (_, __) => Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Color.lerp(const Color(0xFFEF4444), const Color(0xFFFF6B6B), _pulse.value),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        _liveText.isEmpty ? 'Listening in ${_lang.name}…' : _liveText,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(_liveText.isEmpty ? 0.5 : 0.9),
                          fontStyle: _liveText.isEmpty ? FontStyle.italic : FontStyle.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        _ava(true),
      ],
    ),
  );

  Widget _thinkingBubble() => Padding(
    padding: const EdgeInsets.only(bottom: 14),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        _ava(false),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF162032),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18), topRight: Radius.circular(18),
              bottomRight: Radius.circular(18), bottomLeft: Radius.circular(4),
            ),
            border: Border.all(color: const Color(0xFF10B981).withOpacity(0.12)),
          ),
          child: AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(3, (i) {
                final v = ((_pulse.value + i * 0.25) % 1.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: 6, height: 6 + 8 * v,
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Text('Thinking…',
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.28))),
      ],
    ),
  );

  Widget _ava(bool isUser) => Container(
    width: 30, height: 30,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      gradient: LinearGradient(
        colors: isUser
            ? [const Color(0xFF3B82F6), const Color(0xFF2563EB)]
            : [const Color(0xFF10B981), const Color(0xFF059669)],
      ),
    ),
    child: Icon(isUser ? LucideIcons.user : LucideIcons.brain, size: 15, color: Colors.white),
  );

  // ─── Mic bar ──────────────────────────────────────────────────────────────
  Widget _micBar() => Container(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
    decoration: BoxDecoration(
      color: const Color(0xFF0D1B2E),
      border: Border(top: BorderSide(color: Colors.white.withOpacity(0.06))),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_isListening) ...[
          // Waveform
          AnimatedBuilder(
            animation: _pulse,
            builder: (_, __) => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(13, (i) {
                final c = (i - 6).abs() * 0.1;
                final h = 4.0 + 24.0 * ((_pulse.value + c * 1.8) % 1.0);
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  width: 3, height: h,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withOpacity(0.75),
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 10),
        ],
        // ── Buttons row ──
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Stop audio button — shown when TTS is playing
            if (_isAudioPlaying) ...[
              GestureDetector(
                onTap: _stopAudio,
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFFEF4444).withOpacity(0.15),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.5)),
                  ),
                  child: const Icon(Icons.stop_rounded, size: 24, color: Color(0xFFEF4444)),
                ),
              ),
              const SizedBox(width: 20),
            ],
            // Main mic button
            GestureDetector(
              onTap: _onMicTap,
              child: AnimatedBuilder(
                animation: _pulse,
                builder: (_, __) {
                  final s = _isListening ? 1.0 + 0.06 * _pulse.value : 1.0;
                  final g = _isListening ? 28.0 + 14.0 * _pulse.value
                      : (_isProcessing ? 10.0 : 18.0);
                  return Transform.scale(
                    scale: s,
                    child: Container(
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _isProcessing
                              ? [const Color(0xFF475569), const Color(0xFF334155)]
                              : _isListening
                                  ? [const Color(0xFFEF4444), const Color(0xFFDC2626)]
                                  : [const Color(0xFF10B981), const Color(0xFF059669)],
                        ),
                        boxShadow: [BoxShadow(
                          color: (_isListening
                                  ? const Color(0xFFEF4444)
                                  : const Color(0xFF10B981))
                              .withOpacity(_isProcessing ? 0.08 : 0.38),
                          blurRadius: g, spreadRadius: 2,
                        )],
                      ),
                      child: _isProcessing
                          ? const Padding(
                              padding: EdgeInsets.all(20),
                              child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                            )
                          : Icon(
                              _isListening ? Icons.stop_rounded : Icons.mic_rounded,
                              size: 30, color: Colors.white,
                            ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          _isAudioPlaying
              ? 'Tap ■ to stop voice playback'
              : _isProcessing
                  ? 'Getting answer from Gemini…'
                  : _isListening
                      ? 'Tap ■ to stop  •  Speak clearly'
                      : _sttReady
                          ? 'Tap to speak in ${_lang.name}'
                          : 'Initialising microphone…',
          style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.32)),
        ),
      ],
    ),
  );
}

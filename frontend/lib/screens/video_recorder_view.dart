// Imports
import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:video_player/video_player.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/translation_service.dart';
import '../services/audio_service.dart';

/// Video Recorder View - Record short videos for diagnosis
/// US13: Record short videos with duration limits
/// US16: Confirmation of captured input
class VideoRecorderView extends StatefulWidget {
  final VoidCallback onBack;
  final Function(String videoPath) onVideoRecorded;

  const VideoRecorderView({
    super.key,
    required this.onBack,
    required this.onVideoRecorded,
  });

  @override
  State<VideoRecorderView> createState() => _VideoRecorderViewState();
}

class _VideoRecorderViewState extends State<VideoRecorderView> {
  final ImagePicker _picker = ImagePicker();
  bool _isRecording = false;
  bool _hasVideo = false;
  XFile? _recordedVideo;
  int _recordingDuration = 0;
  Timer? _durationTimer;
  VideoPlayerController? _videoController;
  
  // US13: Duration limit (30 seconds)
  static const int maxDurationSeconds = 30;

  @override
  void initState() {
    super.initState();
    audioService.speak('Record a short video showing your plant symptoms.');
  }

  @override
  void dispose() {
    _durationTimer?.cancel();
    _videoController?.dispose();
    super.dispose();
  }

  /// US13: Record or select video
  Future<void> _startRecording() async {
    if (_isRecording) return;

    setState(() {
      _isRecording = true;
      _recordingDuration = 0;
    });

    // Start duration timer for UI feedback
    _durationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() => _recordingDuration++);
      if (_recordingDuration >= maxDurationSeconds) {
        _stopRecording();
      }
    });

    try {
      final XFile? video = await _picker.pickVideo(
        source: kIsWeb ? ImageSource.gallery : ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxDuration: const Duration(seconds: maxDurationSeconds),
      );

      _durationTimer?.cancel();

      if (video != null) {
        await _initializeVideoPlayer(video);
        setState(() {
          _isRecording = false;
          _hasVideo = true;
          _recordedVideo = video;
        });
        
        // US16: Confirmation
        audioService.confirmAction('success', message: 'Video recorded successfully');
      } else {
        _stopRecording(); // Reset state if cancelled
      }
    } catch (e) {
      _stopRecording();
      debugPrint('Error recording video: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  Future<void> _initializeVideoPlayer(XFile video) async {
    _videoController?.dispose();
    
    if (kIsWeb) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(video.path));
    } else {
      _videoController = VideoPlayerController.file(File(video.path));
    }

    try {
      await _videoController!.initialize();
      await _videoController!.setLooping(true);
      await _videoController!.play();
      setState(() {});
    } catch (e) {
      debugPrint('Error initializing video player: $e');
    }
  }

  void _stopRecording() {
    _durationTimer?.cancel();
    setState(() {
      _isRecording = false;
    });
  }

  String _formatDuration(int seconds) {
    final mins = seconds ~/ 60;
    final secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _retakeVideo() {
    _videoController?.pause();
    _videoController?.dispose();
    _videoController = null;
    setState(() {
      _hasVideo = false;
      _recordedVideo = null;
      _recordingDuration = 0;
    });
  }

  /// US13 & US16: Submit video
  Future<void> _submitVideo() async {
    if (_recordedVideo == null) return;
    
    // US13: Check file size (approx limit for 30s video)
    final int sizeInBytes = await _recordedVideo!.length();
    final double sizeInMb = sizeInBytes / (1024 * 1024);
    
    if (sizeInMb > 50) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Video is too large (>50MB). Please record a shorter video.'),
          backgroundColor: AppColors.red600,
        ),
      );
      return;
    }
    
    if (!mounted) return;

    // US16: Final confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: const [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 12),
            Text('Video ready for analysis!'),
          ],
        ),
        backgroundColor: AppColors.nature600,
      ),
    );

    widget.onVideoRecorded(_recordedVideo!.path);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: Text(
          context.t('videoView.title'),
          style: const TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black,
              AppColors.nature900.withOpacity(0.8),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Video Preview Area
              Expanded(
                child: _buildPreviewArea(),
              ),

              // Controls
              _buildControls(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPreviewArea() {
    return Center(
      child: Container(
        width: 320,
        height: 400,
        decoration: BoxDecoration(
          color: AppColors.gray900,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _isRecording ? AppColors.red500 : AppColors.nature500,
            width: 3,
          ),
        ),
        child: Stack(
          children: [
            // Center content
            Center(
              child: _hasVideo && _videoController != null && _videoController!.value.isInitialized
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: AspectRatio(
                        aspectRatio: _videoController!.value.aspectRatio,
                        child: VideoPlayer(_videoController!),
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _hasVideo ? Icons.check_circle : Icons.videocam,
                          size: 64,
                          color: _hasVideo ? AppColors.nature500 : AppColors.gray500,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _hasVideo
                              ? 'Loading Preview...'
                              : (kIsWeb ? 'Tap to select video' : 'Tap to record'),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
            ),
            
            // Recording indicator
            if (_isRecording)
              Positioned(
                top: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: AppColors.red600,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '${_formatDuration(_recordingDuration)} / ${_formatDuration(maxDurationSeconds)}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

            // Duration limit info
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: Text(
                  'Max: ${maxDurationSeconds}s',
                  style: TextStyle(
                    color: AppColors.gray400,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          if (!_hasVideo) ...[
            // Record button
            GestureDetector(
              onTap: _isRecording ? _stopRecording : _startRecording,
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _isRecording ? AppColors.red600 : AppColors.nature600,
                  boxShadow: [
                    BoxShadow(
                      color: (_isRecording ? AppColors.red600 : AppColors.nature600).withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Center(
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.videocam,
                    size: 36,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ] else ...[
            // Preview actions
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Retake button
                ElevatedButton.icon(
                  onPressed: _retakeVideo,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retake'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gray700,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
                const SizedBox(width: 20),
                // Submit button
                ElevatedButton.icon(
                  onPressed: _submitVideo,
                  icon: const Icon(Icons.check),
                  label: const Text('Use Video'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.nature600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 16),
          Text(
            _isRecording
                ? 'Recording...'
                : (_hasVideo ? 'Review your video' : 'Tap to ${kIsWeb ? "select" : "record"} video'),
            style: TextStyle(color: AppColors.gray400),
          ),
        ],
      ),
    );
  }
}

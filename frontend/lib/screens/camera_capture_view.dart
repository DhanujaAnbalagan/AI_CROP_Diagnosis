import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:camera/camera.dart';
import 'package:image_picker/image_picker.dart' show ImagePicker, ImageSource, XFile;
import '../core/theme/app_colors.dart';
import '../core/localization/translation_service.dart';
import '../core/utils/image_quality_util.dart';
import '../services/audio_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

/// Camera Capture View - Modern AI camera for plant diagnosis.
class CameraCaptureView extends StatefulWidget {
  final VoidCallback onBack;
  final Function(String imagePath, {String? base64Content}) onCapture;

  const CameraCaptureView({
    super.key,
    required this.onBack,
    required this.onCapture,
  });

  @override
  State<CameraCaptureView> createState() => _CameraCaptureViewState();
}

class _CameraCaptureViewState extends State<CameraCaptureView> {
  CameraController? _controller;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isCapturing = false;
  bool _showGuidance = true;
  String? _qualityWarning;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) {
      _initializeCamera();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      audioService.speak('Position your plant clearly in the frame for best results.');
    });
  }

  Future<void> _initializeCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras != null && _cameras!.isNotEmpty) {
        _controller = CameraController(
          _cameras![0],
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _controller!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      debugPrint('Camera initialization error: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    if (_isCapturing) return;

    setState(() {
      _isCapturing = true;
      _qualityWarning = null;
      _showGuidance = false;
    });

    try {
      XFile? image;
      if (_isCameraInitialized && _controller != null) {
        image = await _controller!.takePicture();
      } else {
        // Fallback to gallery
        image = await _picker.pickImage(source: ImageSource.gallery);
      }

      if (image == null) {
        setState(() => _isCapturing = false);
        return;
      }

      final bytes = await image.readAsBytes();
      final quality = await ImageQualityUtil.analyzeImageFromBytes(bytes);

      if (!mounted) return;

      if (!quality.isGood) {
        setState(() {
          _isCapturing = false;
          _qualityWarning = quality.isBlurry
              ? 'Image appears blurry. Please take another photo.'
              : 'Image is too dark. Try adding more light.';
        });
        audioService.confirmAction('error', message: _qualityWarning);
        return;
      }

      setState(() => _isCapturing = false);
      audioService.confirmAction('success', message: 'Photo captured successfully!');
      _showSuccessAndProceed(image.path, bytes: bytes);

    } catch (e) {
      debugPrint('Error capturing photo: $e');
      setState(() => _isCapturing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      final bytes = await image.readAsBytes();
      _showSuccessAndProceed(image.path, bytes: bytes);
    }
  }

  void _showSuccessAndProceed(String path, {Uint8List? bytes}) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Photo captured successfully!'),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 1),
      ),
    );

    Future.delayed(const Duration(milliseconds: 500), () async {
      widget.onCapture(path, base64Content: kIsWeb && bytes != null ? Uri.dataFromBytes(bytes, mimeType: 'image/jpeg').toString().split(',').last : null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Darker background for camera focus
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18, color: Colors.white),
          onPressed: widget.onBack,
        ),
        title: Text(
          context.t('cameraView.title'),
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.image, color: Colors.white),
            onPressed: _pickFromGallery,
            tooltip: 'Choose from gallery',
          ),
        ],
      ),
      extendBodyBehindAppBar: true,
      body: Stack(
        children: [
          // 1. Camera Preview or Fallback
          Positioned.fill(
            child: _isCameraInitialized && _controller != null
                ? CameraPreview(_controller!)
                : Container(
                    color: AppColors.gray900,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(LucideIcons.cameraOff, color: Colors.white54, size: 48),
                          const SizedBox(height: 16),
                          Text(
                            kIsWeb ? "Web mode: Use gallery upload" : "Initializing camera...",
                            style: const TextStyle(color: Colors.white70),
                          ),
                          if (kIsWeb) ...[
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _pickFromGallery,
                              icon: const Icon(LucideIcons.image),
                              label: const Text("Select from Gallery"),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                  ),
          ),

          // 2. Alignment Overlay
          if (_isCameraInitialized) _buildCameraOverlay(),

          // 3. Guidance Section
          if (_showGuidance) 
            Positioned(
              top: MediaQuery.of(context).padding.top + 60,
              left: 20,
              right: 20,
              child: _buildGuidanceSection(),
            ),

          // 4. Capture Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _buildBottomControls(),
          ),

          if (_isCapturing)
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildCameraOverlay() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.35),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 280,
              height: 380,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.transparent),
              ),
              child: Stack(
                children: [
                  _buildCorner(Alignment.topLeft),
                  _buildCorner(Alignment.topRight),
                  _buildCorner(Alignment.bottomLeft),
                  _buildCorner(Alignment.bottomRight),
                  const Center(
                    child: Icon(LucideIcons.scan, color: Colors.white38, size: 40),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                "Align leaf within frame",
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCorner(Alignment alignment) {
    return Align(
      alignment: alignment,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          border: Border(
            top: alignment == Alignment.topLeft || alignment == Alignment.topRight 
              ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            bottom: alignment == Alignment.bottomLeft || alignment == Alignment.bottomRight 
              ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            left: alignment == Alignment.topLeft || alignment == Alignment.bottomLeft 
              ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
            right: alignment == Alignment.topRight || alignment == Alignment.bottomRight 
              ? const BorderSide(color: Colors.white, width: 4) : BorderSide.none,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildGuidanceSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(LucideIcons.sparkles, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              const Text("Capture Tips", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black87)),
              const Spacer(),
              GestureDetector(
                onTap: () => setState(() => _showGuidance = false),
                child: const Icon(Icons.close, size: 16, color: Colors.black45),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildSimpleTip(LucideIcons.sun, "Bright Light"),
              _buildSimpleTip(LucideIcons.focus, "Clear Focus"),
              _buildSimpleTip(LucideIcons.maximize, "Fill Frame"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleTip(IconData icon, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(height: 4),
        Text(text, style: const TextStyle(fontSize: 10, color: Colors.black54, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildBottomControls() {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).padding.bottom + 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black87, Colors.transparent],
        ),
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: _isCapturing ? null : _capturePhoto,
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 4),
              ),
              child: Center(
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(LucideIcons.camera, color: Colors.black, size: 32),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            "TAP TO SCAN",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, letterSpacing: 1.5, fontSize: 12),
          ),
        ],
      ),
    );
  }
}


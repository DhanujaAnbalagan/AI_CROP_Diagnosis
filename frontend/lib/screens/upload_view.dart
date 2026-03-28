import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/theme/app_colors.dart';
import '../core/utils/responsive_layout.dart';
import '../core/localization/translation_service.dart';
import '../services/audio_service.dart';

/// Upload View — Modern AgriTech theme for image selection.
class UploadView extends StatefulWidget {
  final Function(List<String>) onImagesSelected;
  final VoidCallback onBack;

  const UploadView({
    super.key,
    required this.onImagesSelected,
    required this.onBack,
  });

  @override
  State<UploadView> createState() => _UploadViewState();
}

class _UploadViewState extends State<UploadView> {
  final List<XFile> _selectedImages = [];
  final List<Uint8List> _imageBytes = [];
  bool _isLoading = false;

  Future<void> _selectImages() async {
    try {
      final picker = ImagePicker();
      final images = await picker.pickMultiImage(imageQuality: 85);
      if (images.isNotEmpty) {
        final bytes = await Future.wait(images.map((f) => f.readAsBytes()));
        setState(() {
          _selectedImages.addAll(images);
          _imageBytes.addAll(bytes);
        });
        audioService.confirmAction('select');
      }
    } catch (e) {
      debugPrint('Image selection error: $e');
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
      _imageBytes.removeAt(index);
    });
    audioService.confirmAction('delete');
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;
    setState(() => _isLoading = true);
    audioService.confirmAction('success');

    final paths = _selectedImages.map((f) => f.path).toList();
    widget.onImagesSelected(paths);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_selectedImages.length} image(s) sent for analysis'),
          backgroundColor: AppColors.primary,
        ),
      );
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 18),
          onPressed: widget.onBack,
          color: AppColors.gray800,
        ),
        title: Text(
          context.t('uploadView.title'),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.gray800,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: responsiveMaxWidth(context)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Upload Crop Photos",
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.gray800,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Select clear photos of the affected leaves for more accurate AI diagnosis.",
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.gray500,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // Main Drop Zone / Selection Area
                    GestureDetector(
                      onTap: _selectImages,
                      child: _selectedImages.isEmpty
                          ? _buildEmptyState()
                          : _buildImageGrid(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // Bottom Action Bar
          _buildBottomBar(context),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      height: 320,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.leaf50,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.primary.withOpacity(0.2),
          width: 2,
          style: BorderStyle.solid,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: const Icon(
                LucideIcons.imagePlus,
                size: 32,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Select Images',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.gray800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Select one or more crop leaf images',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.gray500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImageGrid(BuildContext context) {
    final cols = responsiveColumns(context, mobile: 2, tablet: 3, desktop: 4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Selected Photos (${_selectedImages.length})',
              style: const TextStyle(
                color: AppColors.gray800,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: _selectImages,
              icon: const Icon(LucideIcons.plus, size: 16),
              label: const Text("Add More"),
              style: TextButton.styleFrom(foregroundColor: AppColors.primary),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: cols,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1,
          ),
          itemCount: _selectedImages.length,
          itemBuilder: (context, index) {
            return Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.smallShadow,
                    image: DecorationImage(
                      image: MemoryImage(_imageBytes[index]),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                // Remove button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _removeImage(index),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: AppColors.smallShadow,
                      ),
                      child: const Icon(Icons.close, size: 16, color: AppColors.error),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildBottomBar(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: responsiveMaxWidth(context)),
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => setState(() { _selectedImages.clear(); _imageBytes.clear(); }),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    side: const BorderSide(color: AppColors.gray200),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Clear All", style: TextStyle(color: AppColors.gray600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  onPressed: _selectedImages.isEmpty || _isLoading ? null : _uploadImages,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    disabledBackgroundColor: AppColors.gray200,
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(LucideIcons.sparkles, size: 18),
                            const SizedBox(width: 8),
                            Text(
                              _selectedImages.isEmpty
                                  ? "Select Images"
                                  : "Start AI Analysis (${_selectedImages.length})",
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


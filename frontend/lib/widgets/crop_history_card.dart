import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// A mini crop history card displayed in the horizontal history strip.
class CropHistoryCard extends StatelessWidget {
  final String cropName;
  final String status;
  final String confidence;
  final Color statusColor;
  final IconData cropIcon;
  final String? imageUrl;
  final VoidCallback? onTap;

  const CropHistoryCard({
    super.key,
    required this.cropName,
    required this.status,
    required this.confidence,
    required this.cropIcon,
    this.imageUrl,
    this.statusColor = const Color(0xFF2E7D32),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 110,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow,
          border: Border.all(color: AppColors.gray100),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                clipBehavior: Clip.antiAlias,
                child: _buildImagePreview(),
              ),
              const SizedBox(height: 8),
              Text(
                cropName,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  status,
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                    letterSpacing: 0.3,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                confidence,
                style: const TextStyle(
                  fontSize: 10,
                  color: AppColors.textHint,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (imageUrl == null || imageUrl!.isEmpty) {
      return Icon(cropIcon, color: statusColor, size: 22);
    }

    try {
      if (imageUrl!.startsWith('http')) {
        return Image.network(
          imageUrl!,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(cropIcon, color: statusColor, size: 22),
        );
      } else if (!kIsWeb) {
        return Image.file(
          File(imageUrl!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Icon(cropIcon, color: statusColor, size: 22),
        );
      }
    } catch (e) {
      // Fallback
    }
    return Icon(cropIcon, color: statusColor, size: 22);
  }
}

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/utils/responsive_layout.dart';
import '../services/preferences_service.dart';
import '../services/database_service.dart';
import '../models/analysis_result.dart';
import '../widgets/crop_advice_card.dart';
import '../widgets/media_gallery.dart';
import '../core/theme/app_colors.dart';

/// History View — Redesigned with AgriTech Light theme.
class HistoryView extends StatefulWidget {
  final VoidCallback onBack;

  const HistoryView({super.key, required this.onBack});

  @override
  State<HistoryView> createState() => _HistoryViewState();
}

class _HistoryViewState extends State<HistoryView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<AnalysisResult> _history = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadHistory();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadHistory() async {
    try {
      if (kIsWeb) {
        _history = [];
      } else {
        _history = await databaseService.getAllDiagnoses();
      }
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showAdvice(AnalysisResult result) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(30),
            topRight: Radius.circular(30),
          ),
          child: CropAdviceCard(
            result: result,
            onClose: () => Navigator.pop(context),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.chevronLeft, size: 24),
          onPressed: widget.onBack,
          color: AppColors.textPrimary,
        ),
        title: const Text(
          'History & Uploads',
          style: TextStyle(
            color: AppColors.textPrimary, 
            fontWeight: FontWeight.w800,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw, size: 20),
            onPressed: () {
              setState(() => _isLoading = true);
              _loadHistory();
            },
            color: AppColors.textSecondary,
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textHint,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          indicatorSize: TabBarIndicatorSize.label,
          labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, letterSpacing: 0.5),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          tabs: const [
            Tab(text: 'Analysis History'),
            Tab(text: 'Pending Media'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _isLoading
              ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
              : _history.isEmpty
                  ? _buildEmptyState()
                  : _buildHistoryList(context),
          const MediaGallery(),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= Breakpoints.mobile;

    if (isWide) {
      return GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: width >= Breakpoints.tablet ? 3 : 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.4,
        ),
        itemCount: _history.length,
        itemBuilder: (context, index) => _buildHistoryCard(context, _history[index]),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      itemCount: _history.length,
      itemBuilder: (context, index) => _buildHistoryCard(context, _history[index]),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.05),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.history, size: 64, color: AppColors.primary),
          ),
          const SizedBox(height: 24),
          const Text(
            'No History Yet',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Your previous plant diagnosis reports will be automatically saved here for quick reference.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 15, color: AppColors.textSecondary, height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryCard(BuildContext context, AnalysisResult item) {
    final isHealthy = item.disease.toLowerCase() == 'healthy';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.softShadow,
        border: Border.all(color: AppColors.gray100, width: 1),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => _showAdvice(item),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: (isHealthy ? AppColors.success : AppColors.warning).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isHealthy ? LucideIcons.shieldCheck : LucideIcons.leaf,
                    size: 30,
                    color: isHealthy ? AppColors.success : AppColors.warning,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              item.crop.toUpperCase(),
                              style: const TextStyle(
                                fontSize: 13, 
                                fontWeight: FontWeight.w900, 
                                color: AppColors.textSecondary,
                                letterSpacing: 1.1,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _buildSeverityBadge(item.severity),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.disease,
                        style: TextStyle(
                          fontSize: 17,
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(LucideIcons.calendar, size: 12, color: AppColors.textHint),
                              const SizedBox(width: 4),
                              Text(
                                _formatDate(item.date),
                                style: const TextStyle(fontSize: 12, color: AppColors.textHint, fontWeight: FontWeight.w500),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.info.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(LucideIcons.barChart3, size: 12, color: AppColors.info),
                                const SizedBox(width: 4),
                                Text(
                                  '${(item.confidence * 100).toInt()}%',
                                  style: const TextStyle(fontSize: 11, color: AppColors.info, fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeverityBadge(String severity) {
    Color color;
    switch (severity.toLowerCase()) {
      case 'high':
      case 'severe':
        color = AppColors.error;
        break;
      case 'moderate':
      case 'medium':
        color = AppColors.warning;
        break;
      case 'low':
        color = AppColors.info;
        break;
      case 'healthy':
      case 'none':
        color = AppColors.success;
        break;
      default:
        color = AppColors.textHint;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Text(
        severity.isEmpty ? 'N/A' : severity.toUpperCase(),
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w900, color: color, letterSpacing: 0.5),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}


import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../core/theme/app_colors.dart';
import '../core/localization/translation_service.dart';
import '../services/consent_service.dart';
import '../services/offline_storage_service.dart';
import '../services/preferences_service.dart';
import '../services/location_service.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:async';
import '../services/region_service.dart';
import '../services/weather_service.dart';
import '../services/database_service.dart';
import '../widgets/scan_hero_card.dart';
import '../widgets/crop_history_card.dart';
import '../widgets/quick_tip_card.dart';
import '../models/analysis_result.dart';
import '../services/reminder_service.dart';
import '../models/reminder_model.dart';
import 'package:intl/intl.dart';

class HomeView extends StatefulWidget {
  final Function(String) onNavigate;
  final bool isOnline;

  const HomeView({
    super.key,
    required this.onNavigate,
    this.isOnline = true,
  });

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> with TickerProviderStateMixin {
  bool _isGuest = false;
  int _pendingSyncCount = 0;
  String _displayName = 'Farmer';
  String _avatarInitials = 'F';
  WeatherData? _weatherData;
  List<Map<String, dynamic>> _scanHistory = [];
  List<ReminderModel> _activeReminders = [];
  late Timer _timer;
  String _currentTime = '';

  // AI Bubble animation
  bool _aiBubbleExpanded = false;
  late AnimationController _bubbleCtrl;
  late Animation<double> _bubbleScale;

  @override
  void initState() {
    super.initState();
    _checkGuestMode();
    _loadPendingSyncCount();
    _checkRegionSetup();
    _loadUserName();
    _loadWeather();
    _loadScanHistory();
    _loadActiveReminders();
    _updateTime();

    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateTime();
      _loadActiveReminders();
    });

    // AI bubble animation
    _bubbleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _bubbleScale = CurvedAnimation(parent: _bubbleCtrl, curve: Curves.easeOutBack);
  }

  Future<void> _loadActiveReminders() async {
    try {
      final now = DateTime.now();
      final all = await reminderService.getAll();
      final active = all.where((r) {
        if (r.isCompleted) return false;
        final refDate = DateTime(now.year, now.month, now.day);
        final rmDate = DateTime(r.scheduledDate.year, r.scheduledDate.month, r.scheduledDate.day);
        return rmDate.isAfter(refDate) || rmDate.isAtSameMomentAs(refDate);
      }).toList();
      
      // Sort by soonest first
      active.sort((a, b) {
        final aTime = DateTime(a.scheduledDate.year, a.scheduledDate.month, a.scheduledDate.day, int.parse(a.scheduledTime.split(':')[0]), int.parse(a.scheduledTime.split(':')[1]));
        final bTime = DateTime(b.scheduledDate.year, b.scheduledDate.month, b.scheduledDate.day, int.parse(b.scheduledTime.split(':')[0]), int.parse(b.scheduledTime.split(':')[1]));
        return aTime.compareTo(bTime);
      });

      if (mounted) {
        setState(() => _activeReminders = active);
      }
    } catch (e) {
      debugPrint('Error loading reminders: $e');
    }
  }

  @override
  void dispose() {
    _bubbleCtrl.dispose();
    _timer.cancel();
    super.dispose();
  }

  void _updateTime() {
    final now = DateTime.now();
    final hour = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final minute = now.minute.toString().padLeft(2, '0');
    final period = now.hour >= 12 ? 'PM' : 'AM';
    if (mounted) {
      setState(() {
        _currentTime = '$hour:$minute $period';
      });
    }
  }

  Future<void> _loadWeather() async {
    try {
      final position = await LocationService.getCurrentPosition();
      final weather = await WeatherService.fetchWeather(position);
      if (mounted) {
        setState(() => _weatherData = weather);
      }
    } catch (e) {
      debugPrint('Error loading weather: $e');
    }
  }

  Future<void> _loadScanHistory() async {
    try {
      List<AnalysisResult> diagnoses = [];
      
      // 1. Try SQLite (Mobile only)
      if (!kIsWeb) {
        diagnoses = await databaseService.getAllDiagnoses();
      }
      
      // 2. Fallback to SharedPreferences (Web or if SQLite is empty)
      if (diagnoses.isEmpty) {
        final history = await preferencesService.getAnalysisHistory();
        diagnoses = history.map((h) => AnalysisResult.fromJson(h)).toList();
      }

      if (mounted) {
        setState(() {
          _scanHistory = diagnoses.map((d) => {
            'id': d.id,
            'name': d.crop,
            'status': d.disease,
            'confidence': '${(d.confidence * 100).toStringAsFixed(0)}%',
            'color': _getStatusColor(d.disease),
            'icon': _getCropIcon(d.crop),
            'imageUrl': d.imageUrl,
          }).toList();
        });
      }
    } catch (e) {
      debugPrint('Error loading history: $e');
    }
  }

  Future<void> _loadUserName() async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    final isGuest = await consentService.isGuestMode();
    if (!mounted) return;
    if (isGuest || firebaseUser == null) {
      setState(() {
        _displayName = 'Guest User';
        _avatarInitials = 'G';
      });
    } else {
      final name = firebaseUser.displayName ?? firebaseUser.email ?? 'Farmer';
      final parts = name.split(' ');
      final initials = parts.length >= 2
          ? '${parts[0][0]}${parts[1][0]}'.toUpperCase()
          : name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
      setState(() {
        _displayName = parts[0]; // first name
        _avatarInitials = initials;
      });
    }
  }

  void _toggleAiBubble() {
    setState(() => _aiBubbleExpanded = !_aiBubbleExpanded);
    if (_aiBubbleExpanded) {
      _bubbleCtrl.forward();
    } else {
      _bubbleCtrl.reverse();
    }
  }

  Future<void> _checkGuestMode() async {
    final isGuest = await consentService.isGuestMode();
    if (mounted) {
      setState(() {
        _isGuest = isGuest;
      });
    }
  }

  Future<void> _loadPendingSyncCount() async {
    final count = await offlineStorageService.getPendingCount();
    if (mounted) {
      setState(() => _pendingSyncCount = count);
    }
  }

  Future<void> _checkRegionSetup() async {
    final region = await preferencesService.getRegion();
    if (region == null) {
      Future.delayed(const Duration(seconds: 1), () {
        if (mounted) {
          _showRegionSetupDialog();
        }
      });
    }
  }

  Future<void> _showRegionSetupDialog() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Localize Your Advice'),
        content: const Text(
          'To provide treatment advice specific to your regional climate, we need to know your state. Would you like to auto-detect your location or select manually?'
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showManualRegionSelection();
            },
            child: const Text('Select Manually'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _autoDetectRegion();
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Auto-detect', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Future<void> _showManualRegionSelection() async {
    final List<String> regions = ['Tamil Nadu', 'Punjab', 'Maharashtra'];
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select State'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: regions.map((r) => ListTile(
            title: Text(r),
            onTap: () => Navigator.pop(context, r),
          )).toList(),
        ),
      ),
    );

    if (result != null && mounted) {
      await preferencesService.setRegion(result);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Region set to $result')),
      );
    }
  }

  Future<void> _autoDetectRegion() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detecting your location...'), duration: Duration(seconds: 2)),
      );

      final position = await LocationService.getCurrentPosition();
      final region = RegionService.getRegionFromCoordinates(position.latitude, position.longitude);

      if (region != null && mounted) {
        await preferencesService.setRegion(region);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Detected Region: $region')),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not determine region. Please select manually.')),
        );
        _showManualRegionSelection();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Location error: $e')),
        );
        _showManualRegionSelection();
      }
    }
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7F6),
      body: Stack(
        children: [
          Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // Guest Banner
                      if (_isGuest) ...[
                        _buildGuestBanner(context),
                        const SizedBox(height: 16),
                      ],

                      // Offline / Sync Status
                      if (!widget.isOnline || _pendingSyncCount > 0) ...[
                        _buildStatusBar(context),
                        const SizedBox(height: 16),
                      ],

                      // 1. Weather Strip (Horizontal)
                      _buildWeatherStrip(),
                      const SizedBox(height: 24),

                      // 5. Hero Scan Card
                      ScanHeroCard(onTap: () => widget.onNavigate('camera')),
                      const SizedBox(height: 16),

                      // Upload Card (Redesigned)
                      _buildUploadCard(),
                      const SizedBox(height: 24),

                      // 6. My Crop History
                      _buildSectionTitle('My Crop History', onViewAll: () => widget.onNavigate('history')),
                      const SizedBox(height: 12),
                      _buildCropHistoryStrip(),
                      const SizedBox(height: 24),

                      // 7. Farmer Calendar banner
                      _buildSectionTitle('Smart Tools', onViewAll: null),
                      const SizedBox(height: 12),
                      _buildSmartToolsGrid(context),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          ),

          // ── Expandable AI Floating Bubble ────────────────────────────────
          _buildAiFab(),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------------

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 16,
        right: 12,
        bottom: 16,
      ),
      decoration: const BoxDecoration(
        gradient: AppColors.heroGradient,
      ),
      child: Row(
        children: [
          // Profile Avatar with dynamic initials
          GestureDetector(
            onTap: () => widget.onNavigate('profile'),
            child: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white.withOpacity(0.5), width: 1.5),
              ),
              child: Center(
                child: Text(
                  _avatarInitials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Dynamic user name + greeting
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              'Good ${_getGreeting()}, $_displayName',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Text('🌱', style: TextStyle(fontSize: 14)),
                        ],
                      ),
                    ),
                    Text(
                      _currentTime,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                Text(
                  _isGuest ? 'Guest Mode' : 'Farmer Dashboard',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Search
          _buildHeaderIcon(Icons.search_rounded, onTap: () => _showSearchSheet(context)),
          const SizedBox(width: 6),
          // Notifications
          _buildHeaderIcon(
            Icons.notifications_rounded, 
            badgeCount: _activeReminders.length,
            onTap: () => _showNotificationsSheet(context),
          ),
          const SizedBox(width: 6),
          // Settings
          _buildHeaderIcon(Icons.settings_rounded, onTap: () => widget.onNavigate('settings')),
        ],
      ),
    );
  }

  /// Simple in-app search sheet (routes to existing screens based on query)
  void _showSearchSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _SearchSheet(onNavigate: widget.onNavigate),
    );
  }

  /// Notifications sheet
  void _showNotificationsSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.gray300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              '🔔 Notifications',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 16),
            if (_activeReminders.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: Text(
                    'No pending reminders.',
                    style: TextStyle(color: AppColors.textHint, fontSize: 14),
                  ),
                ),
              )
            else
              ..._activeReminders.map((r) {
                final color = Color(r.reminderType.colorValue);
                IconData iconData = Icons.notifications;
                if (r.reminderType == ReminderType.pesticide) iconData = Icons.science_rounded;
                else if (r.reminderType == ReminderType.fertilizer) iconData = Icons.grass_rounded;
                else if (r.reminderType == ReminderType.irrigation) iconData = Icons.water_drop_rounded;
                else if (r.reminderType == ReminderType.harvest) iconData = Icons.agriculture_rounded;
                else if (r.reminderType == ReminderType.inspection) iconData = Icons.search_rounded;

                final timeFormat = DateFormat('h:mm a').format(
                  DateTime(2024, 1, 1, int.parse(r.scheduledTime.split(':')[0]), int.parse(r.scheduledTime.split(':')[1]))
                );

                String datePrefix = '';
                final now = DateTime.now();
                if (r.scheduledDate.year == now.year && r.scheduledDate.month == now.month && r.scheduledDate.day == now.day) {
                  datePrefix = 'Today';
                } else if (r.scheduledDate.year == now.year && r.scheduledDate.month == now.month && r.scheduledDate.day == now.day + 1) {
                  datePrefix = 'Tomorrow';
                } else {
                  datePrefix = DateFormat('MMM d').format(r.scheduledDate);
                }

                return _buildNotifItem(
                  iconData,
                  r.title,
                  '${r.cropName} — $datePrefix at $timeFormat',
                  color,
                );
              }),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildNotifItem(IconData icon, String title, String sub, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.textPrimary)),
                Text(sub, style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIcon(IconData icon, {VoidCallback? onTap, int badgeCount = 0}) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          if (badgeCount > 0)
            Positioned(
              top: -2,
              right: -2,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: AppColors.error,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeCount > 9 ? '9+' : badgeCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── Expandable AI Floating Bubble ────────────────────────────────────────

  Widget _buildAiFab() {
    return Positioned(
      right: 16,
      bottom: 90, // above bottom nav bar
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Expanded options (Voice + LLM)
          if (_aiBubbleExpanded) ...[
            ScaleTransition(
              scale: _bubbleScale,
              child: _buildAiOption(
                icon: Icons.mic_rounded,
                label: 'Voice Doctor',
                color: const Color(0xFFEF5350),
                onTap: () {
                  _toggleAiBubble();
                  widget.onNavigate('voice');
                },
              ),
            ),
            const SizedBox(height: 10),
            ScaleTransition(
              scale: _bubbleScale,
              child: _buildAiOption(
                icon: Icons.auto_awesome_rounded,
                label: 'LLM Advice',
                color: const Color(0xFF2E7D32),
                onTap: () {
                  _toggleAiBubble();
                  widget.onNavigate('llm-advice');
                },
              ),
            ),
            const SizedBox(height: 10),
          ],

          // Main AI bubble button
          GestureDetector(
            onTap: _toggleAiBubble,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: _aiBubbleExpanded
                      ? [const Color(0xFF1B5E20), const Color(0xFF2E7D32)]
                      : [const Color(0xFF43A047), const Color(0xFF2E7D32)],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2E7D32).withOpacity(0.45),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: AnimatedRotation(
                turns: _aiBubbleExpanded ? 0.125 : 0,
                duration: const Duration(milliseconds: 250),
                child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 26),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 22),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // STATUS BAR
  // ------------------------------------------------------------------

  Widget _buildStatusBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: widget.isOnline ? AppColors.amber100 : AppColors.red400.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isOnline ? AppColors.amber500 : AppColors.error,
          width: 0.5,
        ),
      ),
      child: Row(
        children: [
          Icon(
            widget.isOnline ? LucideIcons.cloudOff : LucideIcons.wifi,
            size: 16,
            color: widget.isOnline ? AppColors.amber600 : AppColors.error,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              widget.isOnline
                  ? '$_pendingSyncCount item(s) pending sync'
                  : 'You are offline – results will be saved locally',
              style: TextStyle(
                color: widget.isOnline ? AppColors.amber700 : AppColors.error,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // SECTION TITLE
  // ------------------------------------------------------------------
  Widget _buildSectionTitle(String title, {VoidCallback? onViewAll, bool showViewAll = true}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary,
          ),
        ),
        if (showViewAll && onViewAll != null)
          GestureDetector(
            onTap: onViewAll,
            child: const Text(
              'View All',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // WEATHER STRIP
  // ------------------------------------------------------------------

  Widget _buildWeatherStrip() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            const Color(0xFFE8F5E9),
            const Color(0xFFC8E6C9).withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildWeatherItem(
            '🌡️',
            '${_weatherData?.temperature.toStringAsFixed(1) ?? "--"}°C',
            'Temp',
          ),
          _buildVerticalDivider(),
          _buildWeatherItem(
            _weatherData?.icon ?? '🌤️',
            _weatherData?.condition ?? 'Loading...',
            'Status',
          ),
          _buildVerticalDivider(),
          _buildWeatherItem(
            '💧',
            '${_weatherData?.humidity ?? "--"}%',
            'Humidity',
          ),
        ],
      ),
    );
  }

  Widget _buildWeatherItem(String icon, String value, String label) {
    return Column(
      children: [
        Text(icon, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1B5E20),
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF43A047),
          ),
        ),
      ],
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 30,
      width: 1,
      color: const Color(0xFF2E7D32).withOpacity(0.15),
    );
  }

  // ------------------------------------------------------------------
  // SECTION TITLE
  // ------------------------------------------------------------------

  // ------------------------------------------------------------------
  // CROP HISTORY STRIP
  // ------------------------------------------------------------------

  Widget _buildCropHistoryStrip() {
    if (_scanHistory.isEmpty) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.gray200),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(LucideIcons.camera, color: AppColors.gray300, size: 32),
            SizedBox(height: 8),
            Text(
              'No scan history yet',
              style: TextStyle(color: AppColors.textHint, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      );
    }

    return SizedBox(
      height: 175,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _scanHistory.length,
        itemBuilder: (context, i) {
          final crop = _scanHistory[i];
          return CropHistoryCard(
            cropName: crop['name'] as String,
            status: crop['status'] as String,
            confidence: crop['confidence'] as String,
            cropIcon: crop['icon'] as IconData,
            imageUrl: crop['imageUrl'] as String?,
            statusColor: crop['color'] as Color,
            onTap: () => widget.onNavigate('history'),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------
  // QUICK TIPS STRIP
  // ------------------------------------------------------------------

  Widget _buildQuickTipsStrip() {
    final tips = [
      {
        'tip': 'Water your crops early morning to reduce evaporation and fungal risk.',
        'category': 'Irrigation',
        'color': const Color(0xFF1976D2),
        'icon': LucideIcons.droplets,
      },
      {
        'tip': 'Rotate crops every season to maintain soil nutrients and reduce disease.',
        'category': 'Crop Care',
        'color': const Color(0xFF2E7D32),
        'icon': LucideIcons.refreshCw,
      },
      {
        'tip': 'Apply organic compost before planting for healthier root development.',
        'category': 'Fertilizer',
        'color': const Color(0xFF795548),
        'icon': LucideIcons.sprout,
      },
      {
        'tip': 'Monitor leaf color weekly – yellowing often signals nutrient deficiency.',
        'category': 'Disease Watch',
        'color': const Color(0xFFF57C00),
        'icon': LucideIcons.eye,
      },
    ];

    return SizedBox(
      height: 135,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: tips.length,
        itemBuilder: (context, i) {
          final tip = tips[i];
          return QuickTipCard(
            tip: tip['tip'] as String,
            category: tip['category'] as String,
            color: tip['color'] as Color,
            icon: tip['icon'] as IconData,
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------------
  // UPLOAD CROP IMAGE CARD
  // ------------------------------------------------------------------

  Widget _buildUploadCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [Color(0xFF2E7D32), Color(0xFF66BB6A)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E7D32).withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () => widget.onNavigate('upload'),
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    LucideIcons.leaf,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'Upload Crop Image',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Choose leaf image from gallery',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // WEATHER INSIGHT CARD
  // ------------------------------------------------------------------

  Widget _buildWeatherInsightCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1565C0).withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_cloudy_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                const Text(
                  'Weather Conditions',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Text(
                  'Today',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildWeatherStat('🌡️', '24°C', 'Temperature'),
                _buildWeatherDivider(),
                _buildWeatherStat('💧', '62%', 'Humidity'),
                _buildWeatherDivider(),
                _buildWeatherStat('💨', '8 km/h', 'Wind'),
                _buildWeatherDivider(),
                _buildWeatherStat('⛅', 'Partly\nCloudy', 'Status'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeatherStat(String emoji, String value, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        const SizedBox(height: 4),
        Text(
          value,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 14,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.75),
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildWeatherDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.3),
    );
  }

  // ------------------------------------------------------------------
  // SOIL & CLIMATE MONITOR CARD
  // ------------------------------------------------------------------

  Widget _buildSoilClimateCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF4CAF50).withOpacity(0.25), width: 1.5),
        boxShadow: AppColors.softShadow,
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.eco_rounded, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Soil & Climate Monitor',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'LIVE',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _buildClimateIndicator('Soil Moisture', 0.55, 'Moderate', const Color(0xFF795548)),
            const SizedBox(height: 12),
            _buildClimateIndicator('Humidity', 0.78, 'High', const Color(0xFF1976D2)),
            const SizedBox(height: 12),
            _buildClimateIndicator('Disease Risk', 0.45, 'Medium', const Color(0xFFF57C00)),
          ],
        ),
      ),
    );
  }

  Widget _buildClimateIndicator(String label, double value, String level, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                level,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value,
            backgroundColor: color.withOpacity(0.12),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // ------------------------------------------------------------------
  // DISEASE RISK ALERT CARD
  // ------------------------------------------------------------------

  Widget _buildDiseaseRiskCard() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: const Color(0xFFF57C00).withOpacity(0.35),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF57C00).withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning_amber_rounded,
                    color: Color(0xFFF57C00), size: 22),
                const SizedBox(width: 8),
                const Text(
                  'AI Disease Risk Prediction',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF4E3A00),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Based on current weather & humidity conditions',
              style: TextStyle(
                fontSize: 11,
                color: Color(0xFF7B6200),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildRiskBadge(
                    '🍂 Rust Risk',
                    'Medium',
                    const Color(0xFFF57C00),
                    0.50,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildRiskBadge(
                    '🌿 Blight Risk',
                    'High',
                    const Color(0xFFD32F2F),
                    0.75,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () => widget.onNavigate('camera'),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF57C00),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                    SizedBox(width: 6),
                    Text(
                      'Scan My Crop Now',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiskBadge(String label, String level, Color color, double value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: value,
              backgroundColor: color.withOpacity(0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            level,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------
  // SMART TOOLS GRID
  // ------------------------------------------------------------------

  Widget _buildSmartToolsGrid(BuildContext context) {
    final tools = <Map<String, dynamic>>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Farmer Calendar banner card ──────────────────────────────────
        GestureDetector(
          onTap: () => widget.onNavigate('farmer-calendar'),
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2E7D32), Color(0xFF43A047)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E7D32).withOpacity(0.3),
                  blurRadius: 14,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Farmer Calendar',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        'Schedule pesticide, irrigation & harvest reminders',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios_rounded,
                    color: Colors.white, size: 16),
              ],
            ),
          ),
        ),

        // ── Tool cards grid ──────────────────────────────────────────────
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.5,
          children: tools.map((tool) => _buildToolCard(tool)).toList(),
        ),
      ],
    );
  }

  Widget _buildToolCard(Map<String, dynamic> tool) {
    final color = tool['color'] as Color;
    return GestureDetector(
      onTap: () => widget.onNavigate(tool['nav'] as String),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppColors.softShadow,
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(tool['icon'] as IconData, color: color, size: 20),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tool['label'] as String,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    tool['sub'] as String,
                    style: const TextStyle(
                      fontSize: 10,
                      color: AppColors.textHint,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------
  // GUEST BANNER
  // ------------------------------------------------------------------

  Widget _buildGuestBanner(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.userPlus, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Guest Mode Active',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const Text(
                  'Sign in to sync your scan history across devices.',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => widget.onNavigate('auth'),
            child: const Text('SIGN IN', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    status = status.toLowerCase();
    if (status.contains('healthy')) return AppColors.primary;
    if (status.contains('blight') || status.contains('rust') || status.contains('rot')) return AppColors.error;
    if (status.contains('spot') || status.contains('mildew') || status.contains('mold')) return AppColors.warning;
    return AppColors.nature600;
  }

  IconData _getCropIcon(String crop) {
    crop = crop.toLowerCase();
    if (crop.contains('tomato')) return Icons.circle;
    if (crop.contains('potato')) return Icons.lens_blur;
    if (crop.contains('corn') || crop.contains('maize')) return Icons.grain;
    if (crop.contains('rice') || crop.contains('wheat')) return Icons.eco_rounded;
    if (crop.contains('apple') || crop.contains('grape')) return Icons.apple;
    return Icons.eco;
  }
}

// =========================================================================
// SEARCH SHEET
// =========================================================================

class _SearchSheet extends StatefulWidget {
  final Function(String) onNavigate;
  const _SearchSheet({required this.onNavigate});

  @override
  State<_SearchSheet> createState() => _SearchSheetState();
}

class _SearchSheetState extends State<_SearchSheet> {
  final _ctrl = TextEditingController();
  String _query = '';

  final _shortcuts = [
    {'label': '📷 Scan a Crop',      'route': 'camera',       'desc': 'Take a photo for disease detection'},
    {'label': '📜 Scan History',      'route': 'history',      'desc': 'View past diagnoses'},
    {'label': '💬 AI Chatbot',        'route': 'chatbot',      'desc': 'Chat with the farming AI'},
    {'label': '✨ LLM Advice',        'route': 'llm-advice',   'desc': 'Get expert crop care advice'},
    {'label': '🗓 Farmer Calendar',   'route': 'farmer-calendar', 'desc': 'View and manage reminders'},
    {'label': '👤 Profile',           'route': 'profile',      'desc': 'View my profile'},
    {'label': '⚙️ Settings',          'route': 'settings',     'desc': 'App settings'},
  ];

  List<Map<String, String>> get _filtered {
    if (_query.isEmpty) return List<Map<String, String>>.from(_shortcuts);
    return _shortcuts
        .where((s) =>
            s['label']!.toLowerCase().contains(_query.toLowerCase()) ||
            s['desc']!.toLowerCase().contains(_query.toLowerCase()))
        .toList()
        .cast<Map<String, String>>();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        left: 20, right: 20, top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: AppColors.gray300, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _ctrl,
            autofocus: true,
            onChanged: (v) => setState(() => _query = v),
            decoration: InputDecoration(
              hintText: 'Search features...',
              prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
              filled: true,
              fillColor: AppColors.gray50,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ..._filtered.map((s) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
            title: Text(s['label']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            subtitle: Text(s['desc']!, style: const TextStyle(fontSize: 12, color: AppColors.textHint)),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.textHint),
            onTap: () {
              Navigator.pop(context);
              widget.onNavigate(s['route']!);
            },
          )),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

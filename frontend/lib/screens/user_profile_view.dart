import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/utils/responsive_layout.dart';
import '../core/localization/translation_service.dart';
import '../core/providers/language_provider.dart';
import '../services/preferences_service.dart';

/// User Profile View — Premium dark theme with responsive layout.
class UserProfileView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onLogout;
  final VoidCallback? onLanguageChange;

  const UserProfileView({
    super.key,
    required this.onBack,
    this.onLogout,
    this.onLanguageChange,
  });

  @override
  State<UserProfileView> createState() => _UserProfileViewState();
}

class _UserProfileViewState extends State<UserProfileView> {
  List<String> _selectedCrops = [];
  bool _isLoading = true;

  final List<String> _availableCrops = [
    'Tomato', 'Potato', 'Rice', 'Wheat', 'Maize', 'Cotton', 'Sugarcane', 'Soybean', 'Chilli', 'Onion'
  ];

  @override
  void initState() {
    super.initState();
    _loadCrops();
  }

  Future<void> _loadCrops() async {
    final crops = await preferencesService.getSelectedCrops();
    if (mounted) setState(() { _selectedCrops = crops; _isLoading = false; });
  }

  Future<void> _toggleCrop(String crop) async {
    setState(() {
      if (_selectedCrops.contains(crop)) {
        _selectedCrops.remove(crop);
      } else {
        _selectedCrops.add(crop);
      }
    });
    await preferencesService.setSelectedCrops(_selectedCrops);
  }

  void _showCropSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: const Color(0xFF1E2D45),
              title: Text(context.t('userProfile.myCrops'), style: const TextStyle(color: Colors.white)),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _availableCrops.length,
                  itemBuilder: (context, index) {
                    final crop = _availableCrops[index];
                    final isSelected = _selectedCrops.contains(crop);
                    return CheckboxListTile(
                      title: Text(crop, style: const TextStyle(color: Colors.white70)),
                      value: isSelected,
                      activeColor: const Color(0xFF10B981),
                      checkColor: Colors.white,
                      onChanged: (val) async {
                        await _toggleCrop(crop);
                        setDialogState(() {});
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close', style: TextStyle(color: Color(0xFF10B981))),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFF0F1A2E),
        body: Center(child: CircularProgressIndicator(color: Color(0xFF10B981))),
      );
    }

    final languageProvider = Provider.of<LanguageProvider>(context);
    final currentLang = languageProvider.currentLanguageInfo;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1A2E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: widget.onBack,
          color: Colors.white70,
        ),
        title: Text(
          context.t('userProfile.title'),
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0F1A2E), Color(0xFF1A2940)],
          ),
        ),
        child: SingleChildScrollView(
          child: ResponsiveBody(
            child: Column(
              children: [
                // Avatar section
                _buildAvatarSection(),
                const SizedBox(height: 28),

                // Stats Cards
                _buildStatsRow(context),
                const SizedBox(height: 28),

                // Settings Section
                _buildSettingsSection(context, currentLang),
                const SizedBox(height: 28),

                // Logout Button
                if (widget.onLogout != null)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: widget.onLogout,
                      icon: const Icon(LucideIcons.logOut, size: 18),
                      label: Text(context.t('userProfile.logout')),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: BorderSide(color: const Color(0xFFEF4444).withOpacity(0.3)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarSection() {
    return Column(
      children: [
        Container(
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
                blurRadius: 20,
              ),
            ],
          ),
          child: const Icon(LucideIcons.user, size: 36, color: Colors.white),
        ),
        const SizedBox(height: 12),
        const Text(
          'Farmer',
          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
        ),
        Text(
          'CropAID User',
          style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14),
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _buildStatCard('12', context.t('userProfile.scans'), LucideIcons.camera, const Color(0xFF38BDF8)),
        _buildStatCard('8', context.t('userProfile.diseases'), LucideIcons.bug, const Color(0xFFFBBF24)),
        _buildStatCard(_selectedCrops.length.toString(), context.t('userProfile.crops'), LucideIcons.leaf, const Color(0xFF10B981)),
      ],
    );
  }

  Widget _buildStatCard(String value, String label, IconData icon, Color color) {
    final width = MediaQuery.of(context).size.width;
    final cardWidth = width >= Breakpoints.mobile ? 140.0 : (width - 56) / 3;

    return SizedBox(
      width: cardWidth,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withOpacity(0.06)),
        ),
        child: Column(
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.5))),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsSection(BuildContext context, LanguageInfo currentLang) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(
        children: [
          _buildSettingsItem(
            icon: LucideIcons.leaf,
            title: context.t('userProfile.myCrops'),
            subtitle: '${_selectedCrops.length} ${context.t('userProfile.cropsRegistered')}',
            onTap: _showCropSelectionDialog,
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: LucideIcons.globe,
            title: context.t('userProfile.language'),
            subtitle: currentLang.nativeName,
            onTap: widget.onLanguageChange,
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: LucideIcons.bell,
            title: context.t('userProfile.notifications'),
            subtitle: context.t('userProfile.notificationsDesc'),
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: LucideIcons.helpCircle,
            title: context.t('userProfile.helpSupport'),
            subtitle: context.t('userProfile.helpSupportDesc'),
            onTap: () {},
          ),
          _buildDivider(),
          _buildSettingsItem(
            icon: LucideIcons.info,
            title: context.t('userProfile.about'),
            subtitle: 'v1.0.0',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 20, color: const Color(0xFF10B981)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white.withOpacity(0.85))),
                    Text(subtitle, style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.4))),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 60, color: Colors.white.withOpacity(0.05));
  }
}

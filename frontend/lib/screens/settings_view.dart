import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../core/utils/responsive_layout.dart';
import '../core/localization/translation_service.dart';
import '../core/providers/language_provider.dart';
import '../services/preferences_service.dart';
import '../services/location_service.dart';
import '../services/region_service.dart';

/// Settings View — Premium dark theme with responsive layout.
class SettingsView extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback? onLanguageChange;

  const SettingsView({super.key, required this.onBack, this.onLanguageChange});

  @override
  State<SettingsView> createState() => _SettingsViewState();
}

class _SettingsViewState extends State<SettingsView> {
  bool _pushNotifications = true;
  bool _pestAlerts = true;
  bool _soundEnabled = true;
  bool _darkMode = true;
  String _selectedRegion = 'Tamil Nadu';
  final List<String> _regions = ['Tamil Nadu', 'Punjab', 'Maharashtra'];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final region = await preferencesService.getRegion() ?? 'Tamil Nadu';
    if (mounted) setState(() => _selectedRegion = region);
  }

  Future<void> _onRegionTap() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1E2D45),
        title: const Text('Select Region', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ..._regions.map((r) => ListTile(
              title: Text(r, style: const TextStyle(color: Colors.white70)),
              onTap: () => Navigator.pop(context, r),
            )),
            const Divider(color: Colors.white12),
            ListTile(
              leading: const Icon(Icons.my_location, color: Color(0xFF10B981)),
              title: const Text('Auto-detect', style: TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.bold)),
              onTap: () => Navigator.pop(context, 'auto'),
            ),
          ],
        ),
      ),
    );

    if (result == 'auto') {
      _autoDetectRegion();
    } else if (result != null && mounted) {
      setState(() => _selectedRegion = result);
      await preferencesService.setRegion(result);
    }
  }

  Future<void> _autoDetectRegion() async {
    try {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Detecting your location...'), duration: Duration(seconds: 2)),
      );
      final position = await LocationService.getCurrentPosition();
      final region = RegionService.getRegionFromCoordinates(position.latitude, position.longitude);
      if (region != null && mounted) {
        setState(() => _selectedRegion = region);
        await preferencesService.setRegion(region);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Detected: $region')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Location error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
          context.t('settings.title'),
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // General
                _buildSectionTitle(context.t('settingsView.general')),
                const SizedBox(height: 10),
                _buildSettingsCard([
                  _buildSettingsItem(
                    icon: LucideIcons.globe,
                    title: context.t('settings.language'),
                    trailing: Text(currentLang.nativeName, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                    onTap: widget.onLanguageChange,
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: LucideIcons.mapPin,
                    title: 'Region',
                    trailing: Text(_selectedRegion, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 14)),
                    onTap: _onRegionTap,
                  ),
                  _buildDivider(),
                  _buildSwitchItem(
                    icon: LucideIcons.moon,
                    title: context.t('settingsView.darkMode'),
                    value: _darkMode,
                    onChanged: (val) => setState(() => _darkMode = val),
                  ),
                ]),

                const SizedBox(height: 24),

                // Notifications
                _buildSectionTitle(context.t('settingsView.notifications')),
                const SizedBox(height: 10),
                _buildSettingsCard([
                  _buildSwitchItem(
                    icon: LucideIcons.bell,
                    title: context.t('settingsView.pushNotifications'),
                    value: _pushNotifications,
                    onChanged: (val) => setState(() => _pushNotifications = val),
                  ),
                  _buildDivider(),
                  _buildSwitchItem(
                    icon: LucideIcons.alertTriangle,
                    title: context.t('settingsView.pestAlerts'),
                    value: _pestAlerts,
                    onChanged: (val) => setState(() => _pestAlerts = val),
                  ),
                ]),

                const SizedBox(height: 24),

                // Audio
                _buildSectionTitle(context.t('settingsView.audio')),
                const SizedBox(height: 10),
                _buildSettingsCard([
                  _buildSwitchItem(
                    icon: LucideIcons.volume2,
                    title: context.t('settingsView.soundEffects'),
                    value: _soundEnabled,
                    onChanged: (val) => setState(() => _soundEnabled = val),
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: LucideIcons.mic,
                    title: context.t('settingsView.voiceSettings'),
                    onTap: () {},
                  ),
                ]),

                const SizedBox(height: 24),

                // About
                _buildSectionTitle(context.t('settingsView.aboutSection')),
                const SizedBox(height: 10),
                _buildSettingsCard([
                  _buildSettingsItem(
                    icon: LucideIcons.info,
                    title: context.t('settingsView.appVersion'),
                    trailing: Text('1.0.0', style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 14)),
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: LucideIcons.fileText,
                    title: context.t('settingsView.termsOfService'),
                    onTap: () {},
                  ),
                  _buildDivider(),
                  _buildSettingsItem(
                    icon: LucideIcons.shield,
                    title: context.t('settingsView.privacyPolicy'),
                    onTap: () {},
                  ),
                ]),

                const SizedBox(height: 32),

                // Clear Data
                Center(
                  child: TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(LucideIcons.trash2, color: Color(0xFFEF4444), size: 18),
                    label: Text(
                      context.t('settingsView.clearData'),
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 15),
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

  Widget _buildSectionTitle(String title) {
    return Text(
      title.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: Colors.white.withOpacity(0.4),
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildSettingsCard(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.04),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    Widget? trailing,
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
                child: Text(
                  title,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.85)),
                ),
              ),
              if (trailing != null) ...[trailing, const SizedBox(width: 4)],
              Icon(Icons.chevron_right, color: Colors.white.withOpacity(0.2), size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
            child: Text(
              title,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white.withOpacity(0.85)),
            ),
          ),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: const Color(0xFF10B981),
            inactiveTrackColor: Colors.white.withOpacity(0.1),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Divider(height: 1, indent: 60, color: Colors.white.withOpacity(0.05));
  }
}

import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

/// Audio Settings View - Audio and TTS settings
/// Matches React's AudioSettingsPanel component
class AudioSettingsView extends StatefulWidget {
  final VoidCallback onBack;

  const AudioSettingsView({
    super.key,
    required this.onBack,
  });

  @override
  State<AudioSettingsView> createState() => _AudioSettingsViewState();
}

class _AudioSettingsViewState extends State<AudioSettingsView> {
  bool _soundEnabled = true;
  bool _ttsEnabled = true;
  bool _hapticFeedback = true;
  double _volume = 0.8;
  double _speechRate = 0.5;
  String _selectedVoice = 'Female';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: widget.onBack,
          color: AppColors.gray700,
        ),
        title: const Text(
          'Audio Settings',
          style: TextStyle(color: AppColors.gray800),
        ),
        centerTitle: true,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.nature50, Color(0xFFD1FAE5)],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Sound Effects Section
              _buildSection(
                title: 'Sound Effects',
                children: [
                  _buildSwitchItem(
                    icon: Icons.volume_up,
                    title: 'Sound Effects',
                    subtitle: 'Play sounds for actions and alerts',
                    value: _soundEnabled,
                    onChanged: (val) => setState(() => _soundEnabled = val),
                  ),
                  if (_soundEnabled) ...[
                    const SizedBox(height: 16),
                    _buildSliderItem(
                      icon: Icons.tune,
                      title: 'Volume',
                      value: _volume,
                      onChanged: (val) => setState(() => _volume = val),
                    ),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // Text-to-Speech Section
              _buildSection(
                title: 'Text-to-Speech',
                children: [
                  _buildSwitchItem(
                    icon: Icons.record_voice_over,
                    title: 'Voice Feedback',
                    subtitle: 'Read diagnosis results aloud',
                    value: _ttsEnabled,
                    onChanged: (val) => setState(() => _ttsEnabled = val),
                  ),
                  if (_ttsEnabled) ...[
                    const SizedBox(height: 16),
                    _buildSliderItem(
                      icon: Icons.speed,
                      title: 'Speech Rate',
                      value: _speechRate,
                      onChanged: (val) => setState(() => _speechRate = val),
                      labels: const ['Slow', 'Normal', 'Fast'],
                    ),
                    const SizedBox(height: 16),
                    _buildVoiceSelector(),
                  ],
                ],
              ),

              const SizedBox(height: 24),

              // Haptic Section
              _buildSection(
                title: 'Haptics',
                children: [
                  _buildSwitchItem(
                    icon: Icons.vibration,
                    title: 'Haptic Feedback',
                    subtitle: 'Vibrate on button press',
                    value: _hapticFeedback,
                    onChanged: (val) => setState(() => _hapticFeedback = val),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Test Button
              Center(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('🔊 Testing audio settings...'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Test Audio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.nature600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.gray800,
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSwitchItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.nature100,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 24, color: AppColors.nature600),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.gray800,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: AppColors.nature600,
        ),
      ],
    );
  }

  Widget _buildSliderItem({
    required IconData icon,
    required String title,
    required double value,
    required ValueChanged<double> onChanged,
    List<String>? labels,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: AppColors.gray500),
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray600,
              ),
            ),
            const Spacer(),
            Text(
              '${(value * 100).round()}%',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.nature600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: AppColors.nature500,
            inactiveTrackColor: AppColors.gray200,
            thumbColor: AppColors.nature600,
            overlayColor: AppColors.nature200,
          ),
          child: Slider(
            value: value,
            onChanged: onChanged,
          ),
        ),
        if (labels != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: labels.map((l) => Text(
                l,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.gray400,
                ),
              )).toList(),
            ),
          ),
      ],
    );
  }

  Widget _buildVoiceSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.person, size: 20, color: AppColors.gray500),
            const SizedBox(width: 8),
            Text(
              'Voice Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: AppColors.gray600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildVoiceOption('Female', Icons.woman),
            const SizedBox(width: 12),
            _buildVoiceOption('Male', Icons.man),
          ],
        ),
      ],
    );
  }

  Widget _buildVoiceOption(String name, IconData icon) {
    final isSelected = _selectedVoice == name;
    
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedVoice = name),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.nature100 : AppColors.gray50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppColors.nature500 : AppColors.gray200,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 32,
                color: isSelected ? AppColors.nature600 : AppColors.gray400,
              ),
              const SizedBox(height: 8),
              Text(
                name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? AppColors.nature600 : AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

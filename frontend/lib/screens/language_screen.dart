import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/language_provider.dart';
import '../core/localization/translation_service.dart';

/// Screen for selecting the application language.
/// Redesigned with AgriTech Light theme.
class LanguageScreen extends StatefulWidget {
  final Function(String) onSelect;

  const LanguageScreen({
    super.key,
    required this.onSelect,
  });

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isListening = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _startVoiceInput() {
    setState(() {
      _isListening = true;
    });
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isListening = false;
        });
      }
    });
  }

  void _stopVoiceInput() {
    setState(() {
      _isListening = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.read<LanguageProvider>();
    final filteredLanguages = languageProvider.filterLanguages(_searchQuery);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Background soft gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFFE8F5E9),
                  AppColors.background,
                ],
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 48),
                
                // Header
                Text(
                  context.t('languageScreen.title'),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Select your preferred language',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                const SizedBox(height: 40),

                // Search and Voice Input
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      // Modern Search Box
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: AppColors.softShadow,
                            border: Border.all(color: AppColors.primary.withOpacity(0.05)),
                          ),
                          child: TextField(
                            controller: _searchController,
                            onChanged: (value) {
                              setState(() {
                                _searchQuery = value;
                              });
                            },
                            decoration: InputDecoration(
                              hintText: context.t('languageScreen.searchPlaceholder'),
                              hintStyle: const TextStyle(color: AppColors.textHint, fontSize: 15),
                              prefixIcon: const Icon(
                                LucideIcons.search,
                                color: AppColors.primary,
                                size: 20,
                              ),
                              suffixIcon: _searchQuery.isNotEmpty
                                  ? IconButton(
                                      icon: const Icon(LucideIcons.xCircle, size: 20, color: AppColors.textHint),
                                      onPressed: () {
                                        _searchController.clear();
                                        setState(() {
                                          _searchQuery = '';
                                        });
                                      },
                                    )
                                  : null,
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),

                      // Premium Voice Button
                      GestureDetector(
                        onTap: _isListening ? _stopVoiceInput : _startVoiceInput,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _isListening ? AppColors.error : AppColors.primary,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: (_isListening ? AppColors.error : AppColors.primary).withOpacity(0.35),
                                blurRadius: 15,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isListening
                                ? _buildVoiceWaves()
                                : const Icon(
                                    LucideIcons.mic,
                                    size: 24,
                                    color: Colors.white,
                                  ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                if (_isListening)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Text(
                      context.t('languageScreen.listening'),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1,
                      ),
                    ),
                  ),

                const SizedBox(height: 32),

                // Language Grid
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: filteredLanguages.isEmpty
                        ? const Center(
                            child: Text(
                              'No matching languages found',
                              style: TextStyle(color: AppColors.textHint, fontSize: 16),
                            ),
                          )
                        : GridView.builder(
                            physics: const BouncingScrollPhysics(),
                            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
                              crossAxisSpacing: 20,
                              mainAxisSpacing: 20,
                              childAspectRatio: 1.6,
                            ),
                            itemCount: filteredLanguages.length,
                            itemBuilder: (context, index) {
                              final lang = filteredLanguages[index];
                              return _buildLanguageButton(lang);
                            },
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageButton(LanguageInfo lang) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => widget.onSelect(lang.code),
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            boxShadow: AppColors.softShadow,
            border: Border.all(color: AppColors.primary.withOpacity(0.08)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                lang.nativeName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
              if (lang.code != 'en') ...[
                const SizedBox(height: 6),
                Text(
                  lang.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary.withOpacity(0.6),
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVoiceWaves() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.5, end: 1.0),
          duration: Duration(milliseconds: 600 + (index * 150)),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Container(
              width: 3,
              height: 10 + (index == 1 ? 10.0 : 4.0) * value,
              margin: const EdgeInsets.symmetric(horizontal: 2.5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(3),
              ),
            );
          },
        );
      }),
    );
  }
}


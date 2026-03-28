import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_colors.dart';
import '../core/providers/language_provider.dart';
import '../services/consent_service.dart';
import '../services/preferences_service.dart';
import '../services/crop_service.dart' hide preferencesService;
import '../widgets/crop_advice_card.dart';
import 'landing_page.dart';
import 'consent_screen.dart';
import 'language_screen.dart';
import 'login_screen.dart';
import 'home_view.dart';
import 'camera_capture_view.dart';
import 'upload_view.dart';
import 'voice_doctor_view.dart';
import 'history_view.dart';
import 'user_profile_view.dart';
import 'settings_view.dart';
import 'audio_settings_view.dart';
import 'video_recorder_view.dart';
import 'llm_advice_view.dart';
import 'smart_camera_guide_view.dart';
import 'diagnosis_result_screen.dart';
import 'chatbot_view.dart';
import 'farmer_calendar_screen.dart';
import '../models/pending_media.dart';
import '../models/analysis_result.dart';
import '../services/offline_storage_service.dart';
import 'marketing_home_page.dart';

/// The main application widget that manages the high-level app state and navigation flow.
/// 
/// This component acts as the root navigator, switching between different screens based on:
/// - Initialization status (loading)
/// - Consent status (marketing -> consent)
/// - Authentication status (login)
/// - Language selection status
/// - Main app navigation (home, camera, profile, etc.)
/// 
/// Equivalent to React's `MainAppFlow` and `CropDiagnosisApp` components.
class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Current high-level state of the app
  String _appState = 'loading'; // loading, landing, consent, login, language, app, marketing
  
  // Current view within the 'app' state
  String _currentView = 'home';
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    _initApp();
  }

  /// Initializes core services and determines the initial app state.
  Future<void> _initApp() async {
    await preferencesService.init();
    await consentService.init();
    
    // US15: Attempt to sync any pending offline media
    // Fire and forget - don't block app startup
    offlineStorageService.syncAllPending().then((result) {
      if (result.success > 0) {
        debugPrint('Synced ${result.success} offline items');
      }
    });

    final hasConsent = await consentService.hasConsent();
    
    if (!mounted) return;
    
    setState(() {
      _appState = hasConsent ? 'app' : 'marketing'; // Start with marketing page if no consent yet
      _isOnline = true; 
    });
  }

  /// Handles the user choosing to continue as a guest.
  void _handleGuestContinue() async {
    await consentService.setGuestMode(true);
    if (!mounted) return;
    setState(() {
      _appState = 'consent';
    });
  }

  /// Transitions to the login screen.
  void _handleLogin() {
    setState(() {
      _appState = 'login';
    });
  }

  /// Handles the completion of the consent flow.
  void _handleConsentGiven() async {
    await consentService.giveConsent();
    
    if (!mounted) return;
    
    // Check if language is selected
    final languageProvider = context.read<LanguageProvider>();
    if (!languageProvider.isLanguageSelected) {
      setState(() {
        _appState = 'language';
      });
    } else {
      setState(() {
        _appState = 'app';
      });
    }
  }

  /// Handles successful login or skipping login.
  /// 
  /// Checks for consent status again to ensure compliance even after login.
  void _handleLoginComplete() async {
    // US5: Explicitly require consent even after login
    // Don't auto-grant consent. Check if already given?
    // If we consider "Login" as "Account Creation", we should show consent.
    
    if (!mounted) return;
    
    final hasConsent = await consentService.hasConsent();
    
    if (hasConsent) {
      // Already consented (maybe previous session)
      _checkLanguageAndProceed();
    } else {
      // Send to consent screen
      setState(() {
        _appState = 'consent';
      });
    }
  }

  /// Checks if a language is selected and navigates accordingly.
  void _checkLanguageAndProceed() {
    final languageProvider = context.read<LanguageProvider>();
    if (!languageProvider.isLanguageSelected) {
      setState(() {
        _appState = 'language';
      });
    } else {
      setState(() {
        _appState = 'app';
      });
    }
  }

  /// Handles language selection and transitions to the main app.
  void _handleLanguageSelect(String code) async {
    final languageProvider = context.read<LanguageProvider>();
    await languageProvider.setLanguage(code);
    if (!mounted) return;
    setState(() {
      _appState = 'app';
    });
  }

  /// Navigates to a specific view within the main app.
  void _navigateTo(String view) {
    setState(() {
      _currentView = view;
    });
  }

  @override
  Widget build(BuildContext context) {
    switch (_appState) {
      case 'loading':
        return _buildLoadingScreen();
      case 'marketing':
        return MarketingHomePage(
          onLaunch: () => setState(() => _appState = 'landing'),
        );
      case 'landing':
        return LandingPage(
          onGuest: _handleGuestContinue,
          onLogin: _handleLogin,
        );
      case 'consent':
        return ConsentScreen(onConsent: _handleConsentGiven);
      case 'login':
        return LoginScreen(
          onLogin: _handleLoginComplete,
          onSkip: _handleLoginComplete,
        );
      case 'language':
        return LanguageScreen(onSelect: _handleLanguageSelect);
      case 'app':
        return _buildMainApp();
      default:
        return _buildLoadingScreen();
    }
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.nature50, Color(0xFFD1FAE5)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  color: AppColors.nature600,
                  strokeWidth: 4,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Loading your preferences...',
                style: TextStyle(
                  color: AppColors.gray600,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMainApp() {
    // If we are in a full-screen sub-flow (camera, upload, etc), show it without bottom nav
    final fullScreenViews = {
      'camera', 'upload', 'voice', 'video', 'history',
      'profile', 'settings', 'audio-settings', 'llm-advice',
      'smart-camera-guide',
    };

    if (fullScreenViews.contains(_currentView)) {
      return Scaffold(body: _buildCurrentView());
    }

    return _MainScaffold(
      currentView: _currentView,
      onNavigate: _navigateTo,
      buildCurrentView: _buildCurrentView,
    );
  }

  /// Router for the specific view content within the main app layout.
  Widget _buildCurrentView() {
    switch (_currentView) {
      case 'home':
        return HomeView(
          onNavigate: (view) {
            if (view == 'camera') {
              _navigateTo('smart-camera-guide');
            } else {
              _navigateTo(view);
            }
          },
          isOnline: _isOnline,
        );

      case 'smart-camera-guide':
        return SmartCameraGuideView(
          onBack: () => _navigateTo('home'),
          onStart: () => _navigateTo('camera'),
        );

      case 'camera':
        return CameraCaptureView(
          onBack: () => _navigateTo('home'),
          onCapture: (path, {String? base64Content}) async {
            // Show loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (c) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
            
            try {
              // Analyze
              final result = await cropService.analyzeImage(path);
              
              if (!mounted) return;
              Navigator.pop(context); // Hide loading
              
              // US16: Confirmation
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Analysis saved to history'),
                  backgroundColor: AppColors.nature600,
                  duration: Duration(seconds: 2),
                ),
              );
              
              // US17-20: Show DiagnosisResultScreen with full results
              if (!mounted) return;
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DiagnosisResultScreen(
                    result: result,
                    onClose: () => Navigator.of(context).pop(),
                  ),
                ),
              );
              
              if (!mounted) return;
              _navigateTo('home');
              
            } catch (e) {
              if (!mounted) return;
              Navigator.pop(context); // Hide loading
              
              final errorStr = e.toString();
              
              // Handle identification failures (Low confidence, Non-leaf, or Drawing) with a bottom sheet
              if (errorStr.contains('confidence') || 
                  errorStr.contains('leaf') ||
                  errorStr.contains('drawing') || 
                  errorStr.contains('illustration')) {
                 _showErrorBottomSheet(context, errorStr.replaceFirst('Exception: ', ''));
                return;
              }

              // US15: Offline Fallback - Save to PendingMedia
              try {
                // ... (rest of offline logic remains same)
                final media = PendingMedia(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  filePath: path,
                  fileType: 'image',
                  createdAt: DateTime.now().millisecondsSinceEpoch,
                  base64Content: base64Content, // For web persistence
                );
                
                await offlineStorageService.savePendingMedia(media);
                
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Offline: Image saved to history for later'),
                    backgroundColor: AppColors.nature600,
                  ),
                );
                _navigateTo('home');
              } catch (saveError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error analyzing and saving: $e')),
                );
              }
            }
          },
        );
      case 'upload':
        return UploadView(
          onBack: () => _navigateTo('home'),
          onImagesSelected: (paths) async {
            if (paths.isEmpty) return;
            
            // Show loading
            showDialog(
              context: context,
              barrierDismissible: false,
              builder: (c) => const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            );
            
            try {
              AnalysisResult? firstResult;
              int successCount = 0;

              // US12: Process multiple images
              for (int i = 0; i < paths.length; i++) {
                final path = paths[i];
                // Update loading status if we could (requires stateful builder in dialog, skipping for simplicity)
                
                final result = await cropService.analyzeImage(path);
                if (i == 0) firstResult = result;
                successCount++;
              }
              
              if (!mounted) return;
              Navigator.pop(context); // Hide loading
              
              // Show notification for multiple items
              if (paths.length > 1) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Analyzed $successCount images. Results saved to history.'),
                    backgroundColor: AppColors.nature600,
                  ),
                );
              }

              // US17-20: Show DiagnosisResultScreen for the first result
              if (firstResult != null && mounted) {
                await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => DiagnosisResultScreen(
                      result: firstResult!,
                      onClose: () => Navigator.of(context).pop(),
                    ),
                  ),
                );
              }
              
              if (!mounted) return;
              _navigateTo('home');
              
            } catch (e) {
              if (!mounted) return;
              Navigator.pop(context); // Hide loading
              
              final errorStr = e.toString();
              if (errorStr.contains('confidence') || 
                  errorStr.contains('leaf') ||
                  errorStr.contains('drawing') || 
                  errorStr.contains('illustration')) {
                 _showErrorBottomSheet(context, errorStr.replaceFirst('Exception: ', ''));
                return;
              }

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Error analyzing images: $e')),
              );
            }
          },
        );
      case 'voice':
        return VoiceDoctorView(
          onBack: () => _navigateTo('home'),
        );
      case 'video':
        return VideoRecorderView(
          onBack: () => _navigateTo('home'),
          onVideoRecorded: (path) async {
            // Save as pending media
            final media = PendingMedia(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              filePath: path,
              fileType: 'video',
              createdAt: DateTime.now().millisecondsSinceEpoch,
              durationSeconds: 15, // Mock duration
            );
            
            await offlineStorageService.savePendingMedia(media);
            
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Video saved to gallery')),
            );
            _navigateTo('home');
          },
        );
      case 'history':
        return HistoryView(
          onBack: () => _navigateTo('home'),
        );
      case 'profile':
        return UserProfileView(
          onBack: () => _navigateTo('home'),
          onLogout: () {
            // Handle logout
            setState(() {
              _appState = 'landing';
              _currentView = 'home';
            });
          },
          onLanguageChange: () {
            setState(() {
              _appState = 'language';
            });
          },
        );
      case 'settings':
        return SettingsView(
          onBack: () => _navigateTo('home'),
          onLanguageChange: () {
            setState(() {
              _appState = 'language';
            });
          },
        );
      case 'audio-settings':
        return AudioSettingsView(
          onBack: () => _navigateTo('home'),
        );
      case 'llm-advice':
        return LlmAdviceView(
          onBack: () => _navigateTo('home'),
        );
      case 'chatbot':
        return ChatbotView(
          onClose: () => _navigateTo('home'),
        );
      case 'farmer-calendar':
        return FarmerCalendarScreen(
          onBack: () => _navigateTo('home'),
        );
      case 'auth':
        return LoginScreen(
          onLogin: () {
            setState(() => _appState = 'app');
            _navigateTo('home');
          },
          onSkip: () => _navigateTo('home'),
        );
      default:
        return HomeView(
          onNavigate: _navigateTo,
          isOnline: _isOnline,
        );
    }
  }

  Widget _buildPlaceholderView(String title, IconData icon) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => _navigateTo('home'),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.nature50, Color(0xFFD1FAE5)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
               Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.nature100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 80,
                  color: AppColors.nature500,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.gray800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Coming soon...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorBottomSheet(BuildContext context, String errorText) {
    // Determine icon and theme based on error type
    final isDrawing = errorText.toLowerCase().contains('drawing') || errorText.toLowerCase().contains('illustration');
    final isNotLeaf = errorText.toLowerCase().contains('leaf');
    
    IconData icon;
    Color color;
    String title;
    
    if (isDrawing) {
      icon = Icons.brush;
      color = Colors.orange;
      title = 'Illustration Detected';
    } else if (isNotLeaf) {
      icon = Icons.nature_people_outlined;
      color = Colors.redAccent;
      title = 'Not a Plant Leaf';
    } else {
      icon = Icons.center_focus_weak;
      color = AppColors.nature600;
      title = 'Low Confidence';
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 4,
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 48, color: color),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.gray900,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                errorText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  height: 1.5,
                  color: AppColors.gray600,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (_currentView != 'camera' && _currentView != 'upload') {
                       _navigateTo('camera');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.nature600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Try Again',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
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

// Unit 64 by bhuvi-d

// =====================================================
// 5-TAB BOTTOM NAVIGATION SCAFFOLD
// =====================================================

class _MainScaffold extends StatefulWidget {
  final String currentView;
  final void Function(String) onNavigate;
  final Widget Function() buildCurrentView;

  const _MainScaffold({
    required this.currentView,
    required this.onNavigate,
    required this.buildCurrentView,
  });

  @override
  State<_MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<_MainScaffold>
    with SingleTickerProviderStateMixin {
  int _selectedIndex = 0;
  late AnimationController _micPulse;

  // Left tabs (left of the Voice FAB)
  static const _leftTabs = [
    _TabDef(label: 'Home', icon: Icons.home_rounded,       view: 'home'),
    _TabDef(label: 'Scan', icon: Icons.camera_alt_rounded, view: 'smart-camera-guide'),
  ];

  // Right tabs (right of the Voice FAB)
  static const _rightTabs = [
    _TabDef(label: 'History', icon: Icons.history_rounded,     view: 'history'),
    _TabDef(label: 'Chatbot', icon: Icons.chat_bubble_rounded, view: 'chatbot'),
    _TabDef(label: 'Profile', icon: Icons.person_rounded,      view: 'profile'),
  ];

  // All tabs combined (for index tracking)
  static const _allTabs = [..._leftTabs, ..._rightTabs];

  @override
  void initState() {
    super.initState();
    _micPulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _micPulse.dispose();
    super.dispose();
  }

  void _onTabTapped(int index) {
    if (index == _selectedIndex && index == 0) return;
    setState(() => _selectedIndex = index);
    widget.onNavigate(_allTabs[index].view);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.buildCurrentView(),
      // ─── Bottom navigation bar ──────────────────────────────────────────
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 12,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              // Left tabs
              ..._leftTabs.asMap().entries.map((e) {
                final i = e.key;
                final tab = e.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTapped(i),
                    behavior: HitTestBehavior.opaque,
                    child: _buildTabItem(tab, _selectedIndex == i),
                  ),
                );
              }),

              // Center space for FAB notch
              const SizedBox(width: 70),

              // Right tabs (index offset by _leftTabs.length)
              ..._rightTabs.asMap().entries.map((e) {
                final i = e.key + _leftTabs.length;
                final tab = e.value;
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _onTabTapped(i),
                    behavior: HitTestBehavior.opaque,
                    child: _buildTabItem(tab, _selectedIndex == i),
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(_TabDef tab, bool selected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          tab.icon,
          size: 22,
          color: selected ? const Color(0xFF2E7D32) : const Color(0xFF9E9E9E),
        ),
        const SizedBox(height: 2),
        Text(
          tab.label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? const Color(0xFF2E7D32) : const Color(0xFF9E9E9E),
          ),
        ),
      ],
    );
  }
}

class _TabDef {
  final String label;
  final IconData icon;
  final String view;
  const _TabDef({required this.label, required this.icon, required this.view});
}

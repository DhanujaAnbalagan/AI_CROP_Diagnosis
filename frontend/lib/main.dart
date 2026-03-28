import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/theme/app_theme.dart';
import 'core/providers/language_provider.dart';
import 'core/localization/translation_service.dart';
import 'services/preferences_service.dart';
import 'services/consent_service.dart';
import 'services/audio_service.dart';
import 'screens/main_app.dart';

// Firebase conditionally imported for platforms that support it
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// The main entry point for the CropAId application.
/// 
/// This function is responsible for:
/// 1. Initializing the Flutter binding.
/// 2. Initializing Firebase (if applicable).
/// 3. Setting preferred device orientations.
/// 4. Configuring the system UI overlay style.
/// 5. Initializing core services (Preferences, Consent, Audio).
/// 6. Running the [CropAIdApp].
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    debugPrint('Firebase initialization failed: $e');
  }

  // Set preferred orientations (only on mobile)
  if (!kIsWeb) {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  // Set system UI overlay style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
    ),
  );

  // Initialize services
  await preferencesService.init();
  await consentService.init();
  await audioService.init();

  runApp(const CropAIdApp());
}

/// The root widget of the CropAId application.
/// 
/// This widget sets up the [MaterialApp] with:
/// - A [MultiProvider] for state management (e.g., [LanguageProvider]).
/// - Theme configuration (light and dark modes).
/// - Localization support using [TranslationDelegate] and global delegates.
/// - The main home screen ([MainApp]).
class CropAIdApp extends StatelessWidget {
  const CropAIdApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
      ],
      child: Consumer<LanguageProvider>(
        builder: (context, languageProvider, child) {
          return MaterialApp(
            title: 'CropAId',
            debugShowCheckedModeBanner: false,
            
            // Theme
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.light,

            // Localization
            locale: languageProvider.locale,
            supportedLocales: supportedLanguages.map((l) => l.locale).toList(),
            localizationsDelegates: const [
              TranslationDelegate(),
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],

            // Main App
            home: const MainApp(),
          );
        },
      ),
    );
  }
}

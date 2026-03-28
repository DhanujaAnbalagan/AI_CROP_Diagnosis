import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing user consent and guest mode.
/// 
/// equivalent to React's consentService.js.
/// Uses [SharedPreferences] to persist consent status and guest mode preference.
class ConsentService {
  static const String _consentKey = 'user_consent';
  static const String _guestModeKey = 'guest_mode';

  SharedPreferences? _prefs;

  /// Initializes the service by loading [SharedPreferences].
  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  /// Returns the [SharedPreferences] instance, initializing it if necessary.
  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Checks if the user has given consent.
  Future<bool> hasConsent() async {
    final p = await prefs;
    return p.getBool(_consentKey) ?? false;
  }

  /// Grants user consent.
  Future<void> giveConsent() async {
    final p = await prefs;
    await p.setBool(_consentKey, true);
  }

  /// Revokes user consent.
  Future<void> revokeConsent() async {
    final p = await prefs;
    await p.setBool(_consentKey, false);
  }

  /// Checks if the app is in guest mode.
  Future<bool> isGuestMode() async {
    final p = await prefs;
    return p.getBool(_guestModeKey) ?? false;
  }

  /// Sets the guest mode status.
  Future<void> setGuestMode(bool isGuest) async {
    final p = await prefs;
    await p.setBool(_guestModeKey, isGuest);
  }

  /// Clears all consent and guest mode data.
  Future<void> clear() async {
    final p = await prefs;
    await p.remove(_consentKey);
    await p.remove(_guestModeKey);
  }
}

/// Global singleton instance of [ConsentService].
final consentService = ConsentService();

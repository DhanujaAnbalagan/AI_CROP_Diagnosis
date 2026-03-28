import 'package:shared_preferences/shared_preferences.dart';

/// Service for managing notification pause functionality.
class NotificationPauseService {
  static const String _pauseUntilKey = 'notifications_pause_until';
  static const String _isPausedKey = 'notifications_is_paused';

  /// Pause notifications for specified duration in hours
  static Future<void> pauseNotifications(int hours) async {
    final prefs = await SharedPreferences.getInstance();
    final pauseUntil = DateTime.now().add(Duration(hours: hours));
    
    await prefs.setInt(_pauseUntilKey, pauseUntil.millisecondsSinceEpoch);
    await prefs.setBool(_isPausedKey, true);
  }

  /// Resume notifications immediately
  static Future<void> resumeNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pauseUntilKey);
    await prefs.setBool(_isPausedKey, false);
  }

  /// Check if notifications are currently paused
  static Future<bool> isPaused() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (!(prefs.getBool(_isPausedKey) ?? false)) {
      return false;
    }

    final pauseUntil = prefs.getInt(_pauseUntilKey);
    if (pauseUntil == null) return false;

    final pauseUntilTime = DateTime.fromMillisecondsSinceEpoch(pauseUntil);
    if (DateTime.now().isAfter(pauseUntilTime)) {
      // Pause period has expired, resume notifications
      await resumeNotifications();
      return false;
    }

    return true;
  }

  /// Get pause status text for display
  static Future<String> getPauseStatusText() async {
    final isPaused = await NotificationPauseService.isPaused();
    if (!isPaused) return 'Notifications Active';

    final prefs = await SharedPreferences.getInstance();
    final pauseUntil = prefs.getInt(_pauseUntilKey);
    if (pauseUntil == null) return 'Notifications Paused';

    final pauseUntilTime = DateTime.fromMillisecondsSinceEpoch(pauseUntil);
    final remaining = pauseUntilTime.difference(DateTime.now());

    if (remaining.inHours > 0) {
      return 'Paused for ${remaining.inHours}h ${remaining.inMinutes % 60}m';
    } else {
      return 'Paused for ${remaining.inMinutes}m';
    }
  }

  /// Get remaining pause time in minutes
  static Future<int?> getRemainingPauseMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    final pauseUntil = prefs.getInt(_pauseUntilKey);
    if (pauseUntil == null) return null;

    final pauseUntilTime = DateTime.fromMillisecondsSinceEpoch(pauseUntil);
    if (DateTime.now().isAfter(pauseUntilTime)) return null;

    return pauseUntilTime.difference(DateTime.now()).inMinutes;
  }
}

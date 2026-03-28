import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Handles local notification scheduling and permission requests for the Farmer Calendar.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    // On web/desktop, notifications are not supported - silently skip
    if (kIsWeb) {
      _initialized = true;
      return;
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  /// Request notification permissions (iOS / newer Android).
  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    try {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        final granted = await androidPlugin.requestNotificationsPermission();
        return granted ?? false;
      }
      final iosPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        final granted = await iosPlugin.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return false;
    } catch (e) {
      debugPrint('NotificationService.requestPermission error: $e');
      return false;
    }
  }

  /// Schedule a one-time notification for a reminder.
  Future<void> scheduleReminder({
    required int notificationId,
    required String title,
    required String body,
    required DateTime scheduledDateTime,
  }) async {
    if (kIsWeb || !_initialized) return;
    try {
      const androidDetails = AndroidNotificationDetails(
        'farmer_calendar',
        'Farmer Calendar Reminders',
        channelDescription: 'Notifications for crop care reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      );
      const darwinDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );
      const notifDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _plugin.show(
        notificationId,
        title,
        body,
        notifDetails,
      );
    } catch (e) {
      debugPrint('NotificationService.scheduleReminder error: $e');
    }
  }

  /// Cancel a specific notification by ID.
  Future<void> cancelNotification(int notificationId) async {
    if (kIsWeb || !_initialized) return;
    await _plugin.cancel(notificationId);
  }
}

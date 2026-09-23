import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

/// Service for scheduling and firing local notifications.
///
/// Uses flutter_local_notifications. Depends on nothing in the data layer —
/// call it from providers after a status change.
class NotificationService {
  static const _notifEnabledKey = 'medtrack_notifications_enabled';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);
    _initialized = true;

    // Request Android 13+ POST_NOTIFICATIONS permission
    if (Platform.isAndroid) {
      final androidPlugin =
          _plugin.resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.requestNotificationsPermission();
    }
  }

  Future<bool> get isEnabled async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notifEnabledKey) ?? true;
  }

  Future<void> setEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notifEnabledKey, enabled);
    if (!enabled) {
      await _plugin.cancelAll();
    }
  }

  static const AndroidNotificationDetails _androidDetails =
      AndroidNotificationDetails(
    'medtrack_channel',
    'MedTrack Reminders',
    channelDescription: 'Medication dose reminders and alerts',
    importance: Importance.high,
    priority: Priority.high,
    icon: '@mipmap/ic_launcher',
  );

  static const NotificationDetails _notifDetails =
      NotificationDetails(android: _androidDetails);

  /// Fires an immediate notification when a dose is marked Missed.
  Future<void> showMissedDoseNotification({
    required int id,
    required String compartmentLabel,
    required String medicineName,
  }) async {
    if (!await isEnabled) return;
    await _plugin.show(
      id,
      '$compartmentLabel dose missed',
      '$medicineName was not collected in time.',
      _notifDetails,
    );
  }

  /// Fires an immediate notification when a dose becomes due.
  Future<void> showDueDoseNotification({
    required int id,
    required String compartmentLabel,
    required String medicineName,
    required String scheduledTime,
  }) async {
    if (!await isEnabled) return;
    await _plugin.show(
      id,
      'Time for your $compartmentLabel dose',
      '$medicineName is ready at $scheduledTime.',
      _notifDetails,
    );
  }

  Future<void> cancelAll() async => _plugin.cancelAll();
}

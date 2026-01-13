import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/material.dart';

import 'package:flutter_timezone/flutter_timezone.dart';
import '../utils/app_globals.dart';
import '../data/note_repository.dart';
import '../screens/notes/new_note_screen.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() => _instance;

  NotificationService._internal();

  final FlutterLocalNotificationsPlugin notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz.initializeTimeZones();

    // 2. Get the device's timezone (e.g., "America/Detroit")
    final timeZoneInfo = await FlutterTimezone.getLocalTimezone();
    final String timeZoneName = timeZoneInfo.identifier;

    // 3. Set the local location
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await notificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse:
          (NotificationResponse notificationResponse) async {
            // Handle notification tap
            final String? payload = notificationResponse.payload;
            if (payload != null) {
              debugPrint('Notification tapped with payload: $payload');

              // Use global navigator key to push screen
              final note = NoteRepository.box.get(payload);
              if (note != null) {
                navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (_) => NewNoteScreen(existingNote: note),
                  ),
                );
              }
            }
          },
    );

    // Request permission for Android 13+
    final androidImplementation = notificationsPlugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (androidImplementation != null) {
      await androidImplementation.requestNotificationsPermission();
      await androidImplementation.requestExactAlarmsPermission();
    }
  }

  // Helper to generate a safe 32-bit integer ID from a String UUID
  static int generateId(String id) {
    return id.hashCode & 0x7FFFFFFF;
  }

  Future<void> scheduleReminder({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledTime,
    String? payload, // Note ID to navigate to
  }) async {
    try {
      final localizedTime = tz.TZDateTime.from(scheduledTime, tz.local);
      debugPrint(
        '🔍 TIMEZONE DEBUG: Detected Local Timezone: ${tz.local.name}',
      );
      debugPrint('🔍 TIMEZONE DEBUG: Raw Scheduled Time: $scheduledTime');
      debugPrint('🔍 TIMEZONE DEBUG: Converted TZ Time: $localizedTime');
      debugPrint(
        '🔍 TIMEZONE DEBUG: Current TZ Time: ${tz.TZDateTime.now(tz.local)}',
      );

      await notificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        localizedTime,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'reminder_channel_v2', // New channel ID to apply updated settings
            'Reminders', // channel Name
            channelDescription: 'Channel for note reminders',
            importance: Importance.max,
            priority: Priority.high,
            playSound: true, // Explicitly enable sound
            enableVibration: true, // Enable vibration
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true, // Show alert even in foreground
            presentSound: true, // Play sound even in foreground
            presentBadge: true, // Update badge even in foreground
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        // uiLocalNotificationDateInterpretation:
        //    UILocalNotificationDateInterpretation.absoluteTime,
        payload: payload,
      );
      debugPrint('Reminder scheduled for $scheduledTime (id: $id)');
    } catch (e) {
      debugPrint('Error scheduling notification: $e');
    }
  }

  Future<void> cancelReminder(int id) async {
    await notificationsPlugin.cancel(id);
    debugPrint('Reminder canceled (id: $id)');
  }

  // To check pending notifications (for debugging)
  Future<List<PendingNotificationRequest>> getPendingReminders() async {
    return await notificationsPlugin.pendingNotificationRequests();
  }
}

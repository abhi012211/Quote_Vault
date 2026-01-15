import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);

    // Initialize Timezone
    tz.initializeTimeZones();
    try {
      final dynamic timeZoneObject = await FlutterTimezone.getLocalTimezone();
      String timeZoneName = timeZoneObject.toString();

      // Handle verbose TimezoneInfo string if present
      // Example: TimezoneInfo(Asia/Calcutta, (locale: en_US, name: India Standard Time))
      if (timeZoneName.startsWith('TimezoneInfo')) {
        final match = RegExp(r'TimezoneInfo\(([^,]+)').firstMatch(timeZoneName);
        if (match != null) {
          timeZoneName = match.group(1) ?? 'UTC';
        }
      }
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (e) {
      debugPrint('Error loading timezone: $e');
      // Fallback to UTC
      tz.setLocalLocation(tz.getLocation('UTC'));
    }
  }

  Future<void> scheduleDailyQuoteNotification({
    int hour = 8,
    int minute = 0,
  }) async {
    // Cancel existing
    await cancelDailyNotification();

    await flutterLocalNotificationsPlugin.zonedSchedule(
      0,
      'Daily Quote',
      'Time for your daily dose of wisdom!',
      _nextInstanceOfTime(hour, minute),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_quote_channel',
          'Daily Quote',
          channelDescription: 'Daily reminder for quotes',
          importance: Importance.high,
          priority: Priority.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelDailyNotification() async {
    await flutterLocalNotificationsPlugin.cancel(0);
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }
}

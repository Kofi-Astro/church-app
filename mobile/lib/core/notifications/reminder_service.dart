import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

/// Local (on-device) daily reading reminder — the "Push/local reminders
/// for daily reading" item from the Phase 3 roadmap, activated here in
/// Phase 4. This is deliberately local-only, not FCM: sermon/live-service/
/// prayer-update push notifications need a Firebase project (an external
/// account this app doesn't have yet, same category as Supabase/Paystack),
/// so they're not wired up. A daily reminder needs no server at all — the
/// OS fires it — so it's fully working today.
class ReminderService {
  static const _reminderNotificationId = 1;
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    tz_data.initializeTimeZones();
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: androidSettings, iOS: iosSettings),
    );
    _initialized = true;
  }

  Future<bool> requestPermission() async {
    await _ensureInitialized();
    final androidGranted = await _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    final iosGranted = await _plugin
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(alert: true, badge: true, sound: true);
    return androidGranted ?? iosGranted ?? true;
  }

  Future<void> scheduleDailyReminder(TimeOfDay time) async {
    await _ensureInitialized();
    await _plugin.zonedSchedule(
      id: _reminderNotificationId,
      title: 'Time for your reading plan',
      body: "Keep your streak going — today's passage is waiting.",
      scheduledDate: _nextInstanceOf(time),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reading_reminders',
          'Reading plan reminders',
          importance: Importance.defaultImportance,
        ),
        iOS: DarwinNotificationDetails(),
      ),
      // "Inexact" avoids needing the SCHEDULE_EXACT_ALARM permission —
      // fine for a daily reminder that doesn't need to fire to the second.
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelReminder() async {
    await _plugin.cancel(id: _reminderNotificationId);
  }

  Future<bool> isScheduled() async {
    await _ensureInitialized();
    final pending = await _plugin.pendingNotificationRequests();
    return pending.any((r) => r.id == _reminderNotificationId);
  }

  tz.TZDateTime _nextInstanceOf(TimeOfDay time) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, time.hour, time.minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }
}

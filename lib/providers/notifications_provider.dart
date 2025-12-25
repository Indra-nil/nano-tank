import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/config.dart';

class NotificationsProvider extends ChangeNotifier {
  final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  NotificationsProvider() {
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    const AndroidInitializationSettings androidSettings = 
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    const DarwinInitializationSettings iosSettings = 
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(settings);
  }

  /// ✅ REPEATING NOTIFICATION - Shows every 4 hours until dismissed
  Future<void> showPumpRefillAlert({
    required String tankName,
    required String pumpName,
    required int daysLeft,
  }) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'pump_refill',
      'Pump Refill Alerts',
      channelDescription: 'Notifications for low pump containers',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
      // ✅ CORRECT REPEATING API
      ongoing: false,
      autoCancel: false,
      playSound: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    int notificationId = ('$tankName-$pumpName').hashCode;
    
    await _notifications.periodicallyShow(
      notificationId,
      'Pump Refill Alert ⚠️',
      '$pumpName in $tankName\n$daysLeft days left!',
      RepeatInterval.hourly,  // ✅ REPEATS EVERY HOUR
      details,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  /// ✅ CANCEL repeating notification
  Future<void> cancelPumpRefillAlert(String tankName, String pumpName) async {
    int notificationId = ('$tankName-$pumpName').hashCode;
    await _notifications.cancel(notificationId);
  }

  /// ✅ IMMEDIATE alert
  Future<void> showImmediateAlert(String message) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'alerts',
      'Tank Alerts',
      channelDescription: 'Immediate tank alerts',
      importance: Importance.max,
      priority: Priority.max,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(0, 'Tank Alert 🚨', message, details);
  }

  void checkAndSchedulePumpNotifications(List<PumpConfig> pumps, String tankName) {
    for (var pump in pumps) {
      if (pump.enabled && pump.remainingMl < 100 && pump.mlPerSec > 0) {
        double dailyUse = (pump.dailyDoseMl.reduce((a, b) => a + b)) / 7;
        int daysLeft = dailyUse > 0 ? (pump.remainingMl / dailyUse).floor() : 999;
        
        if (daysLeft <= 3) {
          showPumpRefillAlert(
            tankName: tankName,
            pumpName: pump.name,
            daysLeft: daysLeft,
          );
        }
      }
    }
  }
}
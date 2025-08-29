// lib/core/services/notification_service.dart

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

/// A dedicated service to handle all local notification logic for the app.
/// This includes initialization, permission requests, and showing specific notifications.
class NotificationService {
  // A static instance of the plugin, which we will initialize.
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // A private constructor to prevent direct instantiation.
  NotificationService._();

  /// Initializes the notification plugin with settings for Android and iOS.
  /// This should be called once when the app starts.
  static Future<void> initialize() async {
    // ✅ CHANGED: The icon name has been changed from 'app_icon' to '@mipmap/ic_launcher'.
    // '@mipmap/ic_launcher' is the default name for the app's main launcher icon
    // that is created with every new Flutter project. Using it ensures that the
    // notification plugin can always find a valid icon, preventing the app from crashing.
    //
    // ❗ TODO: For a production app, replace 'ic_launcher' with a custom-designed
    // notification icon. This icon should be a simple, white-on-transparent PNG
    // and be placed in the `android/app/src/main/res/drawable` folders.
    const AndroidInitializationSettings androidInitializationSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // Define the settings for iOS.
    const DarwinInitializationSettings darwinInitializationSettings =
        DarwinInitializationSettings();

    // Create the overall initialization settings object.
    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: androidInitializationSettings,
      iOS: darwinInitializationSettings,
    );

    // Initialize the plugin with the settings.
    await _notificationsPlugin.initialize(initializationSettings);
  }

  /// Requests notification permission from the user (required for Android 13+).
  /// This should be called at an appropriate time in the UI, like during onboarding.
  static Future<void> requestNotificationPermission() async {
    // Use the permission_handler package to request the notification permission.
    await Permission.notification.request();
  }

  /// Shows the "50% Usage Warning" notification.
  static Future<void> show50PercentWarning() async {
    await _showNotification(
      id: 1, // A unique ID for this notification type.
      title: 'Heads Up: Halfway There!',
      body: "You've used over 50% of your screen time limit for today. Keep up the great work!",
    );
  }

  /// Shows the "75% Usage Warning" notification.
  static Future<void> show75PercentWarning() async {
    await _showNotification(
      id: 2,
      title: "Approaching Your Limit",
      body: "You've now used over 75% of your daily screen time goal. Stay focused!",
    );
  }

  /// Shows the "90% Usage Warning" notification.
  static Future<void> show90PercentWarning() async {
    await _showNotification(
      id: 3,
      title: 'Final Warning: Almost at Your Limit',
      body: 'Be mindful of your usage to succeed today and earn your points!',
    );
  }

  /// Shows the critical "Failure Confirmation" notification.
  static Future<void> showFailureConfirmation() async {
    await _showNotification(
      id: 4,
      title: 'Accountability Alert: Limit Exceeded',
      body: "You've gone over your screen time limit. Your pledge for today is now confirmed and will be processed.",
    );
  }

  /// A private helper method to configure and display a notification.
  static Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    // Define the details for the Android notification.
    // 'channel_id' and 'channel_name' are important for Android 8.0+.
    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
      'screenpledge_warnings', // A unique channel ID.
      'Screen Time Warnings',    // The user-visible channel name.
      channelDescription: 'Notifications for screen time usage warnings.',
      importance: Importance.max,
      priority: Priority.high,
    );

    // Define the details for iOS notifications.
    const DarwinNotificationDetails darwinNotificationDetails =
        DarwinNotificationDetails();


    // Create the overall notification details object.
    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: darwinNotificationDetails,
    );

    // Use the plugin to show the notification.
    await _notificationsPlugin.show(
      id,
      title,
      body,
      notificationDetails,
    );
  }
}
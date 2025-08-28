// lib/features/onboarding_post/presentation/widgets/notification_permission_dialog.dart

import 'package:flutter/material.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/services/notification_service.dart';

/// A custom dialog that explains the value of notifications before requesting
/// the official system permission. This is a "priming" step to increase acceptance rates.
class NotificationPermissionDialog extends StatelessWidget {
  /// A callback function that is executed after the user has made a choice
  /// and the permission has been requested.
  final VoidCallback onContinue;

  const NotificationPermissionDialog({
    super.key,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return AlertDialog(
      // A rounded shape to match our app's aesthetic.
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.0)),
      // Remove default padding so our content can go to the edges.
      contentPadding: const EdgeInsets.all(24.0),
      content: Column(
        // `mainAxisSize: MainAxisSize.min` makes the dialog only as tall as its content.
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // An engaging image to visually represent notifications.
          Image.asset(
            'assets/mascot/mascot_notification.png', // Placeholder path
            height: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Enable Helpful Warnings?',
            style: textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'To help you succeed, we can send you timely notifications when you get close to your daily limit.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          // The primary button to enable notifications.
          PrimaryButton(
            text: 'Yes, Notify Me',
            onPressed: () async {
              // When tapped, first request the permission via our service.
              await NotificationService.requestNotificationPermission();
              // Then, if the widget is still mounted, close the dialog.
              if (context.mounted) {
                Navigator.of(context).pop();
              }
              // Finally, execute the callback to navigate to the next page.
              onContinue();
            },
          ),
          const SizedBox(height: 8),
          // A secondary option to skip.
          TextButton(
            onPressed: () {
              // If skipped, just close the dialog and navigate.
              Navigator.of(context).pop();
              onContinue();
            },
            child: Text(
              'Maybe Later',
              style: TextStyle(color: AppColors.secondaryText),
            ),
          ),
        ],
      ),
    );
  }
}
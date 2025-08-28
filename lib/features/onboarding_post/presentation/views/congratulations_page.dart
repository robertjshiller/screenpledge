// lib/features/onboarding_post/presentation/views/congratulations_page.dart

import 'package:flutter/material.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/features/onboarding_post/presentation/views/user_survey_page.dart';
// ✅ NEW: Import our new notification permission dialog.
import 'package:screenpledge/features/onboarding_post/presentation/widgets/notification_permission_dialog.dart';

/// A celebratory page shown after a user has successfully created and
/// verified their account.
///
/// This page serves as a positive reinforcement and a smooth transition
/// before proceeding to the final setup steps.
class CongratulationsPage extends StatelessWidget {
  const CongratulationsPage({super.key});

  // ✅ NEW: A private method to show our custom notification dialog.
  void _showNotificationDialog(BuildContext context) {
    showDialog(
      context: context,
      // The user can tap outside to dismiss, as this is not a mandatory step.
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        return NotificationPermissionDialog(
          // The onContinue callback defines what happens after the dialog is closed.
          onContinue: () {
            // Navigate to the user survey, replacing the current page.
            // This ensures the user can't go back to the congratulations page.
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (context) => const UserSurveyPage(),
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Spacer(),

              // A large, friendly icon to convey success.
              Icon(
                Icons.check_circle_outline_rounded,
                size: 100,
                color: AppColors.buttonStroke,
              ),
              const SizedBox(height: 32),

              // The main celebratory headline.
              Text(
                "You're All Set!",
                style: textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),

              // Encouraging body text that sets expectations for the next step.
              Text(
                "Your account is ready to go.\nLet's personalize your experience.",
                style: textTheme.bodyLarge?.copyWith(
                  color: AppColors.secondaryText,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(),

              // ✅ CHANGED: The button's onPressed callback now calls our new method
              // to show the notification priming dialog.
              PrimaryButton(
                text: "Let's Get Started",
                onPressed: () {
                  _showNotificationDialog(context);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
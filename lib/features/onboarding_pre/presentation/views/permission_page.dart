// lib/features/onboarding_pre/presentation/views/permission_page.dart

import 'package:flutter/material.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/features/onboarding_pre/presentation/views/data_reveal_sequence.dart';

/// A page that requests the user's permission to access screen time statistics.
///
/// This is a critical step in the onboarding process, as the core functionality
/// of the app depends on this permission. The page is designed to be clear,
/// reassuring, and to build trust with the user.
class PermissionPage extends StatelessWidget {
  /// A constant constructor for this stateless widget.
  const PermissionPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Using a Scaffold to provide the standard Material Design page structure.
    return Scaffold(
      // Using SafeArea to avoid system UI intrusions.
      body: SafeArea(
        // Padding around the entire content for better spacing.
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          // A Column to arrange the widgets vertically.
          child: Column(
            // Center the content horizontally.
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Spacer to push the content down from the top edge.
              const Spacer(flex: 2),
              // The main headline, using the extra-bold displayLarge text style.
              Text(
                'Let\'s Keep You \nFocused',
                style: Theme.of(context).textTheme.displayLarge,
                textAlign: TextAlign.center,
              ),
              // A fixed space between the headline and the mascot image.
              const SizedBox(height: 32),
              // The mascot image, constrained to 75% of the screen width.
              Image.asset(
                'assets/mascot/mascot_thumbs_up.png',
                width: MediaQuery.of(context).size.width * 0.75,
              ),
              // A fixed space between the image and the descriptive text.
              const SizedBox(height: 32),
              // The body text explaining why the permission is needed.
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22.0),
                child: Text(
                  'To help you build better habits, ScreenPledge needs permission to view your screen time stats. Your data is always kept private and secure.',
                  style: Theme.of(context).textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
              ),
              // Spacer to push the button and disclaimer to the bottom.
              const Spacer(flex: 3),
              // Padding to move the button/disclaimer area up by about one button height (56px).
              Padding(
                padding: const EdgeInsets.only(bottom: 56), // Adjust value to control how far up it moves
                child: Column(
                  children: [
                    // The primary call-to-action button.
                    SizedBox(
                      width: double.infinity,
                      child: PrimaryButton(
                        text: 'Allow Screen Time Access',
                        onPressed: () {
                          // Navigate to the DataRevealSequencePage when the button is tapped.
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const DataRevealSequence(),
                            ),
                          );
                        },
                      ),
                    ),
                    // A small space between the button and the disclaimer text.
                    const SizedBox(height: 16),
                    // The small disclaimer text.
                    Text(
                      'We only see app usage time -- never your content',
                      // Using the bodySmall text style.
                      style: Theme.of(context).textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    // Add a final SizedBox for some bottom padding.
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

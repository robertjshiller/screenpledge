// lib/features/onboarding_pre/presentation/views/get_started_page.dart

import 'package:flutter/material.dart';
import 'package:screenpledge/features/onboarding_pre/presentation/views/permission_page.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';

/// The very first screen a new user sees.
///
/// This page serves as the main entry point for the pre-subscription onboarding flow.
/// It presents a welcoming message with the app's mascot and provides clear
/// calls-to-action for new and returning users.
///
/// It is designed to be simple, visually appealing, and focused on conversion.
class GetStartedPage extends StatelessWidget {
  /// A constant constructor for this stateless widget.
  const GetStartedPage({super.key});

  @override
  Widget build(BuildContext context) {
    // The Scaffold provides the basic material design visual layout structure.
    return Scaffold(
      // SafeArea ensures that the content is not obscured by system intrusions
      // like the status bar or device notches.
      body: SafeArea(
        // The main layout is a Column to arrange widgets vertically.
        child: Column(
          children: [
            // This Expanded widget takes up the top half of the screen to display the mascot.
            Expanded(
              flex: 1,
              child: Center(
                // We now use Image.asset to render the PNG mascot image.
                child: Image.asset(
                  'assets/mascot/mascot_neutral.png',
                  // Optional: define a width to constrain the image's size.
                  width: MediaQuery.of(context).size.width * 0.75,
                ),
              ),
            ),
            // This Expanded widget contains the text and buttons in the bottom half.
            Expanded(
              flex: 1,
              child: Padding(
                // Padding is added to ensure content isn't flush against the screen edges.
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  // MainAxisAlignment.center centers the content vertically within this section.
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Header text, styled using the `headlineMedium` style from the app's theme.
                    Text(
                      'Welcome to ScreenPledge',
                      style: Theme.of(context).textTheme.displayLarge,
                      textAlign: TextAlign.center,
                    ),
                    // A small vertical space between the header and sub-header.
                    const SizedBox(height: 16),
                    // Sub-header text, using the `bodyLarge` style for a softer look.
                    Text(
                      'Let\'s reclaim your focus and fulfill your dreams.',
                      style: Theme.of(context).textTheme.bodyLarge,
                      textAlign: TextAlign.center,
                    ),
                    // A larger vertical space before the primary call-to-action.
                    const SizedBox(height: 48),
                    // The primary "Get Started" button, using our reusable component.
                    // This ensures consistent styling and behavior.
                    SizedBox(
                      width: double.infinity, // Make button take full width of its parent
                      child: PrimaryButton(
                        text: 'Get Started',
                        onPressed: () {
                          // Navigate to the PermissionPage when the button is tapped.
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => const PermissionPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    // A smaller space before the secondary action.
                    const SizedBox(height: 12),
                    // The secondary action for returning users.
                    // TextButton is used for a less prominent, text-only button.
                    TextButton(
                      onPressed: () {
                        // TODO: Implement navigation to the login screen.
                        print('Already have an account? tapped');
                      },
                      // The style is explicitly set to match the primary text color,
                      // making it functional but visually subtle against the background.
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primaryText,
                      ),
                      child: const Text('Already have an account?'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

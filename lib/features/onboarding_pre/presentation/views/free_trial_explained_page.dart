// lib/features/onboarding_pre/presentation/views/free_trial_explained_page.dart

import 'package:flutter/material.dart';
import 'package:screenpledge/features/onboarding_post/presentation/views/account_creation_page.dart';
import '../../../../core/config/theme/app_colors.dart';

/// A page that transparently explains the terms of the free trial to the user.
///
/// This screen is designed to build trust by clearly outlining the trial timeline,
/// including when the user will be reminded and when billing will start. It follows
/// the "Blinkist paywall" pattern, which is known for its user-centric and
/// transparent approach to subscription onboarding.
class FreeTrialExplainedPage extends StatelessWidget {
  const FreeTrialExplainedPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Using Scaffold to provide the basic material design visual layout structure.
    return Scaffold(
      // Setting the background color from our centralized app theme.
      backgroundColor: AppColors.background,
      // Using SafeArea to ensure the UI avoids system intrusions like notches.
      body: SafeArea(
        child: Padding(
          // Consistent padding around the content for a clean look.
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            // Cross axis alignment to stretch children to fill the width.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Spacer to push content down from the top edge, creating vertical balance.
              const Spacer(),

              // The main headline for the page, clearly stating its purpose.
              Text(
                'How Your\nFree Trial Works',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.displayLarge,
              ),

              // Vertical spacing between the title and the timeline.
              const SizedBox(height: 40),

              // The core visual element: the timeline explaining the trial steps.
              _buildTimeline(context),

              // Vertical spacing before the pricing information.
              const SizedBox(height: 32),

              // Explicitly stating the cost after the trial ends.
              // This transparency is key to building user trust.
              const Text(
                '7-day free trial, then\n\$19.99 per year (\$1.67/month)',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'OpenSans',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondaryText,
                ),
              ),

              // Spacer to push the action buttons towards the bottom of the screen.
              const Spacer(),
              const Spacer(),

              // The primary call-to-action button.
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const AccountCreationPage(),
                    ),
                    (Route<dynamic> route) => false,
                  );
                },
                style: ElevatedButton.styleFrom(
                  // Using brand colors for a consistent look and feel.
                  backgroundColor: AppColors.buttonFill,
                  foregroundColor: AppColors.buttonText,
                  // Defining the shape and padding of the button.
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  // Adding a subtle border for definition.
                  side: const BorderSide(color: AppColors.buttonStroke, width: 2),
                ),
                child: const Text(
                  'Start My 7 Day Free Trial',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              // Vertical spacing.
              const SizedBox(height: 16),

              // A secondary, less prominent option for users who are not ready to commit.
              TextButton(
                onPressed: () {
                  // TODO: Navigate to a page showing all subscription plans.
                  print('View other plans pressed');
                },
                child: Text(
                  'View other plans',
                  style: TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 16,
                    color: AppColors.secondaryText.withOpacity(0.8),
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),

              // Bottom padding to ensure content isn't flush with the screen edge.
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the vertical timeline widget.
  ///
  /// This method constructs the timeline using custom [_TimelineStep] widgets,
  /// which are connected visually by a line to represent the flow of time.
  Widget _buildTimeline(BuildContext context) {
    return Column(
      children: [
        // Step 1: Immediate access.
        _TimelineStep(
          icon: Icons.lock_open_outlined,
          title: 'Today',
          subtitle: 'Explore all features and content right away.',
          isFirst: true,
          iconBackgroundColor: Colors.blue,
        ),
        // Step 2: The reminder.
        _TimelineStep(
          icon: Icons.notifications_on_outlined,
          title: 'Day 5',
          subtitle: "We'll send a heads-up that your trial is ending.",
          iconBackgroundColor: Colors.blue,
        ),
        // Step 3: Billing starts.
        _TimelineStep(
          icon: Icons.star_border_outlined,
          title: 'Day 7',
          subtitle: 'Your annual subscription begins.\nCancel anytime before.',
          isLast: true,
          iconBackgroundColor: AppColors.buttonFill,
        ),
      ],
    );
  }
}

/// A custom widget to represent a single step in the vertical timeline.
///
/// It combines an icon, a title, and a subtitle, and connects vertically
/// to other steps with a line, creating a clear, easy-to-read timeline.
class _TimelineStep extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isFirst;
  final bool isLast;
  final Color iconBackgroundColor;

  const _TimelineStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isFirst = false,
    this.isLast = false,
    required this.iconBackgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    // IntrinsicHeight ensures that the Row's children, the icon column and the
    // text column, are forced to be the same height, allowing the vertical
    // line to be drawn correctly between them.
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // This column holds the icon and the vertical connecting lines.
          SizedBox(
            width: 40, // Fixed width for alignment.
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                // The top part of the connecting line. It's invisible for the first item.
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : AppColors.inactive,
                  ),
                ),
                // The icon for this step, styled to stand out.
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                // The bottom part of the connecting line. Invisible for the last item.
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : AppColors.inactive,
                  ),
                ),
              ],
            ),
          ),
          // Horizontal spacing between the icon column and the text.
          const SizedBox(width: 16),
          // The textual content of the timeline step.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Vertical padding is used here to create consistent spacing
                // between the timeline items.
                SizedBox(height: isFirst ? 0 : 24),
                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontFamily: 'OpenSans',
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryText,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'OpenSans',
                    fontSize: 14,
                    color: AppColors.secondaryText,
                    height: 1.4, // Improves readability for multi-line text.
                  ),
                ),
                // Bottom padding to ensure space between steps.
                SizedBox(height: isLast ? 0 : 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

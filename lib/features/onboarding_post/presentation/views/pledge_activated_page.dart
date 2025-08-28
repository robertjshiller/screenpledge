// Original comments are retained.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/features/dashboard/presentation/views/dashboard_page.dart';

/// A celebratory screen shown immediately after a user successfully activates a pledge.
///
/// Its purpose is to:
/// 1.  **Congratulate** the user on their commitment.
/// 2.  **Confirm** the details of their pledge.
/// 3.  **Clarify** the "Starts at Midnight" rule to manage expectations.
/// 4.  **Reward** them with an instant starting bonus.
class PledgeActivatedPage extends ConsumerWidget {
  /// The pledge amount in cents, passed from the previous screen to be displayed.
  final int pledgeAmountCents;

  const PledgeActivatedPage({
    super.key,
    required this.pledgeAmountCents,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    // Convert cents to a user-friendly dollar string, e.g., 2500 -> "$25".
    final pledgeAmountDollars = (pledgeAmountCents / 100).toStringAsFixed(0);

    return Scaffold(
      body: SafeArea(
        // ✅ FIX: To prevent the "Bottom Overflow" error on smaller screens,
        // the entire page content is wrapped in a SingleChildScrollView.
        // This makes the page vertically scrollable if the content is too tall
        // for the available screen height, ensuring a robust layout.
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // ✅ CHANGED: Removed Spacers to allow the scroll view to manage spacing naturally.
                // Added a SizedBox for consistent top padding.
                const SizedBox(height: 48),
                // A celebratory image of the app's mascot.
                // Ensure you have an appropriate asset at this path.
                Image.asset(
                  'assets/mascot/mascot_pledge_celebration.png', 
                  height: 120,
                ),
                const SizedBox(height: 24),
                // ✅ CHANGED: The main headline has been updated as requested.
                Text(
                  'We Will Hold You Accountable!',
                  style: textTheme.displaySmall,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                // The main body text, congratulating the user.
                Text(
                  "Congratulations! You've taken the most powerful step towards reclaiming your focus.",
                  style: textTheme.bodyLarge,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // The visually distinct bonus section.
                _BonusBox(),

                const SizedBox(height: 24),

                // The "What's Next" section, providing crucial information.
                _InfoPoint(
                  icon: Icons.check_circle_outline,
                  title: 'PLEDGE CONFIRMED',
                  subtitle:
                      "You've successfully set a \$$pledgeAmountDollars pledge.",
                ),
                const SizedBox(height: 16),
                _InfoPoint(
                  icon: Icons.nightlight_round,
                  title: 'STARTS AT MIDNIGHT',
                  subtitle:
                      'Your first official day begins at midnight in your local timezone.',
                ),
                const SizedBox(height: 16),
                _InfoPoint(
                  icon: Icons.star_outline_rounded,
                  title: 'REWARDS MULTIPLIED',
                  subtitle:
                      "You'll now earn 10x Pledge Points for every successful day!",
                ),

                // ✅ CHANGED: Replaced Spacer with SizedBox for consistent spacing in a scroll view.
                const SizedBox(height: 48),

                // The primary action button to proceed to the dashboard.
                PrimaryButton(
                  text: 'See My Dashboard',
                  onPressed: () {
                    // Navigate to the dashboard and remove all previous screens from the stack.
                    // This prevents the user from navigating back to the onboarding flow.
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (context) => const DashboardPage()),
                      (route) => false,
                    );
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// A private helper widget for the visually distinct bonus box.
class _BonusBox extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.buttonFill.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.buttonFill),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.card_giftcard_rounded, color: AppColors.buttonFill),
          const SizedBox(width: 12),
          // ✅ FIX: To prevent the "Right Overflow" error, the Column containing the text
          // is wrapped in an Expanded widget. This tells the Column to take up all
          // available horizontal space in the Row, forcing its Text children to wrap
          // instead of overflowing.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STARTING BONUS UNLOCKED!',
                  style: textTheme.bodyMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  "We've added 50 Pledge Points to your account.",
                  style: textTheme.bodyMedium,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// A private helper widget to display an informational point with an icon.
class _InfoPoint extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _InfoPoint({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: AppColors.secondaryText, size: 28),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: textTheme.bodyMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                subtitle,
                style: textTheme.bodyMedium
                    ?.copyWith(color: AppColors.secondaryText),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
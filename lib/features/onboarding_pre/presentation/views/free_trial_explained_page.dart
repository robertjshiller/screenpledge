// lib/features/onboarding_pre/presentation/views/free_trial_explained_page.dart

// ✅ FIXED: Removed unnecessary import of 'package:flutter/foundation.dart'.
// 'material.dart' already provides the necessary functionality (like debugPrint).
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:screenpledge/features/onboarding_post/presentation/views/account_creation_page.dart';
import 'package:screenpledge/features/onboarding_pre/presentation/viewmodels/subscription_offer_viewmodel.dart';
import '../../../../core/config/theme/app_colors.dart';

/// A page that transparently explains the terms of the free trial to the user.
///
/// This screen is designed to build trust by clearly outlining the trial timeline.
/// It now acts as the final confirmation step before the purchase is initiated.
class FreeTrialExplainedPage extends ConsumerWidget {
  /// A property to receive the plan details from the previous page.
  final Map<String, dynamic> planDetails;

  const FreeTrialExplainedPage({
    super.key,
    required this.planDetails,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewModelState = ref.watch(subscriptionOfferViewModelProvider);

    ref.listen<AsyncValue<void>>(subscriptionOfferViewModelProvider, (previous, next) {
      if (previous is AsyncLoading && next is AsyncData) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const AccountCreationPage(),
          ),
          (Route<dynamic> route) => false,
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: LayoutBuilder(builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Spacer(),
                      Text(
                        'How Your\nFree Trial Works',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.displayLarge,
                      ),
                      const SizedBox(height: 40),
                      _buildTimeline(context),
                      const SizedBox(height: 32),
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
                      const Spacer(),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: viewModelState.isLoading
                            ? null
                            : () {
                                // ✅ FIXED: Provided all required arguments for the constructor.
                                // We pass fake but valid values for the placement and targeting context.
                                ref
                                    .read(subscriptionOfferViewModelProvider.notifier)
                                    .purchase(Package(
                                        planDetails['packageId'],
                                        PackageType.unknown,
                                        StoreProduct('id', 'desc', 'title', 0.0, 'price_string', 'usd'),
                                        PresentedOfferingContext(
                                          planDetails['packageId'], // offeringIdentifier
                                          null, // placementIdentifier (can be null)
                                          null, // targetingContext (can be null)
                                        ),
                                      ));
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.buttonFill,
                          foregroundColor: AppColors.buttonText,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          side: const BorderSide(color: AppColors.buttonStroke, width: 2),
                        ),
                        child: viewModelState.isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Start My 7 Day Free Trial',
                                style: TextStyle(
                                  fontFamily: 'OpenSans',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () {
                          debugPrint('View other plans pressed');
                        },
                        child: Text(
                          'View other plans',
                          style: TextStyle(
                            fontFamily: 'OpenSans',
                            fontSize: 16,
                            color: AppColors.secondaryText.withAlpha(204),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  /// Builds the vertical timeline widget.
  Widget _buildTimeline(BuildContext context) {
    return Column(
      children: [
        _TimelineStep(
          icon: Icons.lock_open_outlined,
          title: 'Today',
          subtitle: 'Explore all features and content right away.',
          isFirst: true,
          iconBackgroundColor: Colors.blue,
        ),
        _TimelineStep(
          icon: Icons.notifications_on_outlined,
          title: 'Day 5',
          subtitle: "We'll send a heads-up that your trial is ending.",
          iconBackgroundColor: Colors.blue,
        ),
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
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 40,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst ? Colors.transparent : AppColors.inactive,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBackgroundColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 24),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast ? Colors.transparent : AppColors.inactive,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
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
                    height: 1.4,
                  ),
                ),
                SizedBox(height: isLast ? 0 : 24),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
// lib/features/onboarding_pre/presentation/views/subscription_offer_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/features/onboarding_pre/presentation/views/free_trial_explained_page.dart';
import 'package:screenpledge/features/onboarding_pre/presentation/viewmodels/subscription_offer_viewmodel.dart';

/// Subscription selection screen.
///
/// This is the VIEW layer in clean architecture.
/// All logic/state is delegated to the ViewModel.
class SubscriptionOfferPage extends ConsumerWidget {
  const SubscriptionOfferPage({super.key});

  // ----- PLAN DEFINITIONS -----
  // This static data defines the options presented to the user.
  static final List<Map<String, dynamic>> plans = [
    {
      'label': 'Monthly',
      'price': '\$2.99/month',
      'freeTrial': true,
      'mostPopular': false,
      'subtext': '',
      'savings': '',
      'packageId': 'monthly', // RevenueCat package identifier
    },
    {
      'label': 'Annual',
      'price': '\$19.99/year',
      'freeTrial': true,
      'mostPopular': true,
      'subtext': 'Just \$1.67/month',
      'savings': '(Save 61%)',
      'packageId': 'annual', // RevenueCat package identifier
    },
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // We only need the notifier to call `selectPlan`.
    final viewModel = ref.watch(subscriptionOfferViewModelProvider.notifier);
    // We watch the state itself to react to loading/error states if they occur.
    final asyncState = ref.watch(subscriptionOfferViewModelProvider);

    // ✅ ADDED: A listener to show an error if something unexpected happens.
    // This is good practice for handling any potential errors from the ViewModel.
    ref.listen<AsyncValue<void>>(subscriptionOfferViewModelProvider, (_, state) {
      if (state is AsyncError) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('An error occurred: ${state.error}')),
        );
      }
    });

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    'Commit to\nA Better You',
                    style: Theme.of(context).textTheme.displayLarge,
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 8),

                const _CheckListRow(
                    label: 'Build life-changing habits', boldWord: 'Build'),
                const _CheckListRow(
                    label: 'Reclaim hours of your free time',
                    boldWord: 'Reclaim'),
                const _CheckListRow(
                    label: 'Focus to earn real rewards', boldWord: 'Focus'),
                const SizedBox(height: 16),

                // Subscription plan cards
                ...List.generate(plans.length, (i) {
                  final plan = plans[i];
                  final isSelected = viewModel.selectedIndex == i;
                  final isFreeTrial = plan['freeTrial'] == true;
                  final isMostPop = plan['mostPopular'] == true;
                  final subtext = plan['subtext'] as String? ?? '';
                  final savings = plan['savings'] as String? ?? '';

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? const Color(0xFFD4FFE9)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                          color: AppColors.buttonStroke, width: 2),
                      boxShadow: [
                        if (isSelected)
                          BoxShadow(
                            color: AppColors.buttonStroke.withOpacity(0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () => viewModel.selectPlan(i),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 18, vertical: 18),
                          child: Row(
                            children: [
                              CustomRadio(
                                selected: isSelected,
                                onTap: () => viewModel.selectPlan(i),
                                outlineColor: AppColors.buttonStroke,
                                fillColor: Colors.white,
                                selectedFillColor: AppColors.buttonFill,
                                checkmarkColor: AppColors.buttonText,
                                size: 22,
                              ),
                              const SizedBox(width: 18),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      plan['label'] as String,
                                      style: Theme.of(context)
                                          .textTheme
                                          .displayLarge!
                                          .copyWith(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w800),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      plan['price'] as String,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge!
                                          .copyWith(fontSize: 16),
                                    ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  if (isFreeTrial || isMostPop)
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (isFreeTrial)
                                          _Badge(
                                              label: 'Free Trial',
                                              background:
                                                  AppColors.buttonFill),
                                        if (isFreeTrial && isMostPop)
                                          const SizedBox(width: 6),
                                        if (isMostPop)
                                          _Badge(
                                              label: 'Most Popular',
                                              background: const Color.fromARGB(
                                                  255, 255, 176, 85)),
                                      ],
                                    ),
                                  if (subtext.isNotEmpty ||
                                      savings.isNotEmpty) ...[
                                    if (subtext.isNotEmpty)
                                      Padding(
                                        padding:
                                            const EdgeInsets.only(top: 4),
                                        child: Text(
                                          subtext,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall!
                                              .copyWith(
                                                  color: AppColors
                                                      .secondaryText,
                                                  fontWeight: FontWeight.w600),
                                        ),
                                      ),
                                    if (savings.isNotEmpty)
                                      Text(
                                        savings,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall!
                                            .copyWith(
                                                color:
                                                    AppColors.buttonStroke,
                                                fontStyle: FontStyle.italic),
                                      ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 18),
                Center(
                  child: Text(
                    "You won't be charged today.\nFree trial details on the next screen.",
                    style: Theme.of(context).textTheme.bodyLarge!.copyWith(
                        color: AppColors.secondaryText),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 18),
                Center(
                  child: SizedBox(
                    width: 320,
                    child: PrimaryButton(
                      // The button is only disabled if the ViewModel is in a loading state,
                      // which shouldn't happen on this screen anymore, but is good practice.
                      text: asyncState.isLoading ? 'Processing...' : 'Continue',
                      onPressed: asyncState.isLoading
                          ? null
                          : () {
                              // ✅ CHANGED: This button no longer calls purchase().
                              // Its only job is to navigate to the explanation page,
                              // passing along the data for the user's chosen plan.
                              final selectedPlan = plans[viewModel.selectedIndex];
                              
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FreeTrialExplainedPage(
                                    // ✅ PASSING DATA: We send the selected plan's info.
                                    planDetails: selectedPlan,
                                  ),
                                ),
                              );
                            },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/* ===================================================================
   SMALL UI COMPONENTS (VIEW-ONLY)
   =================================================================== */

class _Badge extends StatelessWidget {
  final String label;
  final Color background;
  const _Badge({required this.label, required this.background});

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(
            color: AppColors.buttonStroke,
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: Theme.of(context).textTheme.bodySmall!.copyWith(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
        ),
      );
}

class _CheckListRow extends StatelessWidget {
  final String label, boldWord;
  const _CheckListRow({required this.label, required this.boldWord});

  @override
  Widget build(BuildContext context) {
    final parts = label.split(' ');
    final boldIdx = parts
        .indexWhere((w) => w.toLowerCase() == boldWord.toLowerCase());

    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Row(
        children: [
          Icon(Icons.check, size: 22, color: AppColors.buttonStroke),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              children: [
                for (int i = 0; i < parts.length; i++) ...[
                  TextSpan(
                    text: parts[i],
                    style: i == boldIdx
                        ? Theme.of(context)
                            .textTheme
                            .bodyLarge!
                            .copyWith(fontWeight: FontWeight.bold)
                        : Theme.of(context).textTheme.bodyLarge,
                  ),
                  if (i < parts.length - 1) const TextSpan(text: ' '),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CustomRadio extends StatelessWidget {
  final bool selected;
  final VoidCallback onTap;
  final double size;
  final Color outlineColor, fillColor, selectedFillColor, checkmarkColor;

  const CustomRadio({
    super.key,
    required this.selected,
    required this.onTap,
    required this.outlineColor,
    required this.fillColor,
    required this.selectedFillColor,
    required this.checkmarkColor,
    this.size = 24,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: selected ? selectedFillColor : fillColor,
            shape: BoxShape.circle,
            border: Border.all(color: outlineColor, width: 2.5),
          ),
          child: Center(
            child: selected
                ? Icon(Icons.check, size: size * 0.65, color: checkmarkColor)
                : null,
          ),
        ),
      );
}
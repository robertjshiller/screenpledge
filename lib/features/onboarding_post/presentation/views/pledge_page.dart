// Original comments are retained.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/core/di/profile_providers.dart';
import 'package:screenpledge/features/dashboard/presentation/views/dashboard_page.dart';
import 'package:screenpledge/features/onboarding_post/presentation/viewmodels/pledge_viewmodel.dart';
import 'package:screenpledge/features/onboarding_post/presentation/views/goal_setting_page.dart';
import 'package:screenpledge/features/onboarding_post/presentation/widgets/confirmation_dialog.dart';
// ✅ NEW: Import for our new celebratory "Pledge Activated" page.
import 'package:screenpledge/features/onboarding_post/presentation/views/pledge_activated_page.dart';

class PledgePage extends ConsumerStatefulWidget {
  const PledgePage({super.key});

  @override
  ConsumerState<PledgePage> createState() => _PledgePageState();
}

class _PledgePageState extends ConsumerState<PledgePage> {
  // Local UI state for the slider. The checkbox state is now managed by the dialog.
  double _currentPledgeValue = 25.0;

  // The method to show our custom dialog remains unchanged.
  void _showConfirmationDialog() {
    // `showDialog` is a built-in Flutter function that displays a modal.
    showDialog(
      context: context,
      // `barrierDismissible: false` prevents the user from closing the dialog
      // by tapping outside of it, forcing them to make a choice.
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // We use a Consumer here so the dialog can rebuild if the ViewModel state changes.
        return Consumer(
          builder: (context, ref, child) {
            // Watch the ViewModel to pass the loading state to the dialog.
            final viewModelState = ref.watch(pledgeViewModelProvider);
            return ConfirmationDialog(
              pledgeValue: _currentPledgeValue,
              isLoading: viewModelState.isLoading,
              onConfirm: () {
                // The onConfirm callback triggers the final activation logic.
                final amountInCents = (_currentPledgeValue * 100).toInt();
                // This call remains the same. The listener below will handle the navigation on success.
                ref.read(pledgeViewModelProvider.notifier).savePaymentMethodAndActivatePledge(amountCents: amountInCents);
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final viewModelState = ref.watch(pledgeViewModelProvider);
    final profileState = ref.watch(myProfileProvider);

    // ✅ CHANGED: The listener's logic has been updated.
    // It now ONLY handles the navigation for a SUCCESSFUL PLEDGE ACTIVATION.
    // The navigation for skipping a pledge is now handled directly in the "Not Now" button.
    ref.listen<AsyncValue<void>>(pledgeViewModelProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          // Error handling remains the same. If anything fails, close the dialog and show an error.
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('An error occurred: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        data: (_) {
          // This success case is now specifically for when a pledge is activated.
          if (previous?.isLoading == true) {
            // Get the final pledge amount from the local state of this widget.
            final amountInCents = (_currentPledgeValue * 100).toInt();

            // Navigate to the new celebratory page, passing the pledge amount.
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(
                builder: (context) => PledgeActivatedPage(
                  pledgeAmountCents: amountInCents,
                ),
              ),
              (route) => false, // This removes all previous routes from the stack.
            );
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Make Your Pledge',
          style: textTheme.headlineMedium,
        ),
      ),
      body: SafeArea(
        // The "Smart Scrolling" layout remains the same.
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // The layout remains the same.
                        const Spacer(flex: 2),
                        Text(
                          'This is the single most effective step to guarantee your success.',
                          style: textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Image.asset(
                          'assets/mascot/mascot_pledge_coin.png',
                          height: 100,
                        ),
                        const SizedBox(height: 16),
                        _PledgeOptionBox(
                          child: Text(
                            'Users who set a meaningful pledge are 5 times more likely to meet their goals.',
                            style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _PledgeOptionBox(
                          child: Text(
                            'Earn rewards 10x faster by setting a pledge!',
                            style: textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // The "Goal Review" component remains the same.
                        profileState.when(
                          loading: () => const SizedBox(height: 60, child: Center(child: CircularProgressIndicator())),
                          error: (err, st) => Text('Could not load goal: $err'),
                          data: (profile) {
                            if (profile?.onboardingDraftGoal == null) {
                              return const _GoalReviewBox(
                                goalSummary: 'Goal details not found.',
                                timeLimitSummary: 'Please go back.',
                              );
                            }
                            final draftGoal = profile!.onboardingDraftGoal!;
                            final isTotalTime = draftGoal['goalType'] == 'total_time';
                            final timeLimit = Duration(seconds: draftGoal['timeLimit']);
                            final hours = timeLimit.inHours;
                            final minutes = timeLimit.inMinutes.remainder(60);

                            return _GoalReviewBox(
                              goalSummary: isTotalTime ? 'Total Screen Time' : 'Custom App Group',
                              timeLimitSummary: '${hours}h ${minutes}m Daily Limit',
                            );
                          },
                        ),

                        const Spacer(flex: 3),
                        Text(
                          'Choose An Amount',
                          style: textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              child: Slider(
                                value: _currentPledgeValue,
                                min: 5.0,
                                max: 100.0,
                                activeColor: AppColors.buttonFill,
                                inactiveColor: AppColors.inactive,
                                onChanged: (newValue) {
                                  setState(() {
                                    _currentPledgeValue = newValue;
                                  });
                                },
                              ),
                            ),
                            Text(
                              '\$${_currentPledgeValue.toStringAsFixed(0)}',
                              style: textTheme.headlineSmall,
                            ),
                          ],
                        ),

                        const Spacer(flex: 3),
                        PrimaryButton(
                          text: 'Activate My Pledge',
                          // The button's job is still to open the confirmation dialog.
                          onPressed: viewModelState.isLoading ? null : _showConfirmationDialog,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          // ✅ CHANGED: The logic for the "Not Now" button is now self-contained.
                          // It no longer relies on the listener for navigation.
                          onPressed: viewModelState.isLoading
                              ? null
                              : () async { // Make the callback async
                                  // Await the completion of the skipPledge action.
                                  await ref.read(pledgeViewModelProvider.notifier).skipPledge();
                                  
                                  // After it completes, check the view model's state.
                                  // If there is NO error, it means it was successful, so we can navigate.
                                  // This prevents navigating away if the skip action fails for some reason.
                                  // The `mounted` check is a good practice to ensure the widget is still in the tree.
                                  if (ref.read(pledgeViewModelProvider).hasError == false && mounted) {
                                    Navigator.of(context).pushAndRemoveUntil(
                                      MaterialPageRoute(builder: (context) => const DashboardPage()),
                                      (route) => false,
                                    );
                                  }
                                },
                          child: Text(
                            'Not Now',
                            style: TextStyle(color: AppColors.inactive),
                          ),
                        ),
                        const Spacer(flex: 1),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// The _GoalReviewBox widget remains the same.
class _GoalReviewBox extends StatelessWidget {
  final String goalSummary;
  final String timeLimitSummary;

  const _GoalReviewBox({
    required this.goalSummary,
    required this.timeLimitSummary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.inactive, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'YOUR GOAL',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.secondaryText,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                Text(
                  goalSummary,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                Text(
                  timeLimitSummary,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.secondaryText,
                      ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const GoalSettingPage()),
              );
            },
            child: Text(
              'Edit',
              style: TextStyle(
                color: AppColors.secondaryText,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// The _PledgeOptionBox widget remains the same.
class _PledgeOptionBox extends StatelessWidget {
  final Widget child;
  const _PledgeOptionBox({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.0),
        border: Border.all(
          color: AppColors.buttonStroke,
          width: 2.0,
        ),
      ),
      child: Center(child: child),
    );
  }
}
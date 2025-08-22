// lib/features/onboarding_post/presentation/views/pledge_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/core/di/profile_providers.dart';
import 'package:screenpledge/features/dashboard/presentation/views/dashboard_page.dart';
import 'package:screenpledge/features/onboarding_post/presentation/viewmodels/pledge_viewmodel.dart';
import 'package:screenpledge/features/onboarding_post/presentation/views/goal_setting_page.dart';
// ✅ ADDED: Import for our new custom dialog widget.
import 'package:screenpledge/features/onboarding_post/presentation/widgets/confirmation_dialog.dart';

class PledgePage extends ConsumerStatefulWidget {
  const PledgePage({super.key});

  @override
  ConsumerState<PledgePage> createState() => _PledgePageState();
}

class _PledgePageState extends ConsumerState<PledgePage> {
  // Local UI state for the slider. The checkbox state is now managed by the dialog.
  double _currentPledgeValue = 25.0;

  // ✅ ADDED: A method to show our new custom dialog.
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
                ref.read(pledgeViewModelProvider.notifier).activatePledge(amountCents: amountInCents);
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

    // The listener remains the same. It will navigate after the ViewModel
    // successfully completes the `activatePledge` or `skipPledge` action.
    ref.listen<AsyncValue<void>>(pledgeViewModelProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          // If there's an error, close the dialog first, then show the error.
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
          if (previous?.isLoading == true) {
            // On success, navigate to the dashboard.
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const DashboardPage()),
              (route) => false,
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
        // ✅ CHANGED: Re-introduced the "Smart Scrolling" layout to guarantee
        // no overflows on any screen size with the new content order.
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
                        // ✅ CHANGED: The layout now follows your proposed flow.
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
                        
                        // The "Goal Review" component now comes after the motivation.
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

                        // ✅ REMOVED: The entire "Confirm Your Understanding" Column
                        // with the CheckboxListTiles has been removed from this page.
                        // Its logic now lives inside the ConfirmationDialog.

                        const Spacer(flex: 3),
                        PrimaryButton(
                          text: 'Activate My Pledge',
                          // ✅ CHANGED: The button's job is now to open the confirmation dialog.
                          // We disable it if the ViewModel is loading to prevent opening the dialog
                          // while another operation is in progress.
                          onPressed: viewModelState.isLoading ? null : _showConfirmationDialog,
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: viewModelState.isLoading
                              ? null
                              : () {
                                  ref.read(pledgeViewModelProvider.notifier).skipPledge();
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
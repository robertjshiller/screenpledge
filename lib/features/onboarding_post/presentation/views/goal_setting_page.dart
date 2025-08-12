import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // ✅ ADDED: Riverpod for state management.
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/core/domain/entities/installed_app.dart';
import 'package:screenpledge/features/onboarding_post/presentation/viewmodels/goal_setting_viewmodel.dart'; // ✅ ADDED: The ViewModel for this page.
import 'package:screenpledge/features/onboarding_post/presentation/views/app_selection_page.dart';
import 'package:screenpledge/features/onboarding_post/presentation/views/pledge_page.dart';

// ✅ CHANGED: Converted to a ConsumerStatefulWidget to use Riverpod for state management.
class GoalSettingPage extends ConsumerStatefulWidget {
  const GoalSettingPage({super.key});

  @override
  ConsumerState<GoalSettingPage> createState() => _GoalSettingPageState();
}

class _GoalSettingPageState extends ConsumerState<GoalSettingPage> {
  // These remain as local UI state, managed by the widget itself.
  bool _isTotalTimeSelected = true;
  Duration _selectedTime = const Duration(hours: 3, minutes: 15);
  Set<InstalledApp> _exemptApps = {};
  Set<InstalledApp> _trackedApps = {};

  /* ───────────────────────── TIME-PICKER DIALOG ───────────────────────── */

  // This method remains unchanged.
  void _showTimePicker() {
    Duration tempDuration = _selectedTime;

    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('Set Your Daily Limit'),
          content: SizedBox(
            width: 320,
            height: 216,
            child: CupertinoTimerPicker(
              mode: CupertinoTimerPickerMode.hm,
              initialTimerDuration: _selectedTime,
              onTimerDurationChanged: (newDuration) {
                tempDuration = newDuration;
              },
            ),
          ),
          actions: <CupertinoDialogAction>[
            CupertinoDialogAction(
              child: Text(
                'Cancel',
                style: TextStyle(color: AppColors.primaryText),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(
                'OK',
                style: TextStyle(color: AppColors.primaryText),
              ),
              onPressed: () {
                setState(() {
                  _selectedTime = tempDuration;
                });
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  // This method remains unchanged.
  Future<void> _selectApps({
    required String title,
    required Set<InstalledApp> currentSelection,
    required void Function(Set<InstalledApp>) onUpdate,
  }) async {
    final result = await Navigator.of(context).push<Set<InstalledApp>>(
      MaterialPageRoute(
        builder: (context) => AppSelectionPage(
          title: title,
          initialSelection: currentSelection,
        ),
        fullscreenDialog: true,
      ),
    );
    if (result != null) {
      setState(() {
        onUpdate(result);
      });
    }
  }

  /* ────────────────────────────── UI BUILD ────────────────────────────── */

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    // ✅ ADDED: Watch the ViewModel's state for loading/error status.
    final viewModelState = ref.watch(goalSettingViewModelProvider);

    // ✅ ADDED: A listener to react to state changes (e.g., success or error).
    ref.listen<AsyncValue<void>>(goalSettingViewModelProvider, (previous, next) {
      next.whenOrNull(
        error: (error, stackTrace) {
          // On error, show a SnackBar.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving goal: ${error.toString()}'),
              backgroundColor: Colors.red,
            ),
          );
        },
        data: (_) {
          // On success (when state goes from loading back to data), navigate.
          // The check `previous?.isLoading == true` ensures this only triggers
          // after a successful save operation.
          if (previous?.isLoading == true) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const PledgePage()),
            );
          }
        },
      );
    });

    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        // This pattern allows the use of Spacers for proportional layout
        // while ensuring the content can scroll if it overflows, for example
        // when the keyboard is displayed on a small screen.
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: IntrinsicHeight(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Spacer(flex: 1), // Replaced SizedBox(height: 16)
                        Text(
                          'Set Your Goal',
                          style: textTheme.displayLarge?.copyWith(fontSize: 28),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Choose what to track and set your daily screen time limit',
                          style: textTheme.bodyLarge,
                          textAlign: TextAlign.center,
                        ),
                        const Spacer(flex: 2), // Replaced SizedBox(height: 32)

                        // ----- Goal-type cards -----
                        _GoalTypeCard(
                          title: 'Total Screen Time',
                          description:
                              'Hold yourself accountable for your entire daily phone usage.',
                          isSelected: _isTotalTimeSelected,
                          onTap: () => setState(() => _isTotalTimeSelected = true),
                          child: _AppSelectionButton(
                            label: 'Exempt Apps',
                            count: _exemptApps.length,
                            onPressed: () => _selectApps(
                              title: 'Select Exempt Apps',
                              currentSelection: _exemptApps,
                              onUpdate: (updatedApps) => _exemptApps = updatedApps,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _GoalTypeCard(
                          title: 'Custom App Group',
                          description: 'Target only your biggest distractions.',
                          isSelected: !_isTotalTimeSelected,
                          onTap: () => setState(() => _isTotalTimeSelected = false),
                          child: _AppSelectionButton(
                            label: 'Select Apps & Categories',
                            count: _trackedApps.length,
                            onPressed: () => _selectApps(
                              title: 'Select Apps to Track',
                              currentSelection: _trackedApps,
                              onUpdate: (updatedApps) => _trackedApps = updatedApps,
                            ),
                          ),
                        ),
                        const Spacer(flex: 3), // Replaced SizedBox(height: 48)

                        // ----- Daily limit display -----
                        Text(
                          'Your Daily Limit',
                          style: textTheme.headlineMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        _TimeDisplay(time: _selectedTime, onTap: _showTimePicker),
                        const Spacer(flex: 3), // Replaced SizedBox(height: 48)

                        // ----- Save button -----
                        PrimaryButton(
                          // ✅ CHANGED: Button text and onPressed logic now driven by the ViewModel.
                          text: viewModelState.isLoading ? 'Saving...' : 'Save Goal',
                          onPressed: viewModelState.isLoading
                              ? null // Disable button while loading.
                              : () {
                                  // Call the ViewModel method, passing in the current UI state.
                                  ref
                                      .read(goalSettingViewModelProvider.notifier)
                                      .saveGoal(
                                        isTotalTime: _isTotalTimeSelected,
                                        timeLimit: _selectedTime,
                                        exemptApps: _exemptApps,
                                        trackedApps: _trackedApps,
                                      );
                                },
                        ),
                        const Spacer(flex: 1), // Replaced SizedBox(height: 24)
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

/* ────────────────────────── GOAL-TYPE CARD ────────────────────────── */
// This widget's implementation remains unchanged.
class _GoalTypeCard extends StatelessWidget {
  final String title;
  final String description;
  final bool isSelected;
  final VoidCallback onTap;
  final Widget? child;

  const _GoalTypeCard({
    required this.title,
    required this.description,
    required this.isSelected,
    required this.onTap,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.buttonFill.withAlpha(25) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.buttonStroke : AppColors.inactive,
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isSelected ? AppColors.buttonStroke : AppColors.inactive,
                  size: 28,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontSize: 18),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (child != null) child!,
          ],
        ),
      ),
    );
  }
}

/* ─────────────────── APP SELECTION BUTTON ─────────────────── */
// This widget's implementation remains unchanged.
class _AppSelectionButton extends StatelessWidget {
  final String label;
  final int count;
  final VoidCallback onPressed;

  const _AppSelectionButton({
    required this.label,
    required this.count,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Divider(color: AppColors.inactive.withAlpha(100)),
        const SizedBox(height: 8),
        TextButton(
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: onPressed,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: AppColors.primaryText,
                      fontWeight: FontWeight.w600,
                    ),
              ),
              Row(
                children: [
                  if (count > 0)
                    Text(
                      '$count selected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.inactive,
                          ),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppColors.inactive,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/* ────────────────────────── TIME DISPLAY ────────────────────────── */
// This widget's implementation remains unchanged.
class _TimeDisplay extends StatelessWidget {
  final Duration time;
  final VoidCallback onTap;

  const _TimeDisplay({required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final hours = time.inHours;
    final minutes = time.inMinutes.remainder(60);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.inactive, width: 1.5),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              '${hours}h ${minutes}m',
              style: Theme.of(context).textTheme.displayLarge,
              textAlign: TextAlign.center,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: CupertinoButton(
                padding: EdgeInsets.zero,
                onPressed: onTap,
                child: Icon(
                  Icons.edit,
                  color: AppColors.primaryText,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
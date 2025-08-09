import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/features/onboarding_post/presentation/views/pledge_page.dart'; // Import PledgePage

// This is the main widget for the Goal Setting screen.
class GoalSettingPage extends StatefulWidget {
  const GoalSettingPage({super.key});

  @override
  State<GoalSettingPage> createState() => _GoalSettingPageState();
}

class _GoalSettingPageState extends State<GoalSettingPage> {
  bool _isTotalTimeSelected = true;
  Duration _selectedTime = const Duration(hours: 3, minutes: 15);

  /* ───────────────────────── TIME-PICKER DIALOG ───────────────────────── */

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
                style: TextStyle(color: AppColors.primaryText), // Set text color
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              isDefaultAction: true,
              child: Text(
                'OK',
                style: TextStyle(color: AppColors.primaryText), // Set text color
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

  /* ────────────────────────────── UI BUILD ────────────────────────────── */

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
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
              const SizedBox(height: 32),

              // ----- Goal-type cards -----
              _GoalTypeCard(
                title: 'Total Screen Time',
                description: 'Hold yourself accountable for your entire daily phone usage.',
                isSelected: _isTotalTimeSelected,
                onTap: () => setState(() => _isTotalTimeSelected = true),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Divider(color: AppColors.inactive.withAlpha(100)),
                    const SizedBox(height: 8),
                    Text(
                      'Exempt Apps',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _GoalTypeCard(
                title: 'Custom App Group',
                description: 'Target only your biggest distractions.',
                isSelected: !_isTotalTimeSelected,
                onTap: () => setState(() => _isTotalTimeSelected = false),
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Divider(color: AppColors.inactive.withAlpha(100)),
                    const SizedBox(height: 8),
                    Text(
                      'Select Apps & Categories',
                      style: textTheme.labelLarge?.copyWith(
                        color: AppColors.primaryText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),

              // ----- Daily limit display -----
              Text(
                'Your Daily Limit',
                style: textTheme.headlineMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              _TimeDisplay(time: _selectedTime, onTap: _showTimePicker),
              const SizedBox(height: 48),

              // ----- Save button -----
              PrimaryButton(
                text: 'Save Goal',
                onPressed: () {
                  // Navigate to the PledgePage using Navigator.push
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PledgePage()),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/* ────────────────────────── GOAL-TYPE CARD ────────────────────────── */
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

/* ────────────────────────── TIME DISPLAY ────────────────────────── */
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
        child: Stack( // Changed to Stack
          alignment: Alignment.center, // Center the content of the Stack
          children: [
            Text(
              '${hours}h ${minutes}m',
              style: Theme.of(context).textTheme.displayLarge, // Using displayLarge
              textAlign: TextAlign.center, // Ensure text is centered within its own space
            ),
            Align(
              alignment: Alignment.centerRight, // Position the icon to the right
              child: CupertinoButton(
                padding: EdgeInsets.zero, // Remove default padding
                onPressed: onTap,
                child: Icon(
                  Icons.edit,
                  color: AppColors.primaryText, // Set icon color
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

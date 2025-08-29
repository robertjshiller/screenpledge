// lib/features/dashboard/presentation/widgets/no_goal_view.dart

import 'package:flutter/material.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';

/// The view for SCENARIO 3: The user has no active goal.
class NoGoalView extends StatelessWidget {
  const NoGoalView({super.key});

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Mascot visual
            Image.asset('assets/mascot/mascot_thinking.png', height: 120), // Placeholder
            const SizedBox(height: 24),
            // Main headline
            Text("Ready to build a new habit?", style: textTheme.displaySmall, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            // Body text
            Text(
              'Setting a goal is the first step to reclaiming your focus. You can still track your daily usage below.',
              style: textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            // Call to action
            PrimaryButton(
              text: 'Set a New Goal',
              onPressed: () {
                // TODO: Navigate to the goal setting page.
              },
            ),
          ],
        ),
      ),
    );
  }
}
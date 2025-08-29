// lib/features/dashboard/presentation/widgets/active_goal_view.dart

import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:screenpledge/features/dashboard/presentation/widgets/app_usage_list.dart';
import 'package:screenpledge/features/dashboard/presentation/widgets/progress_ring.dart';
import 'package:screenpledge/features/dashboard/presentation/widgets/weekly_bar_chart.dart';

/// The main dashboard view when a user has an active and effective goal.
class ActiveGoalView extends StatelessWidget {
  final DashboardState dashboardState;
  const ActiveGoalView({super.key, required this.dashboardState});

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  Color _getProgressColor(double progress) {
    // ✅ CHANGED: The logic for the color is now inverted.
    // The color should get more urgent as the progress ring gets EMPTY.
    // A low progress value (e.g., 0.1 or 10% time left) is now the trigger for red.
    if (progress <= 0.1) return Colors.red.shade400;
    if (progress <= 0.3) return Colors.orange.shade400;
    return AppColors.buttonFill;
  }

  @override
  Widget build(BuildContext context) {
    final goal = dashboardState.activeGoal!;
    final profile = dashboardState.profile!;
    final timeSpent = dashboardState.timeSpentToday;
    final timeLimit = goal.timeLimit;
    final timeRemaining = timeLimit > timeSpent ? timeLimit - timeSpent : Duration.zero;
    
    // ✅ THE FIX: The progress calculation is now based on the percentage of time REMAINING.
    // This will make the ring start full and deplete as time is used.
    // For example, if 30 mins of a 60 min limit are used, timeRemaining is 30 mins,
    // and the progress will be 30 / 60 = 0.5 (half full).
    final progress = (timeLimit.inSeconds > 0)
        ? timeRemaining.inSeconds / timeLimit.inSeconds
        : 0.0;

    // The color is now correctly calculated based on the remaining time progress.
    final color = _getProgressColor(progress);

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(), // Ensures pull-to-refresh works
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Display the "Accountability Shield" if a pledge is active.
            if (profile.pledgeAmountCents > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.shield_outlined, color: AppColors.secondaryText),
                  const SizedBox(width: 8),
                  Text(
                    'Your \$${(profile.pledgeAmountCents / 100).toStringAsFixed(0)} Accountability Shield is active.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: AppColors.secondaryText),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],

            // The main progress ring.
            SizedBox(
              width: 250,
              height: 250,
              child: ProgressRing(
                // The progress value is now correct.
                progress: progress.clamp(0.0, 1.0),
                progressColor: color,
                strokeWidth: 20,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(_formatDuration(timeRemaining), style: Theme.of(context).textTheme.displayLarge),
                    const Text('remaining', style: TextStyle(color: AppColors.secondaryText)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 48),
            Text("Today's Limit: ${_formatDuration(timeLimit)}", style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('Time Used: ${_formatDuration(timeSpent)}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 48),
            
            // The weekly bar chart.
            // WeeklyBarChart(
            //   dailyData: dashboardState.weeklyResults,
            //   timeSpentToday: timeSpent,
            //   timeLimitToday: timeLimit,
            // ),
            const SizedBox(height: 24),
            
            // The detailed app usage list.
            AppUsageList(usageStats: dashboardState.dailyUsageBreakdown),
          ],
        ),
      ),
    );
  }
}
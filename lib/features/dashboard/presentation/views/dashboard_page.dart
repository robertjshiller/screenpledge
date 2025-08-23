// lib/features/dashboard/presentation/views/dashboard_page.dart

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/common_widgets/bottom_nav_bar.dart';
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:screenpledge/features/dashboard/presentation/widgets/progress_ring.dart';
import 'package:screenpledge/features/dashboard/presentation/widgets/weekly_bar_chart.dart';
import 'package:screenpledge/core/common_widgets/primary_button.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardStateAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        // ✅ The AppBar now shows the user's Pledge Points (PP).
        // In a real app, this would come from the user's profile.
        title: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Icon(Icons.star_border, color: AppColors.primaryText),
            SizedBox(width: 8),
            Text('0 PP'),
          ],
        ),
        // We remove the back button from the dashboard.
        automaticallyImplyLeading: false,
      ),
      body: dashboardStateAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('An error occurred while loading your dashboard: $error'),
          ),
        ),
        data: (dashboardState) {
          // ✅ THIS IS THE CORE LOGIC CHANGE.
          // We check if a goal exists and if it's effective right now.
          if (dashboardState.activeGoal != null && dashboardState.isGoalEffectiveNow) {
            // If the goal is active and effective, show the progress dashboard.
            return _ActiveGoalDashboard(dashboardState: dashboardState);
          } else if (dashboardState.activeGoal != null && !dashboardState.isGoalEffectiveNow) {
            // If a goal exists but is not yet effective, show the "Goal Pending" UI.
            return _GoalPendingDashboard(goal: dashboardState.activeGoal!);
          } else {
            // If no goal exists at all, show a message prompting the user to create one.
            return const Center(
              child: Text(
                'No active goal found.\nSet a new goal to get started!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: AppColors.secondaryText),
              ),
            );
          }
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) { /* TODO: Implement navigation logic */ },
      ),
    );
  }
}

/// A private widget to display the dashboard when a goal is active and effective.
class _ActiveGoalDashboard extends StatelessWidget {
  final DashboardState dashboardState;
  const _ActiveGoalDashboard({required this.dashboardState});

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.9) return Colors.red.shade400;
    if (progress >= 0.7) return Colors.orange.shade400;
    return AppColors.buttonFill;
  }

  @override
  Widget build(BuildContext context) {
    final goal = dashboardState.activeGoal!;
    final timeSpent = dashboardState.timeSpentToday;
    final timeLimit = goal.timeLimit;
    final timeRemaining = timeLimit > timeSpent ? timeLimit - timeSpent : Duration.zero;
    final ringProgress = (timeLimit.inSeconds > 0) ? timeRemaining.inSeconds / timeLimit.inSeconds : 0.0;
    final colorProgress = dashboardState.progressPercentage;
    final color = _getProgressColor(colorProgress);

    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 250,
                height: 250,
                child: ProgressRing(
                  progress: ringProgress.clamp(0.0, 1.0),
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
              WeeklyBarChart(
                dailyData: dashboardState.weeklyResults,
                historicalUsage: dashboardState.historicalUsage,
                timeSpentToday: timeSpent,
                timeLimitToday: timeLimit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ✅ ADDED: A new private widget for the "Goal Pending" state.
/// This UI is shown to a new user after they set their first goal, before it
/// becomes effective at midnight.
class _GoalPendingDashboard extends StatefulWidget {
  final Goal goal;
  const _GoalPendingDashboard({required this.goal});

  @override
  State<_GoalPendingDashboard> createState() => _GoalPendingDashboardState();
}

class _GoalPendingDashboardState extends State<_GoalPendingDashboard> {
  Timer? _timer;
  Duration _timeUntilStart = Duration.zero;

  @override
  void initState() {
    super.initState();
    _calculateTimeUntilStart();
    // Set up a timer to update the countdown every second.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _calculateTimeUntilStart();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _calculateTimeUntilStart() {
    final now = DateTime.now();
    // The goal starts at midnight of the next day.
    final nextDay = DateTime(now.year, now.month, now.day + 1);
    final difference = nextDay.difference(now);
    if (mounted) {
      setState(() {
        _timeUntilStart = difference;
      });
    }
  }

  String _formatCountdown(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    return '${hours}h ${minutes}m';
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) return '${hours}h ${minutes}m';
    return '${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(flex: 2),
          Text('Congratulations!', style: textTheme.displayLarge, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Image.asset('assets/mascot/mascot_celebration.png', height: 150),
          const SizedBox(height: 24),
          Text('Your First Challenge Is Set!', style: textTheme.headlineMedium, textAlign: TextAlign.center),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppColors.inactive.withAlpha(100)),
            ),
            child: Column(
              children: [
                _InfoRow(
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.buttonStroke,
                  text: 'Your goal to limit your screen time to ${_formatDuration(widget.goal.timeLimit)} will begin at midnight.',
                ),
                const Divider(height: 24),
                _InfoRow(
                  icon: Icons.hourglass_empty,
                  iconColor: AppColors.secondaryText,
                  text: 'Starts in: ${_formatCountdown(_timeUntilStart)}',
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
            decoration: BoxDecoration(
              color: AppColors.buttonFill.withAlpha(50),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: const Text(
              '💡 Start being mindful about your screen time today to increase your chances of success starting tomorrow!',
              textAlign: TextAlign.center,
              style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.secondaryText),
            ),
          ),
          const Spacer(flex: 3),
          Text(
            'To learn more about our system, click the button below.',
            style: textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          PrimaryButton(text: 'Learn More', onPressed: () {}),
          const Spacer(flex: 1),
        ],
      ),
    );
  }
}

// A helper widget for the info box in the pending dashboard.
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String text;
  const _InfoRow({required this.icon, required this.iconColor, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: iconColor, size: 24),
        const SizedBox(width: 12),
        Expanded(child: Text(text, style: Theme.of(context).textTheme.bodyMedium)),
      ],
    );
  }
}
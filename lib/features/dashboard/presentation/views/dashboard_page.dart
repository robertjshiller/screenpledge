// lib/features/dashboard/presentation/views/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/common_widgets/bottom_nav_bar.dart';
import 'package:screenpledge/features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:screenpledge/features/dashboard/presentation/widgets/progress_ring.dart';
import 'package:screenpledge/features/dashboard/presentation/widgets/weekly_bar_chart.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  /// A helper function to format a Duration into a readable string like "1h 23m" or "45m".
  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  /// A helper to determine the color of the ring based on progress.
  Color _getProgressColor(double progress) {
    if (progress >= 0.9) return Colors.red.shade400;
    if (progress >= 0.7) return Colors.orange.shade400;
    return AppColors.buttonFill;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardStateAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
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
          if (dashboardState.activeGoal == null) {
            return const Center(
              child: Text(
                'No active goal found.\nSet a new goal to get started!',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, color: AppColors.secondaryText),
              ),
            );
          }

          final goal = dashboardState.activeGoal!;
          final timeSpent = dashboardState.timeSpentToday;
          final timeLimit = goal.timeLimit;

          final timeRemaining = timeLimit > timeSpent ? timeLimit - timeSpent : Duration.zero;
          final ringProgress = (timeLimit.inSeconds > 0)
              ? timeRemaining.inSeconds / timeLimit.inSeconds
              : 0.0;
          
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
                            Text(
                              _formatDuration(timeRemaining),
                              style: Theme.of(context).textTheme.displayLarge,
                            ),
                            const Text(
                              'remaining',
                              style: TextStyle(color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 48),
                    Text(
                      "Today's Limit: ${_formatDuration(timeLimit)}",
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Time Used: ${_formatDuration(timeSpent)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 48),
                    
                    // ✅ CHANGED: We now pass the live, real-time data for "today"
                    // directly to the WeeklyBarChart widget.
                    WeeklyBarChart(
                      dailyData: dashboardState.weeklyResults,
                      timeSpentToday: timeSpent,
                      timeLimitToday: timeLimit,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) { /* TODO: Implement navigation logic */ },
      ),
    );
  }
}
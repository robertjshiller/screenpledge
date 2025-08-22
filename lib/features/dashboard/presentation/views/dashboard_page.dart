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

  /// A helper function to format the duration into a readable string.
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
    if (progress >= 0.75) return Colors.red.shade400;
    if (progress >= 0.50) return Colors.orange.shade400;
    return AppColors.primaryAccent;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        centerTitle: true,
      ),
      body: dashboardState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Text('An error occurred: $error'),
        ),
        data: (activeGoal) {
          if (activeGoal == null) {
            return const Center(
              child: Text(
                'No active goal found.\nSet a new goal to get started!',
                textAlign: TextAlign.center,
              ),
            );
          }

          // Progress for the COLOR is based on time USED.
          final timeUsedProgress = activeGoal.progressPercentage;
          final color = _getProgressColor(timeUsedProgress);

          // Progress for the RING is based on time REMAINING.
          final timeLimit = activeGoal.timeLimit;
          final timeSpent = activeGoal.timeSpent;
          final timeRemaining = timeLimit > timeSpent ? timeLimit - timeSpent : Duration.zero;
          final ringProgress = (timeLimit.inSeconds > 0)
              ? timeRemaining.inSeconds / timeLimit.inSeconds
              : 0.0;

          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 250,
                    height: 250,
                    child: ProgressRing(
                      progress: ringProgress, // Use the remaining progress for the visual
                      progressColor: color,
                      strokeWidth: 20,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatDuration(timeRemaining),
                            style: Theme.of(context).textTheme.headlineLarge,
                          ),
                          const Text('remaining'),
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
                  const SizedBox(height: 48), // Add some spacing
                  const WeeklyBarChart(), // Add the new weekly bar chart
                ],
              ),
            ),
          );
        },
      ),
      // We keep the bottom navigation bar for consistent app navigation.
      // Note: The state management for the nav bar index is simplified here.
      // In a real app, this would likely be managed by a separate provider.
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0, // Hardcoded to the dashboard index
        onTap: (index) {
          // TODO: Implement navigation logic
        },
      ),
    );
  }
}

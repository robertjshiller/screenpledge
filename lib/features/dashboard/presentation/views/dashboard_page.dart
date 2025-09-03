import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/common_widgets/bottom_nav_bar.dart';
import 'package:screenpledge/core/services/background_task_handler.dart';
import 'package:screenpledge/features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:screenpledge/features/dashboard/presentation/widgets/active_goal_view.dart';
import 'package:screenpledge/features/dashboard/presentation/widgets/goal_pending_view.dart';
import 'package:screenpledge/features/dashboard/presentation/widgets/no_goal_view.dart';
import 'package:screenpledge/features/dashboard/presentation/widgets/result_overlay_banner.dart';

/// The main Dashboard page.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardStateAsync = ref.watch(dashboardProvider);
    final profile = dashboardStateAsync.value?.profile;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Hi, ${profile?.displayName ?? 'Friend'}!',
          style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 8),
                Text(
                  '${profile?.pledgePoints ?? 0} PP',
                  style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
        automaticallyImplyLeading: false,
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(dashboardProvider.notifier).refreshDashboard(),
        child: dashboardStateAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stackTrace) => Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text('An error occurred: $error'),
            ),
          ),
          data: (dashboardState) {
            return Stack(
              children: [
                _buildDashboardBody(dashboardState),
                if (dashboardState.previousDayResult != null)
                  ResultOverlayBanner(result: dashboardState.previousDayResult!),
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          // TODO: Implement navigation for bottom nav bar
          debugPrint('Bottom nav tapped, index: $index');
        },
      ),
      // ✅ UPDATED: A Column of FloatingActionButtons for diagnostics.
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          // Button to trigger the real-time warning notification task.
          FloatingActionButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Triggering WARNING task! Check Logcat.')),
              );
              BackgroundTaskScheduler.triggerWarningTaskNow();
            },
            backgroundColor: Colors.red,
            tooltip: 'Debug: Trigger Warning Worker',
            heroTag: 'debug_warning_worker', // Add unique heroTags to prevent errors
            child: const Icon(Icons.bug_report),
          ),

          const SizedBox(height: 16), // A little space between buttons

          // Button to trigger the end-of-day data submission task.
          FloatingActionButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Triggering SUBMISSION task! Check Logcat & Supabase.')),
              );
              BackgroundTaskScheduler.triggerSubmissionTaskNow();
            },
            backgroundColor: Colors.blue,
            tooltip: 'Debug: Trigger Submission Worker',
            heroTag: 'debug_submission_worker', // Add unique heroTags to prevent errors
            child: const Icon(Icons.cloud_upload),
          ),
        ],
      ),
    );
  }

  /// A helper method to determine which main dashboard view to show.
  Widget _buildDashboardBody(DashboardState state) {
    if (state.isGoalPending) {
      return GoalPendingView(goal: state.activeGoal!);
    } else if (state.activeGoal != null) {
      return ActiveGoalView(dashboardState: state);
    } else {
      return const NoGoalView();
    }
  }
}
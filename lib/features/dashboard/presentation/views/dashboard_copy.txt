// lib/features/dashboard/presentation/views/dashboard_page.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/common_widgets/bottom_nav_bar.dart';
import 'package:screenpledge/core/config/theme/app_colors.dart';
import 'package:screenpledge/features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:screenpledge/features/dashboard/presentation/widgets/active_goal_view.dart';
import 'package:screenpledge/features/dashboard/presentation/widgets/goal_pending_view.dart';
import 'package:screenpledge/features/dashboard/presentation/widgets/no_goal_view.dart';
import 'package:screenpledge/features/dashboard/presentation/widgets/result_overlay_banner.dart';

/// ✅ REFACTORED: The main Dashboard page.
///
/// This widget is now responsible for observing the [dashboardProvider] and
/// delegating the UI rendering to specialized child widgets based on the current state.
/// It also handles the logic for showing the temporary overlay banners.
class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardStateAsync = ref.watch(dashboardProvider);
    // ✅ CHANGED: We get the whole profile object to use in the AppBar.
    final profile = dashboardStateAsync.value?.profile;
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      // ✅ REFACTORED: The AppBar is now personalized.
      appBar: AppBar(
        // The title is now a personalized greeting on the left.
        title: Text(
          // Use the displayName from the profile, with a fallback.
          'Hi, ${profile?.displayName ?? 'Friend'}!',
          style: textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        // The actions list on the right now contains the Pledge Points.
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Icon(Icons.star, color: Colors.amber), // Changed to a filled star for more impact.
                const SizedBox(width: 8),
                // Display pledge points, with a fallback of '0'.
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
        // The RefreshIndicator for pull-to-refresh functionality remains the same.
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
            // The Stack for overlaying banners remains the same.
            return Stack(
              children: [
                // --- Main Content ---
                // This is the main body of the dashboard, which changes based on the state.
                _buildDashboardBody(dashboardState),

                // --- Overlay Banners ---
                // This widget will conditionally show the Success/Failure/Timezone banner.
                if (dashboardState.previousDayResult != null)
                  ResultOverlayBanner(result: dashboardState.previousDayResult!),
                // TODO: Add the Timezone Transition banner here based on state.
              ],
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(
        currentIndex: 0,
        onTap: (index) {
          debugPrint('Bottom nav tapped, index: $index');
        },
      ),
    );
  }

  /// A helper method to determine which main dashboard view to show.
  Widget _buildDashboardBody(DashboardState state) {
    // The logic for choosing which view to display remains the same.
    if (state.isGoalPending) {
      // SCENARIO 1: Goal is set but not yet active.
      return GoalPendingView(goal: state.activeGoal!);
    } else if (state.activeGoal != null) {
      // SCENARIO 2: There is an active and effective goal.
      return ActiveGoalView(dashboardState: state);
    } else {
      // SCENARIO 3: No goal is set.
      return const NoGoalView();
    }
  }
}
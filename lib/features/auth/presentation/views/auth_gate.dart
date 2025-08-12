import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/auth_providers.dart';
import 'package:screenpledge/core/di/profile_providers.dart';
import 'package:screenpledge/features/dashboard/presentation/views/dashboard_page.dart';
import 'package:screenpledge/features/onboarding_pre/presentation/views/get_started_page.dart';
// ✅ ADDED: Imports for the new navigation destinations.
import 'package:screenpledge/features/onboarding_post/presentation/views/goal_setting_page.dart';
import 'package:screenpledge/features/onboarding_post/presentation/views/pledge_page.dart';
import 'package:screenpledge/features/onboarding_post/presentation/views/user_survey_page.dart';

/// The AuthGate is the very first widget that is loaded in the app.
///
/// Its sole responsibility is to determine the user's authentication and
/// onboarding status and route them to the correct initial screen.
/// It acts as a gatekeeper for the entire application.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // First, watch the authentication state from Supabase.
    final authState = ref.watch(authStateChangesProvider);

    // Use the `when` clause to handle the different states of the auth stream.
    return authState.when(
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stackTrace) => Scaffold(
        body: Center(child: Text('Authentication Error: $error')),
      ),
      data: (user) {
        // CASE 1: User is not logged in.
        if (user == null) {
          return const GetStartedPage();
        }
        // CASE 2: User IS logged in.
        else {
          // Now that we know the user is authenticated, we check their profile
          // to determine which onboarding checkpoint they have passed.
          final profileState = ref.watch(myProfileProvider);

          return profileState.when(
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stackTrace) => Scaffold(
              body: Center(child: Text('Error fetching profile: $error')),
            ),
            data: (profile) {
              if (profile == null) {
                return const Scaffold(
                  body: Center(
                    child: Text('Could not load user profile.'),
                  ),
                );
              }

              // ✅ CHANGED: Replaced the single boolean check with a robust,
              // multi-step decision tree to handle the granular onboarding flags.
              // This ensures that if a user quits the app mid-onboarding, they
              // are returned to the exact step where they left off.

              // If the user has completed the final step (pledge setup), they are fully onboarded.
              if (profile.onboardingCompletedPledgeSetup) {
                return const DashboardPage();
              }
              // If they've set a goal but not a pledge, send them to the Pledge page.
              else if (profile.onboardingCompletedGoalSetup) {
                return const PledgePage();
              }
              // If they've completed the survey but not set a goal, send them to Goal Setting.
              else if (profile.onboardingCompletedSurvey) {
                return const GoalSettingPage();
              }
              // If they haven't even completed the survey, that's the first step.
              else {
                return const UserSurveyPage();
              }
            },
          );
        }
      },
    );
  }
}
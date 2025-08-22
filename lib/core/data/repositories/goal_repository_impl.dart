// lib/core/data/repositories/goal_repository_impl.dart

import 'package:flutter/foundation.dart';
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/domain/entities/installed_app.dart';
import 'package:screenpledge/core/domain/repositories/goal_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// The concrete implementation of the [IGoalRepository] contract.
class GoalRepositoryImpl implements IGoalRepository {
  final SupabaseClient _supabaseClient;

  GoalRepositoryImpl(this._supabaseClient);

  @override
  Future<void> commitOnboardingGoal({int? pledgeAmountCents}) async {
    try {
      // This method calls the RPC and remains unchanged as the RPC handles the logic.
      await _supabaseClient.rpc(
        'commit_onboarding_goal',
        params: {'pledge_amount_cents_input': pledgeAmountCents ?? 0},
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Goal?> getActiveGoal() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        throw const AuthException('User is not authenticated.');
      }

      // ✅ FIXED: This now uses the definitive, modern syntax for checking for a NULL value.
      // The correct method is `.filter('column_name', 'is', null)`.
      final data = await _supabaseClient
          .from('goals')
          .select('goal_type, time_limit_seconds, tracked_apps, exempt_apps, effective_at, ended_at')
          .eq('user_id', userId)
          .filter('ended_at', 'is', null) // This is the correct syntax.
          .limit(1)
          .maybeSingle();

      if (data == null) {
        // This is a valid state; the user may not have an active goal yet.
        return null;
      }

      // The Goal object is now constructed with the new, richer data.
      return Goal(
        goalType: data['goal_type'] == 'total_time'
            ? GoalType.totalTime
            : GoalType.customGroup,
        timeLimit: Duration(seconds: data['time_limit_seconds']),
        trackedApps: <InstalledApp>{}, // Placeholder for now
        exemptApps: <InstalledApp>{}, // Placeholder for now
        effectiveAt: DateTime.parse(data['effective_at']),
        endedAt: data['ended_at'] != null ? DateTime.parse(data['ended_at']) : null,
      );
    } on PostgrestException catch (e) {
      debugPrint('Error fetching active goal: $e');
      rethrow;
    } catch (e) {
      debugPrint('An unexpected error occurred while fetching the active goal: $e');
      rethrow;
    }
  }
}
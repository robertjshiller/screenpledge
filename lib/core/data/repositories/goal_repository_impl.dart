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

      final data = await _supabaseClient
          .from('goals')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .limit(1)
          .maybeSingle();

      if (data == null) {
        return null;
      }

      return Goal(
        goalType: data['goal_type'] == 'total_time'
            ? GoalType.totalTime
            : GoalType.customGroup,
        timeLimit: Duration(seconds: data['time_limit_seconds']),
        trackedApps: <InstalledApp>{},
        exemptApps: <InstalledApp>{},
      );
    } on PostgrestException catch (e) {
      debugPrint('Error fetching active goal: $e');
      rethrow;
    } catch (e) {
      debugPrint('An unexpected error occurred: $e');
      rethrow;
    }
  }
}


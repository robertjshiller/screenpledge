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

      // The query remains the same, fetching all necessary columns.
      final data = await _supabaseClient
          .from('goals')
          .select('goal_type, time_limit_seconds, tracked_apps, exempt_apps, effective_at, ended_at')
          .eq('user_id', userId)
          .filter('ended_at', 'is', null)
          .limit(1)
          .maybeSingle();

      if (data == null) {
        // This is a valid state; the user may not have an active goal yet.
        return null;
      }

      // ✅ FIXED: Implemented the JSON deserialization for the app lists.
      // We now correctly parse the `tracked_apps` and `exempt_apps` columns.
      
      // Helper function to safely parse a list of app JSON into a Set of InstalledApp objects.
      Set<InstalledApp> _parseApps(dynamic json) {
        // If the JSON is null or not a list, return an empty set.
        if (json == null || json is! List) {
          return {};
        }
        // Iterate through the list, safely creating an InstalledApp for each entry.
        return json.map((appJson) {
          // The icon data is not stored in the goal, so we use an empty list as a placeholder.
          // The important data for the calculation is the package name.
          return InstalledApp(
            name: appJson['name'] ?? 'Unknown',
            packageName: appJson['packageName'] ?? '',
            icon: Uint8List(0), // Icon data is not needed for goal calculation.
          );
        }).toSet();
      }

      final Set<InstalledApp> trackedApps = _parseApps(data['tracked_apps']);
      final Set<InstalledApp> exemptApps = _parseApps(data['exempt_apps']);

      // The Goal object is now constructed with the real, deserialized app data.
      return Goal(
        goalType: data['goal_type'] == 'total_time'
            ? GoalType.totalTime
            : GoalType.customGroup,
        timeLimit: Duration(seconds: data['time_limit_seconds']),
        trackedApps: trackedApps, // Now contains real data.
        exemptApps: exemptApps,   // Now contains real data.
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
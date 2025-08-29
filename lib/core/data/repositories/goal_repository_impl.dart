// lib/core/data/repositories/goal_repository_impl.dart

import 'package:flutter/foundation.dart';
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/domain/entities/installed_app.dart';
import 'package:screenpledge/core/domain/repositories/cache_repository.dart';
import 'package:screenpledge/core/domain/repositories/goal_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ✅ REFACTORED: The offline-first implementation of the [IGoalRepository].
class GoalRepositoryImpl implements IGoalRepository {
  final SupabaseClient _supabaseClient;
  // ✅ NEW: Add a dependency on the cache repository.
  final ICacheRepository _cacheRepository;

  GoalRepositoryImpl(this._supabaseClient, this._cacheRepository);

  @override
  Future<void> commitOnboardingGoal({int? pledgeAmountCents}) async {
    try {
      // This is a "write" operation, so it goes directly to the network.
      await _supabaseClient.rpc(
        'commit_onboarding_goal',
        params: {'pledge_amount_cents_input': pledgeAmountCents ?? 0},
      );
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<Goal?> getActiveGoal({bool forceRefresh = false}) async {
    // This is the "Sync on Resume" pattern.

    // --- Step 1: Immediately try to load from the cache. ---
    if (!forceRefresh) {
      final cachedGoal = await _cacheRepository.getActiveGoal();
      if (cachedGoal != null) {
        // If we have a cached goal, return it immediately.
        // Then, trigger a background sync to get the latest data.
        _fetchAndCacheFreshGoal();
        return cachedGoal;
      }
    }

    // --- Step 2: If cache is empty or a refresh is forced, fetch from network. ---
    return await _fetchAndCacheFreshGoal();
  }

  /// A private helper method to handle the network fetching and caching logic for the goal.
  Future<Goal?> _fetchAndCacheFreshGoal() async {
    try {
      final userId = _supabaseClient.auth.currentUser?.id;
      if (userId == null) {
        // If the user is logged out, clear any old cached goal and return null.
        await _cacheRepository.clearGoals();
        return null;
      }

      // --- Fetch fresh data from Supabase ---
      final data = await _supabaseClient
          .from('goals')
          .select('goal_type, time_limit_seconds, tracked_apps, exempt_apps, effective_at, ended_at')
          .eq('user_id', userId)
          .filter('ended_at', 'is', null) // This correctly finds the goal that has not ended.
          .order('effective_at', ascending: false) // Get the most recent one.
          .limit(1)
          .maybeSingle();

      if (data == null) {
        // If no goal is found on the server, clear the cache and return null.
        await _cacheRepository.clearGoals();
        return null;
      }

      // Helper function to parse app lists.
      Set<InstalledApp> _parseApps(dynamic json) {
        if (json == null || json is! List) return {};
        return json.map((appJson) {
          return InstalledApp(
            name: appJson['name'] ?? 'Unknown',
            packageName: appJson['packageName'] ?? '',
            icon: Uint8List(0),
          );
        }).toSet();
      }

      final freshGoal = Goal(
        goalType: data['goal_type'] == 'total_time' ? GoalType.totalTime : GoalType.customGroup,
        timeLimit: Duration(seconds: data['time_limit_seconds']),
        trackedApps: _parseApps(data['tracked_apps']),
        exemptApps: _parseApps(data['exempt_apps']),
        effectiveAt: DateTime.parse(data['effective_at']),
        endedAt: data['ended_at'] != null ? DateTime.parse(data['ended_at']) : null,
      );

      // --- Cache the fresh data ---
      await _cacheRepository.saveActiveGoal(freshGoal);

      return freshGoal;
    } catch (e) {
      debugPrint('Error fetching fresh active goal: $e');
      // If the network fails, try to fall back to the cache one last time.
      final cachedGoal = await _cacheRepository.getActiveGoal();
      // If we have a cached goal, it's better to return that than to throw an error.
      if (cachedGoal != null) return cachedGoal;
      // If network fails AND cache is empty, we must throw the error.
      rethrow;
    }
  }
}
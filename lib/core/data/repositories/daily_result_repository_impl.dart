// lib/core/data/repositories/daily_result_repository_impl.dart

import 'package:flutter/foundation.dart';
import 'package:screenpledge/core/domain/entities/daily_result.dart';
import 'package:screenpledge/core/domain/repositories/cache_repository.dart';
import 'package:screenpledge/core/domain/repositories/daily_result_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// ✅ REFACTORED: This is the offline-first implementation of the [IDailyResultRepository].
///
/// This class now orchestrates fetching data from both the local cache and the remote
/// Supabase server, providing a seamless experience regardless of network connectivity.
class DailyResultRepositoryImpl implements IDailyResultRepository {
  final SupabaseClient _supabaseClient;
  // ✅ NEW: Add a dependency on the cache repository contract.
  final ICacheRepository _cacheRepository;

  DailyResultRepositoryImpl(this._supabaseClient, this._cacheRepository);

  @override
  Future<List<DailyResult>> getResultsForLast7Days({bool forceRefresh = false}) async {
    // This is the "Sync on Resume" pattern.

    // --- Step 1: Immediately try to load from the cache for an instant UI. ---
    if (!forceRefresh) {
      final cachedResults = await _cacheRepository.getDailyResults(limit: 7);
      // If we have cached data, return it immediately. The network sync will happen below.
      if (cachedResults.isNotEmpty) {
        // We don't await this, it runs in the background.
        _fetchAndCacheFreshResults(); 
        return cachedResults;
      }
    }

    // --- Step 2: If cache is empty or a refresh is forced, fetch from network. ---
    // This will be the case on the first app launch or when the user pulls to refresh.
    return await _fetchAndCacheFreshResults();
  }

  /// A private helper method to handle the network fetching and caching logic.
  Future<List<DailyResult>> _fetchAndCacheFreshResults() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[DailyResultRepo] _fetchAndCacheFreshResults: User not authenticated.');
      // If user is not logged in, we should also clear any old cached data.
      await _cacheRepository.clearDailyResults();
      return [];
    }

    try {
      // --- Fetch fresh data from Supabase ---
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);

      final response = await _supabaseClient
          .from('daily_results')
          .select('date, outcome, time_spent_seconds, time_limit_seconds')
          .eq('user_id', userId)
          .lte('date', todayMidnight.toIso8601String())
          .order('date', ascending: false)
          .limit(7);

      final freshResults = response.map((row) {
        return DailyResult(
          date: DateTime.parse(row['date']),
          outcome: _mapStringToOutcome(row['outcome']),
          timeSpent: Duration(seconds: row['time_spent_seconds'] ?? 0),
          timeLimit: Duration(seconds: row['time_limit_seconds'] ?? 0),
        );
      }).toList();

      // --- Cache the fresh data ---
      if (freshResults.isNotEmpty) {
        await _cacheRepository.saveDailyResults(freshResults);
      }

      return freshResults;

    } on PostgrestException catch (e) {
      debugPrint('[DailyResultRepo] PostgrestException in _fetchAndCacheFreshResults: ${e.message}');
      // If the network fails, try to fall back to the cache one last time.
      final cachedResults = await _cacheRepository.getDailyResults(limit: 7);
      if (cachedResults.isNotEmpty) return cachedResults;
      // If network fails AND cache is empty, we must throw the error.
      rethrow;
    } catch (e) {
      debugPrint('[DailyResultRepo] Unexpected error in _fetchAndCacheFreshResults: $e');
      rethrow;
    }
  }

  /// Helper to map the string from the database to our Dart enum.
  DailyOutcome _mapStringToOutcome(String? outcomeStr) {
    switch (outcomeStr) {
      case 'success':
        return DailyOutcome.success;
      case 'failure':
        return DailyOutcome.failure;
      case 'paused':
        return DailyOutcome.paused;
      case 'forgiven':
        return DailyOutcome.forgiven;
      default:
        return DailyOutcome.unknown;
    }
  }
}
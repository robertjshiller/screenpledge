// lib/core/data/repositories/daily_result_repository_impl.dart
import 'package:flutter/foundation.dart';
import 'package:screenpledge/core/domain/entities/daily_result.dart';
import 'package:screenpledge/core/domain/repositories/daily_result_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DailyResultRepositoryImpl implements IDailyResultRepository {
  final SupabaseClient _supabaseClient;
  DailyResultRepositoryImpl(this._supabaseClient);

  @override
  Future<List<DailyResult>> getResultsForLast7Days() async {
    final userId = _supabaseClient.auth.currentUser?.id;
    if (userId == null) {
      debugPrint('[DailyResultRepo] getResultsForLast7Days: User not authenticated.');
      throw const AuthException('User is not authenticated.');
    }

    try {
      final today = DateTime.now();
      final todayMidnight = DateTime(today.year, today.month, today.day);

      final response = await _supabaseClient
          .from('daily_results')
          .select('date, outcome, time_spent_seconds, time_limit_seconds')
          .eq('user_id', userId)
          .lte('date', todayMidnight.toIso8601String())
          .order('date', ascending: false)
          .limit(7);

      return response.map((row) {
        return DailyResult(
          date: DateTime.parse(row['date']),
          outcome: _mapStringToOutcome(row['outcome']),
          timeSpent: Duration(seconds: row['time_spent_seconds'] ?? 0),
          timeLimit: Duration(seconds: row['time_limit_seconds'] ?? 0),
        );
      }).toList();
    } on PostgrestException catch (e) {
      debugPrint('[DailyResultRepo] PostgrestException in getResultsForLast7Days: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[DailyResultRepo] Unexpected error in getResultsForLast7Days: $e');
      rethrow;
    }
  }

  DailyOutcome _mapStringToOutcome(String outcomeStr) {
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
// lib/core/domain/repositories/daily_result_repository.dart

import 'package:screenpledge/core/domain/entities/daily_result.dart';

/// The contract (interface) for a repository that handles DailyResult-related data operations.
///
/// ✅ CHANGED: This repository is now the single source of truth for daily results.
/// It is responsible for fetching data from the network, saving it to the cache,
/// and retrieving it from the cache, providing a seamless offline-first experience.
abstract class IDailyResultRepository {
  /// Fetches the results for the last 7 days for the current user.
  ///
  /// This method implements the "Sync on Resume" pattern:
  /// 1. It will first attempt to return data from the local cache for an instant UI.
  /// 2. It will then trigger a background fetch from the remote server.
  /// 3. If the remote fetch is successful, it will update the cache with the fresh data.
  ///
  /// [forceRefresh]: If true, it will bypass the cache and fetch directly from the network.
  ///
  /// Returns a list of [DailyResult] objects, sorted by date.
  /// Throws an exception if the operation fails and no data is cached.
  Future<List<DailyResult>> getResultsForLast7Days({bool forceRefresh = false});
}
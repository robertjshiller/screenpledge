// lib/core/domain/repositories/daily_result_repository.dart

import 'package:screenpledge/core/domain/entities/daily_result.dart';

/// The contract (interface) for a repository that handles DailyResult-related data operations.
/// This defines WHAT needs to be done.
abstract class IDailyResultRepository {
  /// Fetches the results for the last 7 days for the current user.
  ///
  /// Returns a list of [DailyResult] objects, sorted by date.
  /// Throws an exception if the operation fails.
  Future<List<DailyResult>> getResultsForLast7Days();
}

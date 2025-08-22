// lib/core/domain/usecases/get_last_7_days_results.dart

import 'package:screenpledge/core/domain/entities/daily_result.dart';
import 'package:screenpledge/core/domain/repositories/daily_result_repository.dart';

/// The DOMAIN layer Use Case for fetching the last 7 days of results.
class GetLast7DaysResultsUseCase {
  final IDailyResultRepository _repository;
  GetLast7DaysResultsUseCase(this._repository);

  /// The `call` method makes the class callable like a function.
  Future<List<DailyResult>> call() async {
    return await _repository.getResultsForLast7Days();
  }
}
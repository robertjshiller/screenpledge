// lib/core/di/daily_result_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/data/repositories/daily_result_repository_impl.dart';
import 'package:screenpledge/core/di/auth_providers.dart'; // To get the SupabaseClient
import 'package:screenpledge/core/domain/repositories/daily_result_repository.dart';
import 'package:screenpledge/core/domain/usecases/get_last_7_days_results.dart';

/// Provider for the DailyResultRepository.
final dailyResultRepositoryProvider = Provider<IDailyResultRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return DailyResultRepositoryImpl(supabaseClient);
});

/// Provider for the GetLast7DaysResultsUseCase.
final getLast7DaysResultsUseCaseProvider = Provider<GetLast7DaysResultsUseCase>((ref) {
  final dailyResultRepository = ref.watch(dailyResultRepositoryProvider);
  return GetLast7DaysResultsUseCase(dailyResultRepository);
});
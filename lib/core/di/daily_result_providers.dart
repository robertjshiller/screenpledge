// lib/core/di/daily_result_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/data/repositories/daily_result_repository_impl.dart';
import 'package:screenpledge/core/di/auth_providers.dart'; // To get the SupabaseClient
// ✅ NEW: Import the cache repository provider from the profile_providers file.
import 'package:screenpledge/core/di/profile_providers.dart';
import 'package:screenpledge/core/domain/repositories/daily_result_repository.dart';
import 'package:screenpledge/core/domain/usecases/get_last_7_days_results.dart';

/// ✅ REFACTORED: Provider for the DailyResultRepository.
/// It now depends on both the SupabaseClient (for remote data) and the
/// ICacheRepository (for local data), which are injected into its constructor.
final dailyResultRepositoryProvider = Provider<IDailyResultRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  // Watch our new cache repository provider.
  final cacheRepository = ref.watch(cacheRepositoryProvider);
  // Inject both dependencies.
  return DailyResultRepositoryImpl(supabaseClient, cacheRepository);
});

/// Provider for the GetLast7DaysResultsUseCase.
/// This provider does not need to change, as it correctly depends on the
/// IDailyResultRepository abstraction. It is unaware of the offline-first
/// changes we made in the implementation, which is the power of Clean Architecture.
final getLast7DaysResultsUseCaseProvider = Provider<GetLast7DaysResultsUseCase>((ref) {
  final dailyResultRepository = ref.watch(dailyResultRepositoryProvider);
  return GetLast7DaysResultsUseCase(dailyResultRepository);
});
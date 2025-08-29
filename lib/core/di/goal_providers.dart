// lib/core/di/goal_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/data/repositories/goal_repository_impl.dart';
// ✅ NEW: Import the cache repository provider.
import 'package:screenpledge/core/di/profile_providers.dart';
import 'package:screenpledge/core/di/service_providers.dart';
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/domain/repositories/goal_repository.dart';
import 'package:screenpledge/core/domain/usecases/commit_onboarding_goal.dart';

/// ✅ REFACTORED: Provider for the GoalRepository.
/// It now depends on both the SupabaseClient and the ICacheRepository.
final goalRepositoryProvider = Provider<IGoalRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  final cacheRepository = ref.watch(cacheRepositoryProvider);
  return GoalRepositoryImpl(supabaseClient, cacheRepository);
});

/// Provider for the CommitOnboardingGoalUseCase.
final commitOnboardingGoalUseCaseProvider = Provider<CommitOnboardingGoalUseCase>((ref) {
  final goalRepository = ref.watch(goalRepositoryProvider);
  return CommitOnboardingGoalUseCase(goalRepository);
});

/// ✅ REFACTORED: This provider now correctly uses our offline-first repository.
/// It will instantly load the goal from the cache if available, and then
/// automatically update when the network sync completes.
final activeGoalProvider = FutureProvider.autoDispose<Goal?>((ref) {
  final goalRepository = ref.watch(goalRepositoryProvider);
  return goalRepository.getActiveGoal();
});
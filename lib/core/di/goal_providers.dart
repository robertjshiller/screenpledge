// lib/core/di/goal_providers.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/data/repositories/goal_repository_impl.dart';
import 'package:screenpledge/core/di/service_providers.dart';
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/domain/repositories/goal_repository.dart';
import 'package:screenpledge/core/domain/usecases/commit_onboarding_goal.dart';

/// Provider for the GoalRepository.
final goalRepositoryProvider = Provider<IGoalRepository>((ref) {
  final supabaseClient = ref.watch(supabaseClientProvider);
  return GoalRepositoryImpl(supabaseClient);
});

/// Provider for the CommitOnboardingGoalUseCase.
final commitOnboardingGoalUseCaseProvider = Provider<CommitOnboardingGoalUseCase>((ref) {
  final goalRepository = ref.watch(goalRepositoryProvider);
  return CommitOnboardingGoalUseCase(goalRepository);
});

/// A provider that fetches the user's currently active goal definition.
final activeGoalProvider = FutureProvider.autoDispose<Goal?>((ref) {
  final goalRepository = ref.watch(goalRepositoryProvider);
  return goalRepository.getActiveGoal();
});


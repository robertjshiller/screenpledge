import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/service_providers.dart';
import 'package:screenpledge/core/domain/entities/onboarding_stats.dart';
import 'package:screenpledge/core/domain/usecases/get_onboarding_stats.dart';
import 'package:screenpledge/features/onboarding_pre/presentation/viewmodels/onboarding_stats_viewmodel.dart';

// --- Use Case Provider ---

/// Provides an instance of the [GetOnboardingStatsUseCase].
final getOnboardingStatsUseCaseProvider = Provider<GetOnboardingStatsUseCase>((ref) {
  final screenTimeService = ref.watch(screenTimeServiceProvider);
  return GetOnboardingStatsUseCase(screenTimeService);
});

// --- ViewModel Provider ---

/// Provides the [OnboardingStatsViewModel] for the UI to interact with.
final onboardingStatsViewModelProvider = StateNotifierProvider.autoDispose<
    OnboardingStatsViewModel, AsyncValue<OnboardingStats>>((ref) {
  final useCase = ref.watch(getOnboardingStatsUseCaseProvider);
  return OnboardingStatsViewModel(useCase);
});

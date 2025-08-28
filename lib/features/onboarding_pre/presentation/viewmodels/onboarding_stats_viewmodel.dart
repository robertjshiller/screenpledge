import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/domain/entities/onboarding_stats.dart';
import 'package:screenpledge/core/domain/usecases/get_onboarding_stats.dart';

/// Manages the state for the DataRevealSequence, handling the fetching and
/// calculation of the user's screen time statistics.
class OnboardingStatsViewModel extends StateNotifier<AsyncValue<OnboardingStats>> {
  final GetOnboardingStatsUseCase _getOnboardingStatsUseCase;

  OnboardingStatsViewModel(this._getOnboardingStatsUseCase)
      : super(const AsyncValue.loading()) {
    _fetchStats();
  }

  /// Executes the use case to get the stats and updates the state.
  Future<void> _fetchStats() async {
    try {
      state = const AsyncValue.loading();
      final stats = await _getOnboardingStatsUseCase();
      state = AsyncValue.data(stats);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

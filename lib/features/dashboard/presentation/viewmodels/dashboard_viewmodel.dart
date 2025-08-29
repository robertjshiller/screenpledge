// lib/features/dashboard/presentation/viewmodels/dashboard_viewmodel.dart

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:screenpledge/core/di/daily_result_providers.dart';
import 'package:screenpledge/core/di/goal_providers.dart';
import 'package:screenpledge/core/di/profile_providers.dart';
import 'package:screenpledge/core/di/service_providers.dart';
import 'package:screenpledge/core/domain/entities/daily_result.dart';
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/domain/entities/profile.dart';
import 'package:screenpledge/core/domain/repositories/daily_result_repository.dart';
import 'package:screenpledge/core/domain/repositories/goal_repository.dart';
import 'package:screenpledge/core/domain/repositories/profile_repository.dart';
import 'package:screenpledge/core/services/screen_time_service.dart';
import 'package:screenpledge/core/domain/entities/app_usage_stat.dart';

/// The state object for the dashboard.
@immutable
class DashboardState {
  final Profile? profile;
  final Goal? activeGoal;
  final List<DailyResult> weeklyResults;
  final Duration timeSpentToday;
  final List<AppUsageStat> dailyUsageBreakdown;
  final DailyResult? previousDayResult;

  const DashboardState({
    this.profile,
    this.activeGoal,
    this.weeklyResults = const [],
    this.timeSpentToday = Duration.zero,
    this.dailyUsageBreakdown = const [],
    this.previousDayResult,
  });

  bool get isGoalPending {
    if (activeGoal == null) return false;
    return activeGoal!.effectiveAt.isAfter(DateTime.now());
  }
}

/// The ViewModel for the dashboard, now fully offline-first.
class DashboardViewModel extends StateNotifier<AsyncValue<DashboardState>> {
  final IProfileRepository _profileRepo;
  final IDailyResultRepository _dailyResultRepo;
  final IGoalRepository _goalRepo;
  final ScreenTimeService _screenTimeService;
  Timer? _liveUsageTimer;

  DashboardViewModel(
    this._profileRepo,
    this._dailyResultRepo,
    this._goalRepo,
    this._screenTimeService,
  ) : super(const AsyncValue.loading()) {
    loadInitialData();
  }

  /// Loads the initial dashboard data, prioritizing cached data for a fast start.
  Future<void> loadInitialData() async {
    state = const AsyncValue.loading();
    try {
      // Fetch all data sources in parallel. The repositories handle caching.
      final results = await Future.wait([
        _profileRepo.getMyProfile(),
        _dailyResultRepo.getResultsForLast7Days(),
        _screenTimeService.getDailyUsageBreakdown(),
        _goalRepo.getActiveGoal(),
        // ✅ THE FIX: Fetch the initial "Time Used" value as part of the first load.
        // This ensures the dashboard displays the correct usage from the very
        // first frame, eliminating the "0m" bug.
        _screenTimeService.getTotalDeviceUsage(),
      ]);

      final profile = results[0] as Profile;
      final weeklyResults = results[1] as List<DailyResult>;
      final dailyBreakdown = results[2] as List<AppUsageStat>;
      final activeGoal = results[3] as Goal?;
      // ✅ THE FIX: Extract the initial usage from the results.
      final timeSpentToday = results[4] as Duration;

      final previousDayResult = _findPreviousDayResult(weeklyResults);

      final initialState = DashboardState(
        profile: profile,
        activeGoal: activeGoal,
        weeklyResults: weeklyResults,
        dailyUsageBreakdown: dailyBreakdown,
        previousDayResult: previousDayResult,
        // ✅ THE FIX: Pass the fetched initial usage to the state.
        timeSpentToday: timeSpentToday,
      );

      state = AsyncValue.data(initialState);
      // The timer will now start and take over for subsequent updates.
      _startLiveUsageUpdates();
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// A private helper to find "yesterday's" result from the weekly list.
  DailyResult? _findPreviousDayResult(List<DailyResult> results) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    try {
      return results.firstWhere((r) =>
          r.date.year == yesterday.year &&
          r.date.month == yesterday.month &&
          r.date.day == yesterday.day);
    } catch (e) {
      return null;
    }
  }

  /// Fetches fresh data from the network and updates the state.
  Future<void> refreshDashboard() async {
    try {
      final results = await Future.wait([
        _profileRepo.getMyProfile(forceRefresh: true),
        _dailyResultRepo.getResultsForLast7Days(forceRefresh: true),
        _screenTimeService.getDailyUsageBreakdown(),
        _goalRepo.getActiveGoal(forceRefresh: true),
        // ✅ THE FIX: Also fetch the latest usage on a manual refresh.
        _screenTimeService.getTotalDeviceUsage(),
      ]);

      final profile = results[0] as Profile;
      final weeklyResults = results[1] as List<DailyResult>;
      final dailyBreakdown = results[2] as List<AppUsageStat>;
      final activeGoal = results[3] as Goal?;
      final timeSpentToday = results[4] as Duration;
      final previousDayResult = _findPreviousDayResult(weeklyResults);

      final newState = DashboardState(
        profile: profile,
        activeGoal: activeGoal,
        weeklyResults: weeklyResults,
        dailyUsageBreakdown: dailyBreakdown,
        previousDayResult: previousDayResult,
        timeSpentToday: timeSpentToday,
      );
      state = AsyncValue.data(newState);
    } catch (e) {
      print("Dashboard refresh failed: $e");
    }
  }

  /// Starts a timer to periodically update the live screen time usage for today.
  void _startLiveUsageUpdates() {
    _liveUsageTimer?.cancel();
    final currentGoal = state.value?.activeGoal;
    if (currentGoal != null && !(state.value?.isGoalPending ?? true)) {
      // This timer is now only for *subsequent* updates, not the initial load.
      _liveUsageTimer = Timer.periodic(const Duration(minutes: 1), (_) async {
        if (!mounted) return;
        final timeSpent = await _screenTimeService.getTotalDeviceUsage();
        final currentState = state.value;
        if (currentState != null) {
          state = AsyncValue.data(
            DashboardState(
              profile: currentState.profile,
              activeGoal: currentState.activeGoal,
              weeklyResults: currentState.weeklyResults,
              dailyUsageBreakdown: currentState.dailyUsageBreakdown,
              previousDayResult: currentState.previousDayResult,
              timeSpentToday: timeSpent,
            ),
          );
        }
      });
    }
  }

  @override
  void dispose() {
    _liveUsageTimer?.cancel();
    super.dispose();
  }
}

/// The main provider for the dashboard.
final dashboardProvider =
    StateNotifierProvider.autoDispose<DashboardViewModel, AsyncValue<DashboardState>>(
  (ref) {
    final profileRepo = ref.watch(profileRepositoryProvider);
    final dailyResultRepo = ref.watch(dailyResultRepositoryProvider);
    final goalRepo = ref.watch(goalRepositoryProvider);
    final screenTimeService = ref.watch(screenTimeServiceProvider);
    return DashboardViewModel(profileRepo, dailyResultRepo, goalRepo, screenTimeService);
  },
);
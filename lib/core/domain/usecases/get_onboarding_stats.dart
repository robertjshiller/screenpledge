import 'dart:math';

import 'package:screenpledge/core/domain/entities/onboarding_stats.dart';
import 'package:screenpledge/core/services/screen_time_service.dart';

/// A use case dedicated to calculating screen time stats for the onboarding reveal sequence.
class GetOnboardingStatsUseCase {
  final ScreenTimeService _screenTimeService;

  GetOnboardingStatsUseCase(this._screenTimeService);

  /// Fetches the last 6 days of screen time, calculates the daily average,
  /// and extrapolates it to a projected lifetime usage in years.
  Future<OnboardingStats> call() async {
    // 1. Fetch the raw data from the service.
    final lastSixDaysUsage = await _screenTimeService.getScreenTimeForLastSixDays();

    // If the list is empty, return zeroed-out stats.
    if (lastSixDaysUsage.isEmpty) {
      return OnboardingStats(
        projectedLifetimeUsageInYears: 0,
        averageDailyUsageFormatted: "0m",
        reclaimedBooks: 0,
        reclaimedMeals: 0,
        reclaimedTrips: 0,
      );
    }

    // 2. Calculate the average daily usage.
    final totalDuration = lastSixDaysUsage.reduce((value, element) => value + element);
    final averageDailyDuration = Duration(seconds: totalDuration.inSeconds ~/ lastSixDaysUsage.length);

    // 3. Extrapolate to lifetime usage based on a 16-hour waking day.
    // This calculation is designed to be more impactful.
    // It frames the time lost as a percentage of waking life, not total time.
    const wakingHoursPerDay = 16.0;
    final averageDailyUsageInHours = averageDailyDuration.inSeconds / 3600.0;
    
    // Calculate what percentage of a waking day is spent on the screen.
    final percentageOfWakingDay = averageDailyUsageInHours / wakingHoursPerDay;
    
    // Apply that percentage to a 75-year lifespan to find the "lost" years.
    const lifespanInYears = 75.0;
    final projectedLifetimeInYears = lifespanInYears * percentageOfWakingDay;

    // 4. Calculate the dynamic "reclaimed activities" values.
    final projectedLifetimeInHours = projectedLifetimeInYears * 365.25 * wakingHoursPerDay;

    const hoursPerBook = 8.0;
    const hoursPerMeal = 1.5;
    const hoursPerTrip = 224.0; // 14 days * 16 hours/day

    final reclaimedBooks = (projectedLifetimeInHours / hoursPerBook).ceil();
    final reclaimedMeals = (projectedLifetimeInHours / hoursPerMeal).ceil();
    final reclaimedTrips = (projectedLifetimeInHours / hoursPerTrip).ceil();

    // 5. Format the average daily usage into a readable string.
    final hours = averageDailyDuration.inHours;
    final minutes = averageDailyDuration.inMinutes.remainder(60);
    final formattedAverage = hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';

    // 6. Return the fully prepared entity.
    return OnboardingStats(
      projectedLifetimeUsageInYears: max(0, projectedLifetimeInYears), // Ensure it's not negative
      averageDailyUsageFormatted: formattedAverage,
      reclaimedBooks: max(0, reclaimedBooks),
      reclaimedMeals: max(0, reclaimedMeals),
      reclaimedTrips: max(0, reclaimedTrips),
    );
  }
}

/// A data class holding the calculated statistics for the onboarding sequence.
class OnboardingStats {
  /// The projected number of years the user will spend on their screen in their lifetime.
  final double projectedLifetimeUsageInYears;

  /// The average daily screen time, formatted as a string (e.g., "4h 32m").
  final String averageDailyUsageFormatted;

  /// The number of books a user could read with their reclaimed time.
  final int reclaimedBooks;

  /// The number of family meals a user could have with their reclaimed time.
  final int reclaimedMeals;

  /// The number of life-changing trips a user could take with their reclaimed time.
  final int reclaimedTrips;

  OnboardingStats({
    required this.projectedLifetimeUsageInYears,
    required this.averageDailyUsageFormatted,
    required this.reclaimedBooks,
    required this.reclaimedMeals,
    required this.reclaimedTrips,
  });
}

// lib/core/domain/entities/active_goal.dart

import 'package:flutter/foundation.dart';

/// A data class that holds the necessary information for the dashboard view.
///
/// It combines the goal's definition (the limit) with the user's real-time
/// progress (the time spent) for a given day.
@immutable
class ActiveGoal {
  /// The total screen time allowed for this goal, fetched from Supabase.
  final Duration timeLimit;

  /// The actual screen time spent by the user so far today.
  /// This data comes from the device's native screen time API and is calculated
  /// according to the goal's rules (e.g., exempting apps).
  final Duration timeSpent;

  const ActiveGoal({
    required this.timeLimit,
    required this.timeSpent,
  });

  /// A convenience getter to calculate the progress as a value between 0.0 and 1.0.
  double get progressPercentage {
    if (timeLimit.inSeconds == 0) {
      return 0.0;
    }
    // Clamp the value between 0.0 and 1.0 to handle cases where time spent
    // might exceed the limit.
    return (timeSpent.inSeconds / timeLimit.inSeconds).clamp(0.0, 1.0);
  }
}

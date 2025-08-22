// lib/core/domain/entities/daily_result.dart

import 'package:flutter/foundation.dart';

/// Represents the outcome of a single day's pledge.
enum DailyOutcome {
  success,
  failure,
  paused,
  forgiven,
  unknown,
}

/// A pure domain entity representing the recorded result for a single day.
/// This class now includes the quantitative data needed for the chart tooltips.
@immutable
class DailyResult {
  /// The specific date this result applies to.
  final DateTime date;

  /// The outcome for that day.
  final DailyOutcome outcome;

  /// ✅ ADDED: The actual screen time the user spent on this day.
  final Duration timeSpent;

  /// ✅ ADDED: The goal limit the user had on this day.
  final Duration timeLimit;

  const DailyResult({
    required this.date,
    required this.outcome,
    required this.timeSpent,
    required this.timeLimit,
  });
}
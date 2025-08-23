// lib/core/domain/entities/daily_result.dart
import 'package:flutter/foundation.dart';

enum DailyOutcome { success, failure, paused, forgiven, unknown }

@immutable
class DailyResult {
  final DateTime date;
  final DailyOutcome outcome;
  final Duration timeSpent;
  final Duration timeLimit;

  const DailyResult({
    required this.date,
    required this.outcome,
    required this.timeSpent,
    required this.timeLimit,
  });
}
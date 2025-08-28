// lib/core/domain/entities/daily_result.dart

import 'dart:convert';
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

  /// ✅ NEW: Converts the [DailyResult] instance into a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'date': date.toIso8601String(),
      'outcome': outcome.name,
      'timeSpent': timeSpent.inSeconds,
      'timeLimit': timeLimit.inSeconds,
    };
  }

  /// ✅ NEW: Creates a [DailyResult] instance from a map.
  factory DailyResult.fromMap(Map<String, dynamic> map) {
    return DailyResult(
      date: DateTime.parse(map['date']),
      outcome: DailyOutcome.values.byName(map['outcome']),
      timeSpent: Duration(seconds: map['timeSpent']),
      timeLimit: Duration(seconds: map['timeLimit']),
    );
  }

  /// ✅ NEW: Converts the [DailyResult] instance into a JSON string.
  String toJson() => json.encode(toMap());

  /// ✅ NEW: Creates a [DailyResult] instance from a JSON string.
  factory DailyResult.fromJson(String source) =>
      DailyResult.fromMap(json.decode(source) as Map<String, dynamic>);
}
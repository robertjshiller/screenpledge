// lib/core/domain/entities/goal.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:screen_time_channel/installed_app.dart';

/// Represents the type of goal the user can set.
/// This mirrors the `goal_type` ENUM in the Supabase database schema.
enum GoalType {
  totalTime,
  customGroup,
}

/// A pure domain entity representing a user's screen time goal.
///
/// This class is part of the core domain and has no knowledge of the database
/// or any external services. It simply holds the data required to define a goal.
@immutable
class Goal {
  /// The type of goal being set.
  final GoalType goalType;

  /// The daily time limit the user has set for their goal.
  final Duration timeLimit;

  /// The set of apps to be specifically tracked (for a 'customGroup' goal).
  final Set<InstalledApp> trackedApps;

  /// The set of apps to be ignored from tracking (for a 'totalTime' goal).
  final Set<InstalledApp> exemptApps;

  /// The timestamp when this goal becomes active.
  final DateTime effectiveAt;

  /// The timestamp when this goal is superseded by a new one.
  /// This will be null for the currently active goal.
  final DateTime? endedAt;

  const Goal({
    required this.goalType,
    required this.timeLimit,
    required this.trackedApps,
    required this.exemptApps,
    required this.effectiveAt,
    this.endedAt,
  });

  /// ✅ NEW: Converts the [Goal] instance into a map for serialization.
  Map<String, dynamic> toMap() {
    return {
      'goalType': goalType.name,
      'timeLimit': timeLimit.inSeconds,
      // Note: We are not caching the full app list, just the package names.
      'trackedApps': trackedApps.map((x) => x.packageName).toList(),
      'exemptApps': exemptApps.map((x) => x.packageName).toList(),
      'effectiveAt': effectiveAt.toIso8601String(),
      'endedAt': endedAt?.toIso8601String(),
    };
  }

  /// ✅ NEW: Creates a [Goal] instance from a map.
  /// Note: This is a simplified version for caching. It does not restore the
  /// full `InstalledApp` objects, as they are not needed by the background task.
  factory Goal.fromMap(Map<String, dynamic> map) {
    return Goal(
      goalType: GoalType.values.byName(map['goalType']),
      timeLimit: Duration(seconds: map['timeLimit']),
      // For the cached version, we create empty sets as the background task
      // doesn't need the app lists, only the time limit.
      trackedApps: const {},
      exemptApps: const {},
      effectiveAt: DateTime.parse(map['effectiveAt']),
      endedAt: map['endedAt'] != null ? DateTime.parse(map['endedAt']) : null,
    );
  }

  /// ✅ NEW: Converts the [Goal] instance into a JSON string for caching.
  String toJson() => json.encode(toMap());

  /// ✅ NEW: Creates a [Goal] instance from a JSON string.
  factory Goal.fromJson(String source) =>
      Goal.fromMap(json.decode(source) as Map<String, dynamic>);
}
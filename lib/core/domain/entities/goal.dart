// lib/core/domain/entities/goal.dart

import 'package:flutter/foundation.dart';
import 'package:screenpledge/core/domain/entities/installed_app.dart';

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

  /// ✅ ADDED: The timestamp when this goal becomes active.
  final DateTime effectiveAt;

  /// ✅ ADDED: The timestamp when this goal is superseded by a new one.
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
}
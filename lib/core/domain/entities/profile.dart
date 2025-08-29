// lib/core/domain/entities/profile.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';

/// Represents a user's public profile data, as stored in the `profiles` table.
///
/// This entity is a core concept in the application, distinct from the
/// `User` object from Supabase which is only used for authentication. The Profile
/// holds all application-specific data about the user.
///
/// This class is immutable, meaning its state cannot be changed after creation.
/// To update a profile, a new instance must be created.
@immutable
class Profile {
  /// The unique identifier for the user, which must match the Supabase auth user ID.
  final String id;

  /// The user's email address. Can be null.
  final String? email;

  /// ✅ CHANGED: The user's chosen display name or nickname. Can be null.
  /// This is semantically more correct than 'fullName' for our use case.
  final String? displayName;

  /// The current balance of Pledge Points (PP) the user can spend in the rewards marketplace.
  final int pledgePoints;

  /// The total number of Pledge Points the user has ever earned.
  final int lifetimePledgePoints;

  /// The user's current success streak in days.
  final int streakCount;

  /// The current status of the user's monetary pledge.
  final String pledgeStatus;

  /// The monetary amount of the user's pledge, in cents.
  final int pledgeAmountCents;

  /// The user's self-reported timezone, crucial for determining the start
  /// and end of a "day" for goal tracking (e.g., "America/New_York").
  final String? userTimezone;

  /// A flag indicating completion of the onboarding survey.
  final bool onboardingCompletedSurvey;

  /// A flag indicating completion of the initial goal setup.
  final bool onboardingCompletedGoalSetup;

  /// A flag indicating completion of the initial pledge setup.
  final bool onboardingCompletedPledgeSetup;

  /// A field to temporarily store the goal configuration during onboarding.
  /// This makes the onboarding flow resilient to interruptions. It is populated
  /// on the GoalSettingPage and consumed on the PledgePage. It should be cleared
  /// after the final goal is created.
  final Map<String, dynamic>? onboardingDraftGoal;

  /// The timestamp when the profile was first created in the database.
  final DateTime createdAt;

  /// The timestamp when the profile was last updated in the database.
  final DateTime updatedAt;

  /// Creates a const instance of the [Profile] entity.
  const Profile({
    required this.id,
    this.email,
    // ✅ CHANGED: The constructor now accepts 'displayName'.
    this.displayName,
    required this.pledgePoints,
    required this.lifetimePledgePoints,
    required this.streakCount,
    required this.pledgeStatus,
    required this.pledgeAmountCents,
    this.userTimezone,
    required this.onboardingCompletedSurvey,
    required this.onboardingCompletedGoalSetup,
    required this.onboardingCompletedPledgeSetup,
    this.onboardingDraftGoal,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [Profile] instance from a JSON map (a Map<String, dynamic>).
  ///
  /// This factory is used to deserialize the data fetched from the Supabase
  /// `profiles` table into a type-safe Dart object.
  factory Profile.fromMap(Map<String, dynamic> map) {
    return Profile(
      id: map['id'] as String,
      email: map['email'] as String?,
      // ✅ CHANGED: Reads from the 'display_name' column in the database.
      displayName: map['display_name'] as String?,
      pledgePoints: map['pledge_points'] as int,
      lifetimePledgePoints: map['lifetime_pledge_points'] as int,
      streakCount: map['streak_count'] as int,
      pledgeStatus: map['pledge_status'] as String,
      pledgeAmountCents: map['pledge_amount_cents'] as int,
      userTimezone: map['user_timezone'] as String?,
      onboardingCompletedSurvey: map['onboarding_completed_survey'] as bool,
      onboardingCompletedGoalSetup: map['onboarding_completed_goal_setup'] as bool,
      onboardingCompletedPledgeSetup: map['onboarding_completed_pledge_setup'] as bool,
      onboardingDraftGoal: map['onboarding_draft_goal'] != null
          ? Map<String, dynamic>.from(map['onboarding_draft_goal'])
          : null,
      createdAt: DateTime.parse(map['created_at'] as String),
      updatedAt: DateTime.parse(map['updated_at'] as String),
    );
  }

  /// Creates a [Profile] instance from a JSON string.
  /// This is a convenience factory for deserializing data from SharedPreferences.
  factory Profile.fromJson(String source) =>
      Profile.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Converts the [Profile] instance into a map.
  /// This is the first step in serializing the object to a JSON string.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      // ✅ CHANGED: Writes to the 'display_name' key for serialization.
      'display_name': displayName,
      'pledge_points': pledgePoints,
      'lifetime_pledge_points': lifetimePledgePoints,
      'streak_count': streakCount,
      'pledge_status': pledgeStatus,
      'pledge_amount_cents': pledgeAmountCents,
      'user_timezone': userTimezone,
      'onboarding_completed_survey': onboardingCompletedSurvey,
      'onboarding_completed_goal_setup': onboardingCompletedGoalSetup,
      'onboarding_completed_pledge_setup': onboardingCompletedPledgeSetup,
      'onboarding_draft_goal': onboardingDraftGoal,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  /// Converts the [Profile] instance into a JSON string.
  /// This is used for saving the object to SharedPreferences.
  String toJson() => json.encode(toMap());

  // Override equality and hashCode to ensure two Profile instances with the
  // same ID are treated as equal.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Profile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
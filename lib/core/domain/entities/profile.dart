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

  /// The user's full name. Can be null.
  final String? fullName;

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

  // ✅ ADDED: A field to temporarily store the goal configuration during onboarding.
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
    this.fullName,
    required this.pledgePoints,
    required this.lifetimePledgePoints,
    required this.streakCount,
    required this.pledgeStatus,
    required this.pledgeAmountCents,
    this.userTimezone,
    required this.onboardingCompletedSurvey,
    required this.onboardingCompletedGoalSetup,
    required this.onboardingCompletedPledgeSetup,
    this.onboardingDraftGoal, // ✅ ADDED
    required this.createdAt,
    required this.updatedAt,
  });

  /// Creates a [Profile] instance from a JSON map (a Map<String, dynamic>).
  ///
  /// This factory is used to deserialize the data fetched from the Supabase
  /// `profiles` table into a type-safe Dart object.
  factory Profile.fromJson(Map<String, dynamic> json) {
    return Profile(
      id: json['id'] as String,
      email: json['email'] as String?,
      fullName: json['full_name'] as String?,
      pledgePoints: json['pledge_points'] as int,
      lifetimePledgePoints: json['lifetime_pledge_points'] as int,
      streakCount: json['streak_count'] as int,
      pledgeStatus: json['pledge_status'] as String,
      pledgeAmountCents: json['pledge_amount_cents'] as int,
      userTimezone: json['user_timezone'] as String?,
      onboardingCompletedSurvey: json['onboarding_completed_survey'] as bool,
      onboardingCompletedGoalSetup: json['onboarding_completed_goal_setup'] as bool,
      onboardingCompletedPledgeSetup: json['onboarding_completed_pledge_setup'] as bool,
      // ✅ ADDED: Safely cast the jsonb column to a Map. It can be null.
      onboardingDraftGoal: json['onboarding_draft_goal'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

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
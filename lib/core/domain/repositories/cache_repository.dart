// lib/core/domain/repositories/cache_repository.dart

import 'package:screenpledge/core/domain/entities/daily_result.dart';
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/domain/entities/profile.dart';

/// The contract (interface) for a centralized repository that handles all
/// on-device data caching.
///
/// This abstraction allows the rest of the app (ViewModels, UseCases) to
/// interact with the cache without needing to know the underlying storage
/// technology (e.g., SharedPreferences, SQLite).
abstract class ICacheRepository {
  // --- Profile Caching ---

  /// Saves the user's complete profile data to the local cache.
  /// [profile]: The user's Profile object to be saved.
  Future<void> saveProfile(Profile profile);

  /// Retrieves the user's profile data from the local cache.
  /// Returns null if no profile is cached.
  Future<Profile?> getProfile();

  /// Deletes all cached profile data.
  /// This is useful when the user logs out.
  Future<void> clearProfile();

  // --- Goal Caching ---

  /// Saves the user's currently active goal to the local cache.
  /// [goal]: The active Goal object.
  Future<void> saveActiveGoal(Goal goal);

  /// Retrieves the user's active goal from the local cache.
  /// Returns null if no active goal is cached.
  Future<Goal?> getActiveGoal();

  /// Saves a pending goal that will become active in the future.
  /// [goal]: The pending Goal object.
  Future<void> savePendingGoal(Goal goal);

  /// Retrieves the pending goal from the local cache.
  /// Returns null if no pending goal is cached.
  Future<Goal?> getPendingGoal();

  /// Deletes all cached goal data.
  Future<void> clearGoals();

  // --- Daily Results Caching ---

  /// Saves a list of daily results to the local cache (SQLite).
  /// This will typically overwrite existing data to keep it fresh.
  /// [results]: A list of DailyResult objects.
  Future<void> saveDailyResults(List<DailyResult> results);

  /// Retrieves a list of the most recent daily results from the cache.
  /// [limit]: The maximum number of results to return (e.g., for the 7-day chart).
  Future<List<DailyResult>> getDailyResults({int limit = 7});

  /// Deletes all cached daily results.
  Future<void> clearDailyResults();
}
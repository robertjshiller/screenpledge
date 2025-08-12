import 'package:screenpledge/core/data/datasources/goal_remote_datasource.dart';
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/domain/repositories/goal_repository.dart';

/// The concrete implementation of the [IGoalRepository].
/// This is a shared capability, so it lives in the core data layer.
class GoalRepositoryImpl implements IGoalRepository {
  final GoalRemoteDataSource _remoteDataSource;

  GoalRepositoryImpl(this._remoteDataSource);

  @override
  Future<void> saveGoal(Goal goal) async {
    // 1. Convert the pure domain 'Goal' object into a Map that matches the database schema.
    final goalData = {
      // The user_id is handled by Supabase RLS policies and default values.
      'status': 'active', // Default status when creating a new goal.
      'goal_type': goal.goalType == GoalType.totalTime ? 'total_time' : 'custom_group',
      'time_limit_seconds': goal.timeLimit.inSeconds,
      // Convert the Set of InstalledApp objects to a List of JSON maps.
      'tracked_apps': goal.trackedApps.map((app) => app.toJson()).toList(),
      'exempt_apps': goal.exemptApps.map((app) => app.toJson()).toList(),
    };

    // 2. Call the remote data source to perform the database operation.
    await _remoteDataSource.createGoal(goalData);
  }
}
import 'package:screenpledge/core/domain/entities/goal.dart';

/// The contract (interface) for a repository that handles goal-related data operations.
///
/// This abstract class defines *what* can be done with goals, but not *how*.
/// The concrete implementation will live in the data layer and will know how
/// to communicate with Supabase.
abstract class IGoalRepository {
  /// Saves a user's goal to the persistent data store.
  ///
  /// Takes a domain [Goal] object as input.
  /// Throws an exception if the operation fails, which can be caught in the UI layer.
  Future<void> saveGoal(Goal goal);
}
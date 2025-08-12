import 'package:supabase_flutter/supabase_flutter.dart';

/// The data source responsible for all direct communication with the remote 'goals' table in Supabase.
/// This is a shared capability, so it lives in the core data layer.
class GoalRemoteDataSource {
  final SupabaseClient _supabase;

  GoalRemoteDataSource(this._supabase);

  /// Creates a new goal record in the Supabase database.
  ///
  /// Takes a [goalData] map that directly corresponds to the table schema.
  /// Throws a [PostgrestException] if the database operation fails.
  Future<void> createGoal(Map<String, dynamic> goalData) async {
    try {
      await _supabase.from('goals').insert(goalData);
    } catch (e) {
      // Re-throw the original exception to be handled by the repository/UI layer.
      rethrow;
    }
  }
}
import 'package:screenpledge/core/domain/entities/goal.dart';
import 'package:screenpledge/core/domain/repositories/goal_repository.dart';

/// A use case that encapsulates the business logic for saving a user's goal.
///
/// This use case depends on the abstract [IGoalRepository] and has no knowledge
/// of the underlying data source.
class SaveGoalUseCase {
  final IGoalRepository _repository;

  SaveGoalUseCase(this._repository);

  /// Executes the use case.
  Future<void> call(Goal goal) async {
    // For now, it's a simple pass-through. In the future, more complex
    // business rules could be added here before saving.
    return _repository.saveGoal(goal);
  }
}
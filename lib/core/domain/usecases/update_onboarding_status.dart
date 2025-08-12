import 'package:screenpledge/core/domain/repositories/profile_repository.dart';

/// A use case that encapsulates the business logic for updating an onboarding checkpoint.
///
/// This makes the action of updating a flag a reusable and testable piece of business logic.
class UpdateOnboardingStatusUseCase {
  final IProfileRepository _repository;

  UpdateOnboardingStatusUseCase(this._repository);

  /// Executes the use case.
  Future<void> call(String checkpoint, bool status) async {
    return _repository.updateOnboardingStatus(checkpoint, status);
  }
}
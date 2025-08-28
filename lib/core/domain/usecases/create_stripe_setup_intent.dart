import 'package:screenpledge/core/domain/repositories/profile_repository.dart';

/// This use case is responsible for the single action of creating a Stripe Setup Intent.
/// It depends on the IProfileRepository contract to stay decoupled from the data layer.
class CreateStripeSetupIntentUseCase {
  final IProfileRepository _repository;

  CreateStripeSetupIntentUseCase(this._repository);

  /// Executes the use case.
  /// It calls the repository method and returns the client_secret string needed by the Stripe SDK.
  Future<String> call() {
    return _repository.createStripeSetupIntent();
  }
}
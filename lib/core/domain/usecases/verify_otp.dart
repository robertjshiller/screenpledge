// lib/core/domain/usecases/verify_otp.dart

import 'package:screenpledge/core/domain/repositories/auth_repository.dart';

class VerifyOtp {
  final IAuthRepository _repository;
  VerifyOtp(this._repository);

  Future<void> call({required String email, required String token}) async {
    return await _repository.verifyOtp(email: email, token: token);
  }
}

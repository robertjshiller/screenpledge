// lib/core/domain/usecases/resend_otp.dart

import 'package:screenpledge/core/domain/repositories/auth_repository.dart';

class ResendOtp {
  final IAuthRepository _repository;
  ResendOtp(this._repository);

  Future<void> call({required String email}) async {
    return await _repository.resendOtp(email: email);
  }
}
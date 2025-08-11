// lib/core/domain/usecases/sign_up.dart

import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:screenpledge/core/domain/repositories/auth_repository.dart';

class SignUp {
  final IAuthRepository _repository;
  SignUp(this._repository);

  Future<User> call({required String email, required String password}) async {
    return await _repository.signUpWithEmail(email: email, password: password);
  }
}
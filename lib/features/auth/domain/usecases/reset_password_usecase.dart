import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class ResetPasswordParams {
  final String email;

  const ResetPasswordParams({
    required this.email,
  });
}

class ResetPasswordUseCase implements UseCase<void, ResetPasswordParams> {
  final AuthRepository repository;

  ResetPasswordUseCase(this.repository);

  @override
  Future<void> call(ResetPasswordParams params) {
    return repository.sendPasswordResetEmail(
      email: params.email,
    );
  }
}

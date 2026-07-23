import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterParams {
  final String email;
  final String password;
  final String fullName;

  const RegisterParams({
    required this.email,
    required this.password,
    required this.fullName,
  });
}

class RegisterUseCase implements UseCase<UserEntity, RegisterParams> {
  final AuthRepository repository;

  RegisterUseCase(this.repository);

  @override
  Future<UserEntity> call(RegisterParams params) {
    return repository.signUpWithEmailAndPassword(
      email: params.email,
      password: params.password,
      fullName: params.fullName,
    );
  }
}

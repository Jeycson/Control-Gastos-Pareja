import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class IdentifyUserParams {
  final String fullName;

  const IdentifyUserParams({required this.fullName});
}

class IdentifyUserUseCase implements UseCase<UserEntity, IdentifyUserParams> {
  final AuthRepository repository;

  IdentifyUserUseCase(this.repository);

  @override
  Future<UserEntity> call(IdentifyUserParams params) async {
    return await repository.identifyUser(fullName: params.fullName);
  }
}

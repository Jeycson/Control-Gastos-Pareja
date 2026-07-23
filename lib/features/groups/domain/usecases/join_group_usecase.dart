import '../../../../core/usecases/usecase.dart';
import '../entities/group_entity.dart';
import '../repositories/group_repository.dart';

class JoinGroupParams {
  final String inviteCode;
  final String userId;

  const JoinGroupParams({
    required this.inviteCode,
    required this.userId,
  });
}

class JoinGroupUseCase implements UseCase<GroupEntity, JoinGroupParams> {
  final GroupRepository repository;

  JoinGroupUseCase(this.repository);

  @override
  Future<GroupEntity> call(JoinGroupParams params) {
    return repository.joinGroupWithInviteCode(
      inviteCode: params.inviteCode,
      userId: params.userId,
    );
  }
}

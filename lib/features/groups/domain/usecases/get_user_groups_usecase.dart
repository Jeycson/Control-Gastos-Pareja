import '../../../../core/usecases/usecase.dart';
import '../entities/group_entity.dart';
import '../repositories/group_repository.dart';

class GetUserGroupsUseCase implements UseCase<List<GroupEntity>, String> {
  final GroupRepository repository;

  GetUserGroupsUseCase(this.repository);

  @override
  Future<List<GroupEntity>> call(String userId) {
    return repository.getUserGroups(userId);
  }
}

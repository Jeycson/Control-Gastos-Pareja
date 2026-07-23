import '../../../../core/usecases/usecase.dart';
import '../entities/group_entity.dart';
import '../repositories/group_repository.dart';

class CreateGroupParams {
  final String name;
  final double budgetTotal;
  final DateTime startDate;
  final int weeksCount;
  final String createdBy;

  const CreateGroupParams({
    required this.name,
    required this.budgetTotal,
    required this.startDate,
    required this.weeksCount,
    required this.createdBy,
  });
}

class CreateGroupUseCase implements UseCase<GroupEntity, CreateGroupParams> {
  final GroupRepository repository;

  CreateGroupUseCase(this.repository);

  @override
  Future<GroupEntity> call(CreateGroupParams params) {
    return repository.createGroup(
      name: params.name,
      budgetTotal: params.budgetTotal,
      startDate: params.startDate,
      weeksCount: params.weeksCount,
      createdBy: params.createdBy,
    );
  }
}

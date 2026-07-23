import '../../../../core/usecases/usecase.dart';
import '../entities/budget_week_entity.dart';
import '../entities/group_entity.dart';
import '../entities/group_member_entity.dart';
import '../repositories/group_repository.dart';

class GroupSummary {
  final GroupEntity group;
  final double totalSpent;
  final List<GroupMemberEntity> members;
  final List<BudgetWeekEntity> budgetWeeks;

  const GroupSummary({
    required this.group,
    required this.totalSpent,
    required this.members,
    required this.budgetWeeks,
  });
}

class GetGroupSummaryUseCase implements UseCase<GroupSummary, String> {
  final GroupRepository repository;

  GetGroupSummaryUseCase(this.repository);

  @override
  Future<GroupSummary> call(String groupId) async {
    final group = await repository.getGroupById(groupId);
    if (group == null) {
      throw Exception('Grupo no encontrado.');
    }
    final totalSpent = await repository.getGroupTotalSpent(groupId);
    final members = await repository.getGroupMembers(groupId);
    final budgetWeeks = await repository.getGroupBudgetWeeks(groupId);

    return GroupSummary(
      group: group,
      totalSpent: totalSpent,
      members: members,
      budgetWeeks: budgetWeeks,
    );
  }
}

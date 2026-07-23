import '../entities/budget_week_entity.dart';
import '../entities/group_entity.dart';
import '../entities/group_member_entity.dart';

abstract class GroupRepository {
  Future<List<GroupEntity>> getUserGroups(String userId);
  Future<GroupEntity?> getGroupById(String groupId);
  Future<GroupEntity> createGroup({
    required String name,
    required double budgetTotal,
    required DateTime startDate,
    required int weeksCount,
    required String createdBy,
  });
  Future<GroupEntity> joinGroupWithInviteCode({
    required String inviteCode,
    required String userId,
  });
  Future<List<GroupMemberEntity>> getGroupMembers(String groupId);
  Future<List<BudgetWeekEntity>> getGroupBudgetWeeks(String groupId);
  Future<double> getGroupTotalSpent(String groupId);
}

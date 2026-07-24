import '../../../../core/usecases/usecase.dart';
import '../../../groups/domain/entities/budget_week_entity.dart';
import '../../../groups/domain/entities/group_entity.dart';
import '../../../groups/domain/repositories/group_repository.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../entities/dashboard_metrics_entity.dart';
import '../services/dashboard_calculator.dart';

class GetDashboardDataParams {
  final String? groupId;
  final String userId;

  const GetDashboardDataParams({
    this.groupId,
    required this.userId,
  });
}

class GetDashboardDataUseCase
    implements UseCase<DashboardMetricsEntity, GetDashboardDataParams> {
  final GroupRepository groupRepository;
  final TransactionRepository transactionRepository;

  GetDashboardDataUseCase({
    required this.groupRepository,
    required this.transactionRepository,
  });

  @override
  Future<DashboardMetricsEntity> call(GetDashboardDataParams params) async {
    String? activeGroupId = params.groupId;
    GroupEntity? group;
    List<BudgetWeekEntity>? budgetWeeks;

    if (activeGroupId != null && activeGroupId.isNotEmpty) {
      group = await groupRepository.getGroupById(activeGroupId);
      budgetWeeks = await groupRepository.getGroupBudgetWeeks(activeGroupId);
    } else {
      // If no groupId passed, try to fetch user's first group
      final userGroups = await groupRepository.getUserGroups(params.userId);
      if (userGroups.isNotEmpty) {
        group = userGroups.first;
        activeGroupId = group.id;
        budgetWeeks = await groupRepository.getGroupBudgetWeeks(activeGroupId);
      }
    }

    final List<TransactionEntity> transactions =
        await transactionRepository.getTransactions(
      userId: params.userId,
      groupId: activeGroupId,
    );

    return DashboardCalculator.buildMetrics(
      group: group,
      budgetWeeks: budgetWeeks,
      transactions: transactions,
    );
  }
}

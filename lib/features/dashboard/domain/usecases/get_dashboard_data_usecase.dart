import '../../../../core/usecases/usecase.dart';
import '../../../groups/domain/entities/budget_week_entity.dart';
import '../../../groups/domain/entities/group_entity.dart';
import '../../../groups/domain/repositories/group_repository.dart';
import '../../../groups/domain/services/budget_recalculator.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/domain/repositories/transaction_repository.dart';
import '../../../wallets/domain/repositories/wallet_repository.dart';
import '../entities/dashboard_metrics_entity.dart';
import '../services/dashboard_calculator.dart';

class GetDashboardDataParams {
  final String? groupId;
  final String userId;
  final DateTime? customStartDate;
  final DateTime? customEndDate;
  final int? customWeeksCount;

  const GetDashboardDataParams({
    this.groupId,
    required this.userId,
    this.customStartDate,
    this.customEndDate,
    this.customWeeksCount,
  });
}

class GetDashboardDataUseCase
    implements UseCase<DashboardMetricsEntity, GetDashboardDataParams> {
  final GroupRepository groupRepository;
  final TransactionRepository transactionRepository;
  final WalletRepository walletRepository;

  GetDashboardDataUseCase({
    required this.groupRepository,
    required this.transactionRepository,
    required this.walletRepository,
  });

  @override
  Future<DashboardMetricsEntity> call(GetDashboardDataParams params) async {
    final String? activeGroupId = params.groupId;
    GroupEntity? group;
    List<BudgetWeekEntity>? budgetWeeks;

    final List<TransactionEntity> transactions =
        await transactionRepository.getTransactions(
      userId: params.userId,
      groupId: activeGroupId,
    );

    if (activeGroupId != null && activeGroupId.isNotEmpty) {
      group = await groupRepository.getGroupById(activeGroupId);
      budgetWeeks = await groupRepository.getGroupBudgetWeeks(activeGroupId);
    } else {
      // Individual Mode: Compute budget weeks dynamically from sum of user wallets + period spent
      final wallets = await walletRepository.getWallets(params.userId);
      final currentWalletsSum = wallets.fold<double>(0.0, (sum, w) => sum + w.balance);

      final startDate = params.customStartDate ?? DateTime(DateTime.now().year, DateTime.now().month, 1);
      final weeksCount = params.customWeeksCount ?? 4;
      final endDate = params.customEndDate ??
          DateTime(startDate.year, startDate.month, startDate.day + (weeksCount * 7) - 1, 23, 59, 59);

      // Total spent within the current budget period
      final totalSpentInPeriod = transactions
          .where((tx) =>
              !tx.createdAt.isBefore(startDate) &&
              !tx.createdAt.isAfter(endDate))
          .fold<double>(0.0, (sum, tx) => sum + tx.amount);

      // Fixed initial budget before expenses
      final initialBudgetAmount = currentWalletsSum + totalSpentInPeriod;
      final weeklyPlanned = weeksCount > 0 ? initialBudgetAmount / weeksCount : 0.0;
      List<BudgetWeekEntity> generatedWeeks = [];

      for (int i = 1; i <= weeksCount; i++) {
        final wStart = DateTime(startDate.year, startDate.month, startDate.day + (i - 1) * 7);
        final wEnd = DateTime(wStart.year, wStart.month, wStart.day + 6, 23, 59, 59);

        final weekSpent = transactions
            .where((tx) =>
                !tx.createdAt.isBefore(wStart) &&
                !tx.createdAt.isAfter(wEnd))
            .fold<double>(0.0, (sum, tx) => sum + tx.amount);

        generatedWeeks.add(BudgetWeekEntity(
          id: 'ind_$i',
          groupId: '',
          weekNumber: i,
          startDate: wStart,
          endDate: wEnd,
          plannedAmount: weeklyPlanned,
          spentAmount: weekSpent,
          adjustedAmount: weeklyPlanned,
        ));
      }

      final now = DateTime.now();
      for (int i = 0; i < generatedWeeks.length; i++) {
        if (generatedWeeks[i].endDate.isBefore(now) && i < generatedWeeks.length - 1) {
          generatedWeeks = BudgetRecalculator.closeWeekAndRedistribute(generatedWeeks, i);
        }
      }

      budgetWeeks = generatedWeeks;
    }

    return DashboardCalculator.buildMetrics(
      group: group,
      budgetWeeks: budgetWeeks,
      transactions: transactions,
    );
  }
}

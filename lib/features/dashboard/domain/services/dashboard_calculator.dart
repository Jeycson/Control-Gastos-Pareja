import '../../../groups/domain/entities/budget_week_entity.dart';
import '../../../groups/domain/entities/group_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../entities/category_expense_entity.dart';
import '../entities/dashboard_metrics_entity.dart';

abstract class DashboardCalculator {
  static double calculateTimeProgress(
    DateTime? startDate,
    DateTime? endDate,
    DateTime now,
  ) {
    if (startDate == null || endDate == null) return 0.0;
    if (endDate.isBefore(startDate) || endDate == startDate) return 0.0;
    if (now.isBefore(startDate)) return 0.0;
    if (now.isAfter(endDate)) return 100.0;

    final totalSeconds = endDate.difference(startDate).inSeconds;
    if (totalSeconds <= 0) return 0.0;

    final elapsedSeconds = now.difference(startDate).inSeconds;
    final progress = (elapsedSeconds / totalSeconds) * 100.0;
    return progress.clamp(0.0, 100.0);
  }

  static double calculateMoneyProgress(
    double totalSpent,
    double totalBudget,
  ) {
    if (totalBudget <= 0) return 0.0;
    final progress = (totalSpent / totalBudget) * 100.0;
    return progress < 0.0 ? 0.0 : progress;
  }

  static bool checkIsWarning(
    double moneySpentPercentage,
    double timeElapsedPercentage, {
    double threshold = 10.0,
  }) {
    return (moneySpentPercentage - timeElapsedPercentage) > threshold;
  }

  static List<CategoryExpenseEntity> calculateCategoryExpenses(
    List<TransactionEntity> transactions,
  ) {
    if (transactions.isEmpty) return [];

    final Map<String, double> categoryAmounts = {};
    final Map<String, int> categoryCounts = {};
    double grandTotal = 0.0;

    for (final tx in transactions) {
      categoryAmounts[tx.category] =
          (categoryAmounts[tx.category] ?? 0.0) + tx.amount;
      categoryCounts[tx.category] = (categoryCounts[tx.category] ?? 0) + 1;
      grandTotal += tx.amount;
    }

    final List<CategoryExpenseEntity> result = [];
    categoryAmounts.forEach((cat, amount) {
      final percentage = grandTotal > 0 ? (amount / grandTotal) * 100.0 : 0.0;
      result.add(
        CategoryExpenseEntity(
          category: cat,
          amount: amount,
          percentage: percentage,
          count: categoryCounts[cat] ?? 0,
        ),
      );
    });

    result.sort((a, b) => b.amount.compareTo(a.amount));
    return result;
  }

  static List<TransactionEntity> filterExtraordinaryTransactions(
    List<TransactionEntity> transactions,
  ) {
    final list =
        transactions.where((tx) => tx.isExtraordinary).toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }

  static DashboardMetricsEntity buildMetrics({
    GroupEntity? group,
    List<BudgetWeekEntity>? budgetWeeks,
    required List<TransactionEntity> transactions,
    DateTime? now,
    double threshold = 10.0,
  }) {
    final currentDate = now ?? DateTime.now();

    final double totalBudget = group?.budgetTotal ??
        (budgetWeeks?.fold<double>(
                0.0, (prev, w) => prev + w.plannedAmount) ??
            0.0);

    final double totalSpent = group != null
        ? transactions.fold<double>(0.0, (prev, tx) => prev + tx.amount)
        : transactions.fold<double>(0.0, (prev, tx) => prev + tx.amount);

    final DateTime? startDate = group?.startDate ??
        (budgetWeeks != null && budgetWeeks.isNotEmpty
            ? budgetWeeks.first.startDate
            : null);
    final DateTime? endDate = group?.endDate ??
        (budgetWeeks != null && budgetWeeks.isNotEmpty
            ? budgetWeeks.last.endDate
            : null);

    final timeElapsedPercentage =
        calculateTimeProgress(startDate, endDate, currentDate);
    final moneySpentPercentage =
        calculateMoneyProgress(totalSpent, totalBudget);

    final percentageDiff = moneySpentPercentage - timeElapsedPercentage;
    final isWarning = checkIsWarning(
      moneySpentPercentage,
      timeElapsedPercentage,
      threshold: threshold,
    );

    final categoryExpenses = calculateCategoryExpenses(transactions);
    final extraordinaryTransactions =
        filterExtraordinaryTransactions(transactions);
    final totalExtraordinarySpent = extraordinaryTransactions.fold(
      0.0,
      (prev, tx) => prev + tx.amount,
    );

    int? currentWeekNumber;
    if (budgetWeeks != null && budgetWeeks.isNotEmpty) {
      for (final w in budgetWeeks) {
        if (!currentDate.isBefore(w.startDate) &&
            !currentDate.isAfter(w.endDate)) {
          currentWeekNumber = w.weekNumber;
          break;
        }
      }
      currentWeekNumber ??= budgetWeeks.first.weekNumber;
    }

    return DashboardMetricsEntity(
      groupId: group?.id,
      groupName: group?.name,
      startDate: startDate,
      endDate: endDate,
      totalBudget: totalBudget,
      totalSpent: totalSpent,
      timeElapsedPercentage: timeElapsedPercentage,
      moneySpentPercentage: moneySpentPercentage,
      thresholdPercentage: threshold,
      isWarning: isWarning,
      percentageDifference: percentageDiff,
      categoryExpenses: categoryExpenses,
      extraordinaryTransactions: extraordinaryTransactions,
      totalExtraordinarySpent: totalExtraordinarySpent,
      currentWeekNumber: currentWeekNumber,
      totalWeeks: group?.weeksCount ?? budgetWeeks?.length,
    );
  }
}

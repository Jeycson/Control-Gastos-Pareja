import '../../../transactions/domain/entities/transaction_entity.dart';
import 'category_expense_entity.dart';

class DashboardMetricsEntity {
  final String? groupId;
  final String? groupName;
  final DateTime? startDate;
  final DateTime? endDate;
  final double totalBudget;
  final double totalSpent;
  final double timeElapsedPercentage;
  final double moneySpentPercentage;
  final double thresholdPercentage;
  final bool isWarning;
  final double percentageDifference;
  final List<CategoryExpenseEntity> categoryExpenses;
  final List<TransactionEntity> extraordinaryTransactions;
  final double totalExtraordinarySpent;
  final int? currentWeekNumber;
  final int? totalWeeks;

  const DashboardMetricsEntity({
    this.groupId,
    this.groupName,
    this.startDate,
    this.endDate,
    required this.totalBudget,
    required this.totalSpent,
    required this.timeElapsedPercentage,
    required this.moneySpentPercentage,
    this.thresholdPercentage = 10.0,
    required this.isWarning,
    required this.percentageDifference,
    required this.categoryExpenses,
    required this.extraordinaryTransactions,
    required this.totalExtraordinarySpent,
    this.currentWeekNumber,
    this.totalWeeks,
  });

  DashboardMetricsEntity copyWith({
    String? groupId,
    String? groupName,
    DateTime? startDate,
    DateTime? endDate,
    double? totalBudget,
    double? totalSpent,
    double? timeElapsedPercentage,
    double? moneySpentPercentage,
    double? thresholdPercentage,
    bool? isWarning,
    double? percentageDifference,
    List<CategoryExpenseEntity>? categoryExpenses,
    List<TransactionEntity>? extraordinaryTransactions,
    double? totalExtraordinarySpent,
    int? currentWeekNumber,
    int? totalWeeks,
  }) {
    return DashboardMetricsEntity(
      groupId: groupId ?? this.groupId,
      groupName: groupName ?? this.groupName,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalBudget: totalBudget ?? this.totalBudget,
      totalSpent: totalSpent ?? this.totalSpent,
      timeElapsedPercentage:
          timeElapsedPercentage ?? this.timeElapsedPercentage,
      moneySpentPercentage:
          moneySpentPercentage ?? this.moneySpentPercentage,
      thresholdPercentage: thresholdPercentage ?? this.thresholdPercentage,
      isWarning: isWarning ?? this.isWarning,
      percentageDifference:
          percentageDifference ?? this.percentageDifference,
      categoryExpenses: categoryExpenses ?? this.categoryExpenses,
      extraordinaryTransactions:
          extraordinaryTransactions ?? this.extraordinaryTransactions,
      totalExtraordinarySpent:
          totalExtraordinarySpent ?? this.totalExtraordinarySpent,
      currentWeekNumber: currentWeekNumber ?? this.currentWeekNumber,
      totalWeeks: totalWeeks ?? this.totalWeeks,
    );
  }
}

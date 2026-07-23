class BudgetWeekEntity {
  final String id;
  final String groupId;
  final int weekNumber;
  final DateTime startDate;
  final DateTime endDate;
  final double plannedAmount;
  final double spentAmount;
  final double adjustedAmount;

  const BudgetWeekEntity({
    required this.id,
    required this.groupId,
    required this.weekNumber,
    required this.startDate,
    required this.endDate,
    required this.plannedAmount,
    required this.spentAmount,
    required this.adjustedAmount,
  });
}

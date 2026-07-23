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

  BudgetWeekEntity copyWith({
    String? id,
    String? groupId,
    int? weekNumber,
    DateTime? startDate,
    DateTime? endDate,
    double? plannedAmount,
    double? spentAmount,
    double? adjustedAmount,
  }) {
    return BudgetWeekEntity(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      weekNumber: weekNumber ?? this.weekNumber,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      plannedAmount: plannedAmount ?? this.plannedAmount,
      spentAmount: spentAmount ?? this.spentAmount,
      adjustedAmount: adjustedAmount ?? this.adjustedAmount,
    );
  }
}

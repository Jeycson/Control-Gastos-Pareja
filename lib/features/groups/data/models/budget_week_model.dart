import '../../domain/entities/budget_week_entity.dart';

class BudgetWeekModel extends BudgetWeekEntity {
  const BudgetWeekModel({
    required super.id,
    required super.groupId,
    required super.weekNumber,
    required super.startDate,
    required super.endDate,
    required super.plannedAmount,
    required super.spentAmount,
    required super.adjustedAmount,
  });

  factory BudgetWeekModel.fromJson(Map<String, dynamic> json) {
    return BudgetWeekModel(
      id: json['id'] as String,
      groupId: json['group_id'] as String,
      weekNumber: json['week_number'] as int,
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      plannedAmount: (json['planned_amount'] as num).toDouble(),
      spentAmount: (json['spent_amount'] as num).toDouble(),
      adjustedAmount: (json['adjusted_amount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'group_id': groupId,
      'week_number': weekNumber,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'planned_amount': plannedAmount,
      'spent_amount': spentAmount,
      'adjusted_amount': adjustedAmount,
    };
  }
}

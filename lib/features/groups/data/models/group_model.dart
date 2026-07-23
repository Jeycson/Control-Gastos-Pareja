import '../../domain/entities/group_entity.dart';

class GroupModel extends GroupEntity {
  const GroupModel({
    required super.id,
    required super.name,
    required super.inviteCode,
    required super.budgetTotal,
    required super.startDate,
    required super.endDate,
    required super.weeksCount,
    required super.createdBy,
    super.createdAt,
  });

  factory GroupModel.fromJson(Map<String, dynamic> json) {
    return GroupModel(
      id: json['id'] as String,
      name: json['name'] as String,
      inviteCode: json['invite_code'] as String? ?? '',
      budgetTotal: (json['budget_total'] as num).toDouble(),
      startDate: DateTime.parse(json['start_date'] as String),
      endDate: DateTime.parse(json['end_date'] as String),
      weeksCount: json['weeks_count'] as int,
      createdBy: json['created_by'] as String,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      if (inviteCode.isNotEmpty) 'invite_code': inviteCode,
      'budget_total': budgetTotal,
      'start_date': startDate.toIso8601String().split('T').first,
      'end_date': endDate.toIso8601String().split('T').first,
      'weeks_count': weeksCount,
      'created_by': createdBy,
    };
  }
}

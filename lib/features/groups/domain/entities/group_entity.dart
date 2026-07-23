class GroupEntity {
  final String id;
  final String name;
  final String inviteCode;
  final double budgetTotal;
  final DateTime startDate;
  final DateTime endDate;
  final int weeksCount;
  final String createdBy;
  final DateTime? createdAt;

  const GroupEntity({
    required this.id,
    required this.name,
    required this.inviteCode,
    required this.budgetTotal,
    required this.startDate,
    required this.endDate,
    required this.weeksCount,
    required this.createdBy,
    this.createdAt,
  });
}

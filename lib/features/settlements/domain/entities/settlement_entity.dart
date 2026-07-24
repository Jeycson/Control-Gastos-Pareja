class SettlementEntity {
  final String id;
  final String groupId;
  final String fromUserId;
  final String toUserId;
  final double amount;
  final String status;
  final DateTime? settledAt;
  final DateTime createdAt;

  const SettlementEntity({
    required this.id,
    required this.groupId,
    required this.fromUserId,
    required this.toUserId,
    required this.amount,
    required this.status,
    this.settledAt,
    required this.createdAt,
  });
}

class TransactionEntity {
  final String id;
  final String walletId;
  final String userId;
  final String? groupId;
  final double amount;
  final String category;
  final bool isShared;
  final bool isExtraordinary;
  final String description;
  final DateTime createdAt;
  final String? userName;

  const TransactionEntity({
    required this.id,
    required this.walletId,
    required this.userId,
    this.groupId,
    required this.amount,
    required this.category,
    required this.isShared,
    required this.isExtraordinary,
    required this.description,
    required this.createdAt,
    this.userName,
  });

  TransactionEntity copyWith({
    String? id,
    String? walletId,
    String? userId,
    String? groupId,
    double? amount,
    String? category,
    bool? isShared,
    bool? isExtraordinary,
    String? description,
    DateTime? createdAt,
    String? userName,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      isShared: isShared ?? this.isShared,
      isExtraordinary: isExtraordinary ?? this.isExtraordinary,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      userName: userName ?? this.userName,
    );
  }
}

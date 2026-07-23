enum WalletType {
  cash,
  card,
}

class WalletEntity {
  final String id;
  final String userId;
  final String? groupId;
  final String name;
  final WalletType type;
  final double balance;
  final bool isShared;
  final DateTime? createdAt;

  const WalletEntity({
    required this.id,
    required this.userId,
    this.groupId,
    required this.name,
    required this.type,
    required this.balance,
    required this.isShared,
    this.createdAt,
  });

  WalletEntity copyWith({
    String? id,
    String? userId,
    String? groupId,
    String? name,
    WalletType? type,
    double? balance,
    bool? isShared,
    DateTime? createdAt,
  }) {
    return WalletEntity(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      groupId: groupId ?? this.groupId,
      name: name ?? this.name,
      type: type ?? this.type,
      balance: balance ?? this.balance,
      isShared: isShared ?? this.isShared,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

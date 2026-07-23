import '../../domain/entities/wallet_entity.dart';

class WalletModel extends WalletEntity {
  const WalletModel({
    required super.id,
    required super.userId,
    super.groupId,
    required super.name,
    required super.type,
    required super.balance,
    required super.isShared,
    super.createdAt,
  });

  factory WalletModel.fromJson(Map<String, dynamic> json) {
    return WalletModel(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String?,
      name: json['name'] as String? ?? 'Billetera',
      type: json['type'] == 'card' ? WalletType.card : WalletType.cash,
      balance: (json['balance'] as num).toDouble(),
      isShared: json['is_shared'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      if (groupId != null) 'group_id': groupId,
      'name': name,
      'type': type == WalletType.card ? 'card' : 'cash',
      'balance': balance,
      'is_shared': isShared,
    };
  }

  factory WalletModel.fromEntity(WalletEntity entity) {
    return WalletModel(
      id: entity.id,
      userId: entity.userId,
      groupId: entity.groupId,
      name: entity.name,
      type: entity.type,
      balance: entity.balance,
      isShared: entity.isShared,
      createdAt: entity.createdAt,
    );
  }
}

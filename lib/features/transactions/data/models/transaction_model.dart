import '../../domain/entities/transaction_entity.dart';

class TransactionModel extends TransactionEntity {
  const TransactionModel({
    required super.id,
    required super.walletId,
    required super.userId,
    super.groupId,
    required super.amount,
    required super.category,
    required super.isShared,
    required super.isExtraordinary,
    required super.description,
    required super.createdAt,
    super.userName,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) {
    final profile = json['profiles'] as Map<String, dynamic>?;
    return TransactionModel(
      id: json['id'] as String,
      walletId: json['wallet_id'] as String,
      userId: json['user_id'] as String,
      groupId: json['group_id'] as String?,
      amount: (json['amount'] as num).toDouble(),
      category: json['category'] as String,
      isShared: json['is_shared'] as bool? ?? false,
      isExtraordinary: json['is_extraordinary'] as bool? ?? false,
      description: json['description'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String),
      userName: profile?['full_name'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wallet_id': walletId,
      'user_id': userId,
      if (groupId != null) 'group_id': groupId,
      'amount': amount,
      'category': category,
      'is_shared': isShared,
      'is_extraordinary': isExtraordinary,
      'description': description,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory TransactionModel.fromEntity(TransactionEntity entity) {
    return TransactionModel(
      id: entity.id,
      walletId: entity.walletId,
      userId: entity.userId,
      groupId: entity.groupId,
      amount: entity.amount,
      category: entity.category,
      isShared: entity.isShared,
      isExtraordinary: entity.isExtraordinary,
      description: entity.description,
      createdAt: entity.createdAt,
      userName: entity.userName,
    );
  }
}

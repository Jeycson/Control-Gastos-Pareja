import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<List<TransactionEntity>> getTransactions({
    required String userId,
    String? groupId,
  });
  Future<TransactionEntity> createTransaction(TransactionEntity transaction);
  Future<void> syncOfflineQueue();
}

import '../entities/realtime_transaction_event.dart';
import '../entities/transaction_entity.dart';

abstract class TransactionRepository {
  Future<List<TransactionEntity>> getTransactions({
    required String userId,
    String? groupId,
  });
  Future<TransactionEntity> createTransaction(TransactionEntity transaction);
  Future<void> syncOfflineQueue();
  Stream<RealtimeTransactionEvent> subscribeToGroupTransactions(String groupId);
}

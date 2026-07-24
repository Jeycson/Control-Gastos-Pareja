import '../entities/realtime_transaction_event.dart';
import '../repositories/transaction_repository.dart';

class SubscribeGroupTransactionsUseCase {
  final TransactionRepository repository;

  SubscribeGroupTransactionsUseCase(this.repository);

  Stream<RealtimeTransactionEvent> call(String groupId) {
    return repository.subscribeToGroupTransactions(groupId);
  }
}

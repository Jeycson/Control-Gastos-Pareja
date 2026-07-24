import 'transaction_entity.dart';

enum RealtimeEventType { insert, update, delete }

class RealtimeTransactionEvent {
  final RealtimeEventType type;
  final TransactionEntity transaction;

  const RealtimeTransactionEvent({
    required this.type,
    required this.transaction,
  });
}

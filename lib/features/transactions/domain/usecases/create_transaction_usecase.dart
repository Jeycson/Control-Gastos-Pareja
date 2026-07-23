import '../../../../core/usecases/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class CreateTransactionUseCase
    implements UseCase<TransactionEntity, TransactionEntity> {
  final TransactionRepository repository;

  CreateTransactionUseCase(this.repository);

  @override
  Future<TransactionEntity> call(TransactionEntity transaction) {
    return repository.createTransaction(transaction);
  }
}

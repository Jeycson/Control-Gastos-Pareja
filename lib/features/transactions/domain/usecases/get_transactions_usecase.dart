import '../../../../core/usecases/usecase.dart';
import '../entities/transaction_entity.dart';
import '../repositories/transaction_repository.dart';

class GetTransactionsParams {
  final String userId;
  final String? groupId;

  const GetTransactionsParams({
    required this.userId,
    this.groupId,
  });
}

class GetTransactionsUseCase
    implements UseCase<List<TransactionEntity>, GetTransactionsParams> {
  final TransactionRepository repository;

  GetTransactionsUseCase(this.repository);

  @override
  Future<List<TransactionEntity>> call(GetTransactionsParams params) {
    return repository.getTransactions(
      userId: params.userId,
      groupId: params.groupId,
    );
  }
}

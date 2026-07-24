import '../../../../core/usecases/usecase.dart';
import '../entities/settlement_payment.dart';
import '../repositories/settlement_repository.dart';

class MarkSettlementPaidParams {
  final String groupId;
  final SettlementPayment payment;

  const MarkSettlementPaidParams({
    required this.groupId,
    required this.payment,
  });
}

class MarkSettlementPaidUseCase
    implements UseCase<void, MarkSettlementPaidParams> {
  final SettlementRepository repository;

  MarkSettlementPaidUseCase(this.repository);

  @override
  Future<void> call(MarkSettlementPaidParams params) {
    return repository.markAsPaid(
      groupId: params.groupId,
      payment: params.payment,
    );
  }
}

import '../../../../core/usecases/usecase.dart';
import '../entities/member_balance.dart';
import '../entities/settlement_payment.dart';
import '../repositories/settlement_repository.dart';

class SettlementsSummary {
  final List<MemberBalance> memberBalances;
  final List<SettlementPayment> payments;

  const SettlementsSummary({
    required this.memberBalances,
    required this.payments,
  });
}

class GetSettlementsSummaryUseCase
    implements UseCase<SettlementsSummary, String> {
  final SettlementRepository repository;

  GetSettlementsSummaryUseCase(this.repository);

  @override
  Future<SettlementsSummary> call(String groupId) async {
    final balances = await repository.getGroupMemberBalances(groupId);
    final payments = await repository.getGroupSettlementPayments(groupId);

    return SettlementsSummary(
      memberBalances: balances,
      payments: payments,
    );
  }
}

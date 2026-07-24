import '../entities/member_balance.dart';
import '../entities/settlement_payment.dart';

abstract class SettlementRepository {
  Future<List<MemberBalance>> getGroupMemberBalances(String groupId);
  Future<List<SettlementPayment>> getGroupSettlementPayments(String groupId);
  Future<void> markAsPaid({
    required String groupId,
    required SettlementPayment payment,
  });
}

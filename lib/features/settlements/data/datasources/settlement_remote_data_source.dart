import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/member_balance.dart';
import '../../domain/entities/settlement_payment.dart';
import '../../domain/services/settlement_calculator.dart';

abstract class SettlementRemoteDataSource {
  Future<List<MemberBalance>> getGroupMemberBalances(String groupId);
  Future<List<SettlementPayment>> getGroupSettlementPayments(String groupId);
  Future<void> markAsPaid({
    required String groupId,
    required SettlementPayment payment,
  });
}

class SettlementRemoteDataSourceImpl implements SettlementRemoteDataSource {
  final SupabaseClient supabaseClient;

  SettlementRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<MemberBalance>> getGroupMemberBalances(String groupId) async {
    // 1. Fetch group members with profiles
    final membersResponse = await supabaseClient
        .from('group_members')
        .select('user_id, profiles(full_name)')
        .eq('group_id', groupId);

    final members = (membersResponse as List<dynamic>).map((m) {
      final profile = m['profiles'] as Map<String, dynamic>? ?? {};
      return {
        'userId': m['user_id'] as String,
        'userName': profile['full_name'] as String? ?? 'Usuario',
      };
    }).toList();

    // 2. Fetch shared transactions for group
    final txResponse = await supabaseClient
        .from('transactions')
        .select('user_id, amount')
        .eq('group_id', groupId)
        .eq('is_shared', true);

    final sharedTxs = (txResponse as List<dynamic>).map((tx) {
      return {
        'userId': tx['user_id'] as String,
        'amount': (tx['amount'] as num).toDouble(),
      };
    }).toList();

    return SettlementCalculator.calculateMemberBalances(
      members: members,
      sharedTransactions: sharedTxs,
    );
  }

  @override
  Future<List<SettlementPayment>> getGroupSettlementPayments(
    String groupId,
  ) async {
    final balances = await getGroupMemberBalances(groupId);
    return SettlementCalculator.calculateSettlements(balances);
  }

  @override
  Future<void> markAsPaid({
    required String groupId,
    required SettlementPayment payment,
  }) async {
    await supabaseClient.from('settlements').insert({
      'group_id': groupId,
      'from_user_id': payment.fromUserId,
      'to_user_id': payment.toUserId,
      'amount': payment.amount,
      'status': 'settled',
      'settled_at': DateTime.now().toIso8601String(),
    });
  }
}

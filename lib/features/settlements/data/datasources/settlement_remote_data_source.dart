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
    String? fromWalletId,
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

    // 3. Fetch settled payments for group
    final settledResponse = await supabaseClient
        .from('settlements')
        .select('from_user_id, to_user_id, amount')
        .eq('group_id', groupId)
        .eq('status', 'settled');

    final settledPayments = (settledResponse as List<dynamic>).map((s) {
      return {
        'fromUserId': s['from_user_id'] as String,
        'toUserId': s['to_user_id'] as String,
        'amount': (s['amount'] as num).toDouble(),
      };
    }).toList();

    return SettlementCalculator.calculateMemberBalances(
      members: members,
      sharedTransactions: sharedTxs,
      settledPayments: settledPayments,
    );
  }

  @override
  Future<List<SettlementPayment>> getGroupSettlementPayments(
    String groupId,
  ) async {
    final balances = await getGroupMemberBalances(groupId);
    final calculatedPayments = SettlementCalculator.calculateSettlements(balances);

    // Also fetch pending settlements explicitly created in database
    final pendingResp = await supabaseClient
        .from('settlements')
        .select('from_user_id, to_user_id, amount, profiles!settlements_from_user_id_fkey(full_name)')
        .eq('group_id', groupId)
        .eq('status', 'pending');

    final pendingPayments = <SettlementPayment>[];
    for (final item in (pendingResp as List<dynamic>)) {
      final fromId = item['from_user_id'] as String;
      final toId = item['to_user_id'] as String;
      final amt = (item['amount'] as num).toDouble();
      pendingPayments.add(
        SettlementPayment(
          fromUserId: fromId,
          fromUserName: 'Miembro',
          toUserId: toId,
          toUserName: 'Pagador',
          amount: amt,
        ),
      );
    }

    final allPayments = [...calculatedPayments];
    for (final p in pendingPayments) {
      if (!allPayments.any((existing) =>
          existing.fromUserId == p.fromUserId &&
          existing.toUserId == p.toUserId &&
          existing.amount == p.amount)) {
        allPayments.add(p);
      }
    }

    return allPayments;
  }

  @override
  Future<void> markAsPaid({
    required String groupId,
    required SettlementPayment payment,
    String? fromWalletId,
  }) async {
    await supabaseClient.from('settlements').insert({
      'group_id': groupId,
      'from_user_id': payment.fromUserId,
      'to_user_id': payment.toUserId,
      'amount': payment.amount,
      'status': 'settled',
      'settled_at': DateTime.now().toIso8601String(),
    });

    if (fromWalletId != null && fromWalletId.isNotEmpty) {
      final walletResp = await supabaseClient
          .from('wallets')
          .select('balance')
          .eq('id', fromWalletId)
          .maybeSingle();

      if (walletResp != null) {
        final currentBalance = (walletResp['balance'] as num).toDouble();
        final newBalance = currentBalance - payment.amount;
        await supabaseClient
            .from('wallets')
            .update({'balance': newBalance})
            .eq('id', fromWalletId);

        // Record a transaction for the payer's personal history
        await supabaseClient.from('transactions').insert({
          'wallet_id': fromWalletId,
          'user_id': payment.fromUserId,
          'group_id': groupId,
          'amount': payment.amount,
          'category': 'Otros',
          'is_shared': false,
          'is_full_payment': false,
          'is_extraordinary': false,
          'description': 'Ajuste Cuentas Claras para ${payment.toUserName}',
          'created_at': DateTime.now().toIso8601String(),
        });
      }
    }
  }
}

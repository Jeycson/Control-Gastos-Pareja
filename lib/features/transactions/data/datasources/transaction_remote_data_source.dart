import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/transaction_model.dart';

abstract class TransactionRemoteDataSource {
  Future<List<TransactionModel>> getTransactions({
    required String userId,
    String? groupId,
  });
  Future<TransactionModel> createTransaction(TransactionModel transaction);
}

class TransactionRemoteDataSourceImpl implements TransactionRemoteDataSource {
  final SupabaseClient supabaseClient;

  TransactionRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<TransactionModel>> getTransactions({
    required String userId,
    String? groupId,
  }) async {
    var query = supabaseClient
        .from('transactions')
        .select('*, profiles(full_name)');

    if (groupId != null && groupId.isNotEmpty) {
      query = query.eq('group_id', groupId);
    } else {
      try {
        final userGroupsResp = await supabaseClient
            .from('group_members')
            .select('group_id')
            .eq('user_id', userId);

        final groupIds = (userGroupsResp as List<dynamic>)
            .map((g) => g['group_id'] as String)
            .where((id) => id.isNotEmpty)
            .toList();

        if (groupIds.isNotEmpty) {
          final groupFilters = groupIds.map((id) => 'group_id.eq.$id').join(',');
          query = query.or('user_id.eq.$userId,$groupFilters');
        } else {
          query = query.eq('user_id', userId);
        }
      } catch (_) {
        query = query.eq('user_id', userId);
      }
    }

    final response = await query.order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => TransactionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<TransactionModel> createTransaction(TransactionModel transaction) async {
    try {
      // Attempt Atomic PostgreSQL RPC call to avoid race conditions
      final rpcResult = await supabaseClient.rpc(
        'register_transaction_atomic',
        params: {
          'p_id': transaction.id,
          'p_wallet_id': transaction.walletId,
          'p_user_id': transaction.userId,
          'p_group_id': transaction.groupId,
          'p_amount': transaction.amount,
          'p_category': transaction.category,
          'p_is_shared': transaction.isShared,
          'p_is_full_payment': transaction.isFullPayment,
          'p_is_extraordinary': transaction.isExtraordinary,
          'p_description': transaction.description,
          'p_created_at': transaction.createdAt.toIso8601String(),
        },
      );

      if (rpcResult != null) {
        return TransactionModel.fromJson(Map<String, dynamic>.from(rpcResult as Map));
      }
    } catch (_) {
      // Fallback to client multi-query if RPC function is not yet created in PostgreSQL
    }

    // 1. Insert transaction into Supabase
    final response = await supabaseClient
        .from('transactions')
        .insert(transaction.toJson())
        .select('*, profiles(full_name)')
        .single();

    final createdModel = TransactionModel.fromJson(response);

    // 2. Deduct amount from payer's wallet
    final walletResp = await supabaseClient
        .from('wallets')
        .select('balance')
        .eq('id', transaction.walletId)
        .maybeSingle();

    if (walletResp != null) {
      final currentBalance = (walletResp['balance'] as num).toDouble();
      final newBalance = currentBalance - transaction.amount;
      await supabaseClient
          .from('wallets')
          .update({'balance': newBalance})
          .eq('id', transaction.walletId);
    }

    // 3. If is_shared == true, isFullPayment == true and groupId is present, generate pending settlements for other members
    if (transaction.isShared && transaction.groupId != null) {
      if (transaction.isFullPayment) {
        final membersResp = await supabaseClient
            .from('group_members')
            .select('user_id')
            .eq('group_id', transaction.groupId!);

        final members = membersResp as List<dynamic>;
        if (members.length > 1) {
          final share = transaction.amount / members.length;
          final settlementsPayload = <Map<String, dynamic>>[];
          for (final m in members) {
            final uid = m['user_id'] as String;
            if (uid != transaction.userId) {
              settlementsPayload.add({
                'group_id': transaction.groupId,
                'from_user_id': uid,
                'to_user_id': transaction.userId,
                'amount': share,
                'status': 'pending',
              });
            }
          }
          if (settlementsPayload.isNotEmpty) {
            await supabaseClient.from('settlements').insert(settlementsPayload);
          }
        }
      } else {
        // Shared expense divided automatically across budget weeks
        final dateStr = transaction.createdAt.toIso8601String().split('T').first;

        final weekResp = await supabaseClient
            .from('budget_weeks')
            .select('id, spent_amount')
            .eq('group_id', transaction.groupId!)
            .lte('start_date', dateStr)
            .gte('end_date', dateStr)
            .maybeSingle();

        if (weekResp != null) {
          final weekId = weekResp['id'] as String;
          final currentSpent = (weekResp['spent_amount'] as num).toDouble();
          final newSpent = currentSpent + transaction.amount;

          await supabaseClient
              .from('budget_weeks')
              .update({'spent_amount': newSpent})
              .eq('id', weekId);
        }
      }
    }

    return createdModel;
  }
}

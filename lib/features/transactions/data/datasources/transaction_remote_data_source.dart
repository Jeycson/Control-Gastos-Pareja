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
      query = query.eq('user_id', userId);
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

    // 3. If is_shared == true and groupId is present, increment spent_amount in budget_week
    if (transaction.isShared && transaction.groupId != null) {
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

    return createdModel;
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/wallet_model.dart';

abstract class WalletRemoteDataSource {
  Future<List<WalletModel>> getWallets(String userId);
  Future<WalletModel> createWallet(WalletModel wallet);
  Future<void> updateBalance({
    required String walletId,
    required double newBalance,
  });
  Future<void> deleteWallet(String walletId);
}

class WalletRemoteDataSourceImpl implements WalletRemoteDataSource {
  final SupabaseClient supabaseClient;

  WalletRemoteDataSourceImpl(this.supabaseClient);

  @override
  Future<List<WalletModel>> getWallets(String userId) async {
    final response = await supabaseClient
        .from('wallets')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (response as List<dynamic>)
        .map((json) => WalletModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<WalletModel> createWallet(WalletModel wallet) async {
    final response = await supabaseClient
        .from('wallets')
        .insert(wallet.toJson())
        .select()
        .single();

    return WalletModel.fromJson(response);
  }

  @override
  Future<void> updateBalance({
    required String walletId,
    required double newBalance,
  }) async {
    await supabaseClient
        .from('wallets')
        .update({'balance': newBalance})
        .eq('id', walletId);
  }

  @override
  Future<void> deleteWallet(String walletId) async {
    await supabaseClient.from('wallets').delete().eq('id', walletId);
  }
}

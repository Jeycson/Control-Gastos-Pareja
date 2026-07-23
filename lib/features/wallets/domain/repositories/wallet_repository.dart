import '../entities/wallet_entity.dart';

abstract class WalletRepository {
  Future<List<WalletEntity>> getWallets(String userId);
  Future<WalletEntity> createWallet(WalletEntity wallet);
  Future<void> updateBalance({
    required String walletId,
    required double newBalance,
  });
  Future<void> deleteWallet(String walletId);
}

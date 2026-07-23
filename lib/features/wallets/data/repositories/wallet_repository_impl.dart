import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../datasources/wallet_remote_data_source.dart';
import '../models/wallet_model.dart';

class WalletRepositoryImpl implements WalletRepository {
  final WalletRemoteDataSource remoteDataSource;

  WalletRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<WalletEntity>> getWallets(String userId) async {
    try {
      return await remoteDataSource.getWallets(userId);
    } catch (e) {
      throw ServerException(message: 'Error al obtener las billeteras: $e');
    }
  }

  @override
  Future<WalletEntity> createWallet(WalletEntity wallet) async {
    try {
      final model = WalletModel.fromEntity(wallet);
      return await remoteDataSource.createWallet(model);
    } catch (e) {
      throw ServerException(message: 'Error al crear la billetera: $e');
    }
  }

  @override
  Future<void> updateBalance({
    required String walletId,
    required double newBalance,
  }) async {
    try {
      await remoteDataSource.updateBalance(
        walletId: walletId,
        newBalance: newBalance,
      );
    } catch (e) {
      throw ServerException(message: 'Error al actualizar el saldo: $e');
    }
  }

  @override
  Future<void> deleteWallet(String walletId) async {
    try {
      await remoteDataSource.deleteWallet(walletId);
    } catch (e) {
      throw ServerException(message: 'Error al eliminar la billetera: $e');
    }
  }
}

import '../../../../core/usecases/usecase.dart';
import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class CreateWalletUseCase implements UseCase<WalletEntity, WalletEntity> {
  final WalletRepository repository;

  CreateWalletUseCase(this.repository);

  @override
  Future<WalletEntity> call(WalletEntity wallet) {
    return repository.createWallet(wallet);
  }
}

import '../../../../core/usecases/usecase.dart';
import '../repositories/wallet_repository.dart';

class DeleteWalletUseCase implements UseCase<void, String> {
  final WalletRepository repository;

  DeleteWalletUseCase(this.repository);

  @override
  Future<void> call(String walletId) {
    return repository.deleteWallet(walletId);
  }
}

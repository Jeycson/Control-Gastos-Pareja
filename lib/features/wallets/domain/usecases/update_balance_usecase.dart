import '../../../../core/usecases/usecase.dart';
import '../repositories/wallet_repository.dart';

class UpdateBalanceParams {
  final String walletId;
  final double newBalance;

  const UpdateBalanceParams({
    required this.walletId,
    required this.newBalance,
  });
}

class UpdateBalanceUseCase implements UseCase<void, UpdateBalanceParams> {
  final WalletRepository repository;

  UpdateBalanceUseCase(this.repository);

  @override
  Future<void> call(UpdateBalanceParams params) {
    return repository.updateBalance(
      walletId: params.walletId,
      newBalance: params.newBalance,
    );
  }
}

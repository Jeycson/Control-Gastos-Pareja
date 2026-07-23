import '../../../../core/usecases/usecase.dart';
import '../entities/wallet_entity.dart';
import '../repositories/wallet_repository.dart';

class GetWalletsUseCase implements UseCase<List<WalletEntity>, String> {
  final WalletRepository repository;

  GetWalletsUseCase(this.repository);

  @override
  Future<List<WalletEntity>> call(String userId) {
    return repository.getWallets(userId);
  }
}

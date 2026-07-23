import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../data/datasources/wallet_remote_data_source.dart';
import '../../data/repositories/wallet_repository_impl.dart';
import '../../domain/entities/wallet_entity.dart';
import '../../domain/repositories/wallet_repository.dart';
import '../../domain/usecases/create_wallet_usecase.dart';
import '../../domain/usecases/delete_wallet_usecase.dart';
import '../../domain/usecases/get_wallets_usecase.dart';
import '../../domain/usecases/update_balance_usecase.dart';

final walletRemoteDataSourceProvider = Provider<WalletRemoteDataSource>((ref) {
  return WalletRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepositoryImpl(ref.watch(walletRemoteDataSourceProvider));
});

final getWalletsUseCaseProvider = Provider<GetWalletsUseCase>((ref) {
  return GetWalletsUseCase(ref.watch(walletRepositoryProvider));
});

final createWalletUseCaseProvider = Provider<CreateWalletUseCase>((ref) {
  return CreateWalletUseCase(ref.watch(walletRepositoryProvider));
});

final updateBalanceUseCaseProvider = Provider<UpdateBalanceUseCase>((ref) {
  return UpdateBalanceUseCase(ref.watch(walletRepositoryProvider));
});

final deleteWalletUseCaseProvider = Provider<DeleteWalletUseCase>((ref) {
  return DeleteWalletUseCase(ref.watch(walletRepositoryProvider));
});

class WalletsState {
  final bool isLoading;
  final List<WalletEntity> wallets;
  final String? errorMessage;

  const WalletsState({
    required this.isLoading,
    required this.wallets,
    this.errorMessage,
  });

  factory WalletsState.initial() => const WalletsState(
        isLoading: false,
        wallets: [],
      );

  WalletsState copyWith({
    bool? isLoading,
    List<WalletEntity>? wallets,
    String? errorMessage,
  }) {
    return WalletsState(
      isLoading: isLoading ?? this.isLoading,
      wallets: wallets ?? this.wallets,
      errorMessage: errorMessage,
    );
  }
}

class WalletsNotifier extends StateNotifier<WalletsState> {
  final GetWalletsUseCase getWalletsUseCase;
  final CreateWalletUseCase createWalletUseCase;
  final UpdateBalanceUseCase updateBalanceUseCase;
  final DeleteWalletUseCase deleteWalletUseCase;
  final Ref ref;

  WalletsNotifier({
    required this.getWalletsUseCase,
    required this.createWalletUseCase,
    required this.updateBalanceUseCase,
    required this.deleteWalletUseCase,
    required this.ref,
  }) : super(WalletsState.initial());

  Future<void> loadWallets() async {
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;
    if (user == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final wallets = await getWalletsUseCase(user.id);
      state = state.copyWith(isLoading: false, wallets: wallets);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> createWallet({
    required String name,
    required WalletType type,
    required double initialBalance,
    bool isShared = false,
  }) async {
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;
    if (user == null) return false;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final newWallet = WalletEntity(
        id: '',
        userId: user.id,
        name: name,
        type: type,
        balance: initialBalance,
        isShared: isShared,
      );
      await createWalletUseCase(newWallet);
      await loadWallets();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> updateBalance({
    required String walletId,
    required double newBalance,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await updateBalanceUseCase(
        UpdateBalanceParams(walletId: walletId, newBalance: newBalance),
      );
      await loadWallets();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> deleteWallet(String walletId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await deleteWalletUseCase(walletId);
      await loadWallets();
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final walletsNotifierProvider =
    StateNotifierProvider<WalletsNotifier, WalletsState>((ref) {
  return WalletsNotifier(
    getWalletsUseCase: ref.watch(getWalletsUseCaseProvider),
    createWalletUseCase: ref.watch(createWalletUseCaseProvider),
    updateBalanceUseCase: ref.watch(updateBalanceUseCaseProvider),
    deleteWalletUseCase: ref.watch(deleteWalletUseCaseProvider),
    ref: ref,
  );
});

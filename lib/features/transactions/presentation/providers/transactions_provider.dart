import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/network/supabase_client.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/domain/services/dashboard_calculator.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../groups/domain/entities/group_entity.dart';
import '../../../wallets/presentation/providers/wallets_provider.dart';
import '../../data/datasources/transaction_realtime_data_source.dart';
import '../../data/datasources/transaction_remote_data_source.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../domain/entities/realtime_transaction_event.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/usecases/create_transaction_usecase.dart';
import '../../domain/usecases/get_transactions_usecase.dart';
import '../../domain/usecases/subscribe_group_transactions_usecase.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('Initialize SharedPreferences in main.dart');
});

final connectivityProvider = Provider<Connectivity>((ref) {
  return Connectivity();
});

final transactionRemoteDataSourceProvider =
    Provider<TransactionRemoteDataSource>((ref) {
  return TransactionRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final transactionRealtimeDataSourceProvider =
    Provider<TransactionRealtimeDataSource>((ref) {
  return TransactionRealtimeDataSourceImpl(ref.watch(supabaseClientProvider));
});

final transactionRepositoryProvider = Provider<TransactionRepository>((ref) {
  return TransactionRepositoryImpl(
    remoteDataSource: ref.watch(transactionRemoteDataSourceProvider),
    realtimeDataSource: ref.watch(transactionRealtimeDataSourceProvider),
    connectivity: ref.watch(connectivityProvider),
    prefs: ref.watch(sharedPreferencesProvider),
  );
});

final getTransactionsUseCaseProvider = Provider<GetTransactionsUseCase>((ref) {
  return GetTransactionsUseCase(ref.watch(transactionRepositoryProvider));
});

final createTransactionUseCaseProvider =
    Provider<CreateTransactionUseCase>((ref) {
  return CreateTransactionUseCase(ref.watch(transactionRepositoryProvider));
});

final subscribeGroupTransactionsUseCaseProvider =
    Provider<SubscribeGroupTransactionsUseCase>((ref) {
  return SubscribeGroupTransactionsUseCase(
      ref.watch(transactionRepositoryProvider));
});

class TransactionsState {
  final bool isLoading;
  final List<TransactionEntity> transactions;
  final String? selectedCategory;
  final String? selectedUser;
  final bool onlyExtraordinary;
  final String? errorMessage;

  const TransactionsState({
    required this.isLoading,
    required this.transactions,
    this.selectedCategory,
    this.selectedUser,
    this.onlyExtraordinary = false,
    this.errorMessage,
  });

  factory TransactionsState.initial() => const TransactionsState(
        isLoading: false,
        transactions: [],
      );

  List<TransactionEntity> get filteredTransactions {
    return transactions.where((tx) {
      if (selectedCategory != null &&
          selectedCategory!.isNotEmpty &&
          tx.category != selectedCategory) {
        return false;
      }
      if (selectedUser != null &&
          selectedUser!.isNotEmpty &&
          tx.userId != selectedUser &&
          tx.userName != selectedUser) {
        return false;
      }
      if (onlyExtraordinary && !tx.isExtraordinary) {
        return false;
      }
      return true;
    }).toList();
  }

  TransactionsState copyWith({
    bool? isLoading,
    List<TransactionEntity>? transactions,
    String? selectedCategory,
    String? selectedUser,
    bool? onlyExtraordinary,
    String? errorMessage,
  }) {
    return TransactionsState(
      isLoading: isLoading ?? this.isLoading,
      transactions: transactions ?? this.transactions,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      selectedUser: selectedUser ?? this.selectedUser,
      onlyExtraordinary: onlyExtraordinary ?? this.onlyExtraordinary,
      errorMessage: errorMessage,
    );
  }
}

class TransactionsNotifier extends StateNotifier<TransactionsState> {
  final GetTransactionsUseCase getTransactionsUseCase;
  final CreateTransactionUseCase createTransactionUseCase;
  final Ref ref;

  TransactionsNotifier({
    required this.getTransactionsUseCase,
    required this.createTransactionUseCase,
    required this.ref,
  }) : super(TransactionsState.initial());

  Future<void> loadTransactions({String? groupId}) async {
    final authState = ref.read(authNotifierProvider);
    final user = authState.user;
    if (user == null) return;

    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final list = await getTransactionsUseCase(
        GetTransactionsParams(userId: user.id, groupId: groupId),
      );
      state = state.copyWith(isLoading: false, transactions: list);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  /// Upsert transaction in-place without triggering full screen reload
  void upsertTransaction(TransactionEntity transaction) {
    final list = List<TransactionEntity>.from(state.transactions);
    final index = list.indexWhere((tx) => tx.id == transaction.id);

    if (index >= 0) {
      list[index] = transaction;
    } else {
      list.insert(0, transaction);
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }

    state = state.copyWith(transactions: list);
  }

  void removeTransaction(String id) {
    final list = state.transactions.where((tx) => tx.id != id).toList();
    state = state.copyWith(transactions: list);
  }

  /// Optimistic Update with automatic Rollback on failure
  Future<bool> addTransaction(TransactionEntity transaction) async {
    final previousState = state;

    final optimisticList = [transaction, ...state.transactions];
    state = state.copyWith(transactions: optimisticList, errorMessage: null);

    try {
      final created = await createTransactionUseCase(transaction);

      final updatedList = state.transactions.map((tx) {
        return tx.id == transaction.id ? created : tx;
      }).toList();

      state = state.copyWith(transactions: updatedList);

      unawaited(ref.read(walletsNotifierProvider.notifier).loadWallets());

      return true;
    } catch (e) {
      state = previousState.copyWith(
        errorMessage: 'Error al registrar la transacción. Se realizó rollback.',
      );
      return false;
    }
  }

  void setCategoryFilter(String? category) {
    if (state.selectedCategory == category) {
      state = state.copyWith(selectedCategory: null);
    } else {
      state = state.copyWith(selectedCategory: category);
    }
  }

  void setUserFilter(String? user) {
    if (state.selectedUser == user) {
      state = state.copyWith(selectedUser: null);
    } else {
      state = state.copyWith(selectedUser: user);
    }
  }

  void toggleOnlyExtraordinary() {
    state = state.copyWith(onlyExtraordinary: !state.onlyExtraordinary);
  }
}

final transactionsNotifierProvider =
    StateNotifierProvider<TransactionsNotifier, TransactionsState>((ref) {
  return TransactionsNotifier(
    getTransactionsUseCase: ref.watch(getTransactionsUseCaseProvider),
    createTransactionUseCase: ref.watch(createTransactionUseCaseProvider),
    ref: ref,
  );
});

final realtimeGroupTransactionsProvider =
    StreamProvider.family<RealtimeTransactionEvent, String>((ref, groupId) {
  final subscribeUseCase =
      ref.watch(subscribeGroupTransactionsUseCaseProvider);
  final stream = subscribeUseCase(groupId);

  stream.listen((event) {
    // 1. Update TransactionsNotifier state incrementally without reloading
    if (event.type == RealtimeEventType.delete) {
      ref
          .read(transactionsNotifierProvider.notifier)
          .removeTransaction(event.transaction.id);
    } else {
      ref
          .read(transactionsNotifierProvider.notifier)
          .upsertTransaction(event.transaction);
    }

    // 2. Incrementally update DashboardNotifier if metrics loaded
    final currentMetrics =
        ref.read(dashboardNotifierProvider(groupId)).valueOrNull;
    if (currentMetrics != null) {
      final updatedTxs = List<TransactionEntity>.from(
        ref.read(transactionsNotifierProvider).transactions,
      );
      final newMetrics = DashboardCalculator.buildMetrics(
        group: currentMetrics.groupId != null
            ? GroupEntity(
                id: currentMetrics.groupId!,
                name: currentMetrics.groupName ?? '',
                inviteCode: '',
                budgetTotal: currentMetrics.totalBudget,
                startDate: currentMetrics.startDate ?? DateTime.now(),
                endDate: currentMetrics.endDate ?? DateTime.now(),
                weeksCount: currentMetrics.totalWeeks ?? 1,
                createdBy: '',
              )
            : null,
        transactions: updatedTxs,
        threshold: currentMetrics.thresholdPercentage,
      );
      ref
          .read(dashboardNotifierProvider(groupId).notifier)
          .updateMetrics(newMetrics);
    }

    // 3. Keep wallets balance updated
    unawaited(ref.read(walletsNotifierProvider.notifier).loadWallets());
  });

  return stream;
});

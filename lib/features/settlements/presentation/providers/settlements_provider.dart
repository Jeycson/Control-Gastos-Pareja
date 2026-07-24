import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/supabase_client.dart';
import '../../data/datasources/settlement_remote_data_source.dart';
import '../../data/repositories/settlement_repository_impl.dart';
import '../../domain/entities/member_balance.dart';
import '../../domain/entities/settlement_payment.dart';
import '../../domain/repositories/settlement_repository.dart';
import '../../domain/usecases/get_settlements_summary_usecase.dart';
import '../../domain/usecases/mark_settlement_paid_usecase.dart';

final settlementRemoteDataSourceProvider =
    Provider<SettlementRemoteDataSource>((ref) {
  return SettlementRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final settlementRepositoryProvider = Provider<SettlementRepository>((ref) {
  return SettlementRepositoryImpl(
      ref.watch(settlementRemoteDataSourceProvider));
});

final getSettlementsSummaryUseCaseProvider =
    Provider<GetSettlementsSummaryUseCase>((ref) {
  return GetSettlementsSummaryUseCase(ref.watch(settlementRepositoryProvider));
});

final markSettlementPaidUseCaseProvider =
    Provider<MarkSettlementPaidUseCase>((ref) {
  return MarkSettlementPaidUseCase(ref.watch(settlementRepositoryProvider));
});

class SettlementsState {
  final bool isLoading;
  final List<MemberBalance> memberBalances;
  final List<SettlementPayment> payments;
  final String? errorMessage;

  const SettlementsState({
    required this.isLoading,
    required this.memberBalances,
    required this.payments,
    this.errorMessage,
  });

  factory SettlementsState.initial() => const SettlementsState(
        isLoading: false,
        memberBalances: [],
        payments: [],
      );

  SettlementsState copyWith({
    bool? isLoading,
    List<MemberBalance>? memberBalances,
    List<SettlementPayment>? payments,
    String? errorMessage,
  }) {
    return SettlementsState(
      isLoading: isLoading ?? this.isLoading,
      memberBalances: memberBalances ?? this.memberBalances,
      payments: payments ?? this.payments,
      errorMessage: errorMessage,
    );
  }
}

class SettlementsNotifier extends StateNotifier<SettlementsState> {
  final GetSettlementsSummaryUseCase getSettlementsSummaryUseCase;
  final MarkSettlementPaidUseCase markSettlementPaidUseCase;

  SettlementsNotifier({
    required this.getSettlementsSummaryUseCase,
    required this.markSettlementPaidUseCase,
  }) : super(SettlementsState.initial());

  Future<void> loadSettlements(String groupId) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final summary = await getSettlementsSummaryUseCase(groupId);
      state = state.copyWith(
        isLoading: false,
        memberBalances: summary.memberBalances,
        payments: summary.payments,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }

  Future<bool> markAsPaid({
    required String groupId,
    required SettlementPayment payment,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await markSettlementPaidUseCase(
        MarkSettlementPaidParams(groupId: groupId, payment: payment),
      );
      await loadSettlements(groupId);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }
}

final settlementsNotifierProvider =
    StateNotifierProvider<SettlementsNotifier, SettlementsState>((ref) {
  return SettlementsNotifier(
    getSettlementsSummaryUseCase:
        ref.watch(getSettlementsSummaryUseCaseProvider),
    markSettlementPaidUseCase: ref.watch(markSettlementPaidUseCaseProvider),
  );
});

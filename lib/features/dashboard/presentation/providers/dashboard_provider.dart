import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../groups/presentation/providers/groups_provider.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../domain/entities/category_expense_entity.dart';
import '../../domain/entities/dashboard_metrics_entity.dart';
import '../../domain/usecases/get_dashboard_data_usecase.dart';

final getDashboardDataUseCaseProvider =
    Provider<GetDashboardDataUseCase>((ref) {
  return GetDashboardDataUseCase(
    groupRepository: ref.watch(groupRepositoryProvider),
    transactionRepository: ref.watch(transactionRepositoryProvider),
  );
});

class DashboardNotifier
    extends StateNotifier<AsyncValue<DashboardMetricsEntity>> {
  final GetDashboardDataUseCase getDashboardDataUseCase;
  final Ref ref;
  final String? groupId;

  DashboardNotifier({
    required this.getDashboardDataUseCase,
    required this.ref,
    required this.groupId,
  }) : super(const AsyncValue.loading()) {
    loadDashboard();
  }

  Future<void> loadDashboard({bool isRefresh = false}) async {
    final user = ref.read(authNotifierProvider).user;
    if (user == null) {
      state = const AsyncValue.error('Usuario no autenticado', StackTrace.empty);
      return;
    }

    if (!isRefresh && state.hasValue) {
      return;
    }

    if (isRefresh || !state.hasValue) {
      state = const AsyncValue.loading();
    }

    try {
      final metrics = await getDashboardDataUseCase(
        GetDashboardDataParams(groupId: groupId, userId: user.id),
      );
      state = AsyncValue.data(metrics);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  void updateMetrics(DashboardMetricsEntity metrics) {
    state = AsyncValue.data(metrics);
  }
}

final dashboardNotifierProvider = StateNotifierProvider.family<
    DashboardNotifier, AsyncValue<DashboardMetricsEntity>, String?>((ref, groupId) {
  return DashboardNotifier(
    getDashboardDataUseCase: ref.watch(getDashboardDataUseCaseProvider),
    ref: ref,
    groupId: groupId,
  );
});

class DashboardProgressMetrics {
  final double timeElapsedPercentage;
  final double moneySpentPercentage;
  final bool isWarning;
  final double percentageDifference;
  final double totalSpent;
  final double totalBudget;
  final double thresholdPercentage;

  const DashboardProgressMetrics({
    required this.timeElapsedPercentage,
    required this.moneySpentPercentage,
    required this.isWarning,
    required this.percentageDifference,
    required this.totalSpent,
    required this.totalBudget,
    required this.thresholdPercentage,
  });
}

final dashboardProgressProvider =
    Provider.family<DashboardProgressMetrics?, String?>((ref, groupId) {
  final asyncMetrics = ref.watch(dashboardNotifierProvider(groupId));
  return asyncMetrics.whenOrNull(
    data: (metrics) => DashboardProgressMetrics(
      timeElapsedPercentage: metrics.timeElapsedPercentage,
      moneySpentPercentage: metrics.moneySpentPercentage,
      isWarning: metrics.isWarning,
      percentageDifference: metrics.percentageDifference,
      totalSpent: metrics.totalSpent,
      totalBudget: metrics.totalBudget,
      thresholdPercentage: metrics.thresholdPercentage,
    ),
  );
});

final dashboardCategoryExpensesProvider =
    Provider.family<List<CategoryExpenseEntity>, String?>((ref, groupId) {
  final asyncMetrics = ref.watch(dashboardNotifierProvider(groupId));
  return asyncMetrics.maybeWhen(
    data: (metrics) => metrics.categoryExpenses,
    orElse: () => const [],
  );
});

final dashboardExtraordinaryExpensesProvider =
    Provider.family<List<TransactionEntity>, String?>((ref, groupId) {
  final asyncMetrics = ref.watch(dashboardNotifierProvider(groupId));
  return asyncMetrics.maybeWhen(
    data: (metrics) => metrics.extraordinaryTransactions,
    orElse: () => const [],
  );
});

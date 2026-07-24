import 'package:finanzas_compartidas/features/auth/domain/entities/user_entity.dart';
import 'package:finanzas_compartidas/features/auth/domain/repositories/auth_repository.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/login_usecase.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/register_usecase.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:finanzas_compartidas/features/auth/presentation/providers/auth_provider.dart';
import 'package:finanzas_compartidas/features/auth/presentation/providers/auth_state.dart';
import 'package:finanzas_compartidas/features/dashboard/domain/entities/category_expense_entity.dart';
import 'package:finanzas_compartidas/features/dashboard/domain/entities/dashboard_metrics_entity.dart';
import 'package:finanzas_compartidas/features/dashboard/domain/usecases/get_dashboard_data_usecase.dart';
import 'package:finanzas_compartidas/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:finanzas_compartidas/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:finanzas_compartidas/features/groups/domain/repositories/group_repository.dart';
import 'package:finanzas_compartidas/features/groups/domain/usecases/close_week_usecase.dart';
import 'package:finanzas_compartidas/features/groups/domain/usecases/create_group_usecase.dart';
import 'package:finanzas_compartidas/features/groups/domain/usecases/get_group_summary_usecase.dart';
import 'package:finanzas_compartidas/features/groups/domain/usecases/get_user_groups_usecase.dart';
import 'package:finanzas_compartidas/features/groups/domain/usecases/join_group_usecase.dart';
import 'package:finanzas_compartidas/features/groups/presentation/providers/groups_provider.dart';
import 'package:finanzas_compartidas/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:finanzas_compartidas/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockGroupRepository extends Mock implements GroupRepository {}
class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}

class MockGetUserGroupsUseCase extends Mock implements GetUserGroupsUseCase {}
class MockCreateGroupUseCase extends Mock implements CreateGroupUseCase {}
class MockJoinGroupUseCase extends Mock implements JoinGroupUseCase {}
class MockGetGroupSummaryUseCase extends Mock implements GetGroupSummaryUseCase {}
class MockCloseWeekUseCase extends Mock implements CloseWeekUseCase {}

class MockGetDashboardDataUseCase extends Mock
    implements GetDashboardDataUseCase {}

class TestAuthNotifier extends AuthNotifier {
  TestAuthNotifier(UserEntity user, AuthRepository repo)
      : super(
          loginUseCase: MockLoginUseCase(),
          registerUseCase: MockRegisterUseCase(),
          resetPasswordUseCase: MockResetPasswordUseCase(),
          signOutUseCase: MockSignOutUseCase(),
          authRepository: repo,
        ) {
    state = AuthState.authenticated(user);
  }
}

class TestGroupsNotifier extends GroupsNotifier {
  TestGroupsNotifier(Ref ref)
      : super(
          getUserGroupsUseCase: MockGetUserGroupsUseCase(),
          createGroupUseCase: MockCreateGroupUseCase(),
          joinGroupUseCase: MockJoinGroupUseCase(),
          getGroupSummaryUseCase: MockGetGroupSummaryUseCase(),
          closeWeekUseCase: MockCloseWeekUseCase(),
          ref: ref,
        ) {
    state = const GroupsState(isLoading: false, groups: []);
  }

  @override
  Future<void> loadUserGroups() async {}
}

class TestDashboardNotifier
    extends StateNotifier<AsyncValue<DashboardMetricsEntity>>
    implements DashboardNotifier {
  final DashboardMetricsEntity initialMetrics;

  TestDashboardNotifier(this.initialMetrics)
      : super(AsyncValue.data(initialMetrics));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<void> loadDashboard({bool isRefresh = false}) async {
    state = AsyncValue.data(initialMetrics);
  }

  @override
  void updateMetrics(DashboardMetricsEntity metrics) {
    state = AsyncValue.data(metrics);
  }
}

void main() {
  late MockGroupRepository mockGroupRepo;
  late MockTransactionRepository mockTxRepo;
  late MockAuthRepository mockAuthRepo;

  const testUser = UserEntity(
    id: 'u1',
    email: 'test@example.com',
    fullName: 'María López',
  );

  const mockMetrics = DashboardMetricsEntity(
    groupId: null,
    groupName: null,
    totalBudget: 2000.0,
    totalSpent: 800.0,
    timeElapsedPercentage: 40.0,
    moneySpentPercentage: 40.0,
    thresholdPercentage: 10.0,
    isWarning: false,
    percentageDifference: 0.0,
    categoryExpenses: [
      CategoryExpenseEntity(
        category: 'Comida',
        amount: 500.0,
        percentage: 62.5,
        count: 5,
      ),
      CategoryExpenseEntity(
        category: 'Transporte',
        amount: 300.0,
        percentage: 37.5,
        count: 2,
      ),
    ],
    extraordinaryTransactions: [],
    totalExtraordinarySpent: 0.0,
  );

  setUp(() {
    mockGroupRepo = MockGroupRepository();
    mockTxRepo = MockTransactionRepository();
    mockAuthRepo = MockAuthRepository();

    when(() => mockAuthRepo.getCurrentUser()).thenAnswer((_) async => testUser);
    when(() => mockAuthRepo.authStateChanges)
        .thenAnswer((_) => Stream.value(testUser));
    when(() => mockGroupRepo.getUserGroups('u1')).thenAnswer((_) async => []);
    when(() => mockTxRepo.getTransactions(userId: 'u1', groupId: null))
        .thenAnswer((_) async => []);
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        groupRepositoryProvider.overrideWithValue(mockGroupRepo),
        transactionRepositoryProvider.overrideWithValue(mockTxRepo),
        authNotifierProvider.overrideWith(
          (ref) => TestAuthNotifier(testUser, mockAuthRepo),
        ),
        groupsNotifierProvider.overrideWith(
          (ref) => TestGroupsNotifier(ref),
        ),
        dashboardNotifierProvider(null).overrideWith((ref) {
          return TestDashboardNotifier(mockMetrics);
        }),
      ],
      child: const MaterialApp(
        home: DashboardScreen(),
      ),
    );
  }

  group('DashboardScreen Widget Tests', () {
    testWidgets('renders greeting, metrics cards, progress bar, category chart and action buttons',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pumpAndSettle();

      expect(find.text('Dashboard Financiero 📊'), findsOneWidget);
      expect(find.textContaining('¡Hola, María López!'), findsOneWidget);
      expect(find.text('Presupuesto Total'), findsOneWidget);
      expect(find.textContaining('2000.00'), findsAtLeastNWidgets(1));
      expect(find.text('Total Gastado'), findsOneWidget);
      expect(find.textContaining('800.00'), findsAtLeastNWidgets(1));
      expect(find.text('Ritmo de Gasto'), findsOneWidget);
      expect(find.text('Gastos por Categoría'), findsOneWidget);
      expect(find.text('Gastos Extraordinarios'), findsOneWidget);
      expect(find.text('Nuevo Gasto ⚡'), findsOneWidget);
    });
  });
}

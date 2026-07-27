import 'package:finanzas_compartidas/features/auth/domain/entities/user_entity.dart';
import 'package:finanzas_compartidas/features/auth/domain/repositories/auth_repository.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/identify_user_usecase.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:finanzas_compartidas/features/auth/presentation/providers/auth_provider.dart';
import 'package:finanzas_compartidas/features/auth/presentation/providers/auth_state.dart';
import 'package:finanzas_compartidas/features/dashboard/presentation/providers/dashboard_provider.dart';
import 'package:finanzas_compartidas/features/groups/domain/entities/budget_week_entity.dart';
import 'package:finanzas_compartidas/features/groups/domain/entities/group_entity.dart';
import 'package:finanzas_compartidas/features/groups/domain/repositories/group_repository.dart';
import 'package:finanzas_compartidas/features/groups/presentation/providers/groups_provider.dart';
import 'package:finanzas_compartidas/features/transactions/domain/entities/transaction_entity.dart';
import 'package:finanzas_compartidas/features/transactions/domain/repositories/transaction_repository.dart';
import 'package:finanzas_compartidas/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGroupRepository extends Mock implements GroupRepository {}
class MockTransactionRepository extends Mock implements TransactionRepository {}
class MockAuthRepository extends Mock implements AuthRepository {}
class MockIdentifyUserUseCase extends Mock implements IdentifyUserUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}

class SynchronousAuthNotifier extends AuthNotifier {
  SynchronousAuthNotifier(UserEntity user, AuthRepository repo)
      : super(
          identifyUserUseCase: MockIdentifyUserUseCase(),
          signOutUseCase: MockSignOutUseCase(),
          authRepository: repo,
        ) {
    state = AuthState.authenticated(user);
  }
}

void main() {
  late MockGroupRepository mockGroupRepo;
  late MockTransactionRepository mockTxRepo;
  late MockAuthRepository mockAuthRepo;

  const tUser = UserEntity(id: 'u1', email: 'test@example.com', fullName: 'Test User');

  final tGroup = GroupEntity(
    id: 'g1',
    name: 'Grupo Pruebas',
    inviteCode: 'ABC123',
    budgetTotal: 1000.0,
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 28),
    weeksCount: 4,
    createdBy: 'u1',
    createdAt: DateTime(2026, 7, 1),
  );

  final tWeek1 = BudgetWeekEntity(
    id: 'w1',
    groupId: 'g1',
    weekNumber: 1,
    startDate: DateTime(2026, 7, 1),
    endDate: DateTime(2026, 7, 7),
    plannedAmount: 250.0,
    spentAmount: 150.0,
    adjustedAmount: 250.0,
  );

  final tTx1 = TransactionEntity(
    id: 'tx1',
    walletId: 'w1',
    userId: 'u1',
    groupId: 'g1',
    amount: 150.0,
    category: 'Comida',
    isShared: true,
    isExtraordinary: false,
    description: 'Tacos',
    createdAt: DateTime(2026, 7, 2),
  );

  final tTx2 = TransactionEntity(
    id: 'tx2',
    walletId: 'w1',
    userId: 'u1',
    groupId: 'g1',
    amount: 300.0,
    category: 'Servicios',
    isShared: true,
    isExtraordinary: true,
    description: 'Luz',
    createdAt: DateTime(2026, 7, 3),
  );

  setUp(() {
    mockGroupRepo = MockGroupRepository();
    mockTxRepo = MockTransactionRepository();
    mockAuthRepo = MockAuthRepository();

    when(() => mockAuthRepo.getCurrentUser()).thenAnswer((_) async => tUser);
    when(() => mockAuthRepo.authStateChanges).thenAnswer((_) => Stream.value(tUser));
  });

  ProviderContainer createContainer() {
    return ProviderContainer(
      overrides: [
        authNotifierProvider.overrideWith(
          (ref) => SynchronousAuthNotifier(tUser, mockAuthRepo),
        ),
        groupRepositoryProvider.overrideWithValue(mockGroupRepo),
        transactionRepositoryProvider.overrideWithValue(mockTxRepo),
      ],
    );
  }

  test('dashboardNotifierProvider loads dashboard metrics', () async {
    when(() => mockGroupRepo.getGroupById('g1')).thenAnswer((_) async => tGroup);
    when(() => mockGroupRepo.getGroupBudgetWeeks('g1')).thenAnswer((_) async => [tWeek1]);
    when(() => mockTxRepo.getTransactions(userId: 'u1', groupId: 'g1'))
        .thenAnswer((_) async => [tTx1, tTx2]);

    final container = createContainer();
    addTearDown(container.dispose);

    final asyncState = await container.read(dashboardNotifierProvider('g1').notifier).stream.firstWhere((s) => s.hasValue);
    final metrics = asyncState.value!;

    expect(metrics.totalBudget, equals(1000.0));
    expect(metrics.totalSpent, equals(450.0));
  });

  test('dashboardCategoryExpensesProvider computes category expenses correctly', () async {
    when(() => mockGroupRepo.getGroupById('g1')).thenAnswer((_) async => tGroup);
    when(() => mockGroupRepo.getGroupBudgetWeeks('g1')).thenAnswer((_) async => [tWeek1]);
    when(() => mockTxRepo.getTransactions(userId: 'u1', groupId: 'g1'))
        .thenAnswer((_) async => [tTx1, tTx2]);

    final container = createContainer();
    addTearDown(container.dispose);

    await container.read(dashboardNotifierProvider('g1').notifier).stream.firstWhere((s) => s.hasValue);

    final categories = container.read(dashboardCategoryExpensesProvider('g1'));

    expect(categories.length, equals(2));
    final comida = categories.firstWhere((c) => c.category == 'Comida');
    expect(comida.amount, equals(150.0));

    final servicios = categories.firstWhere((c) => c.category == 'Servicios');
    expect(servicios.amount, equals(300.0));
  });

  test('dashboardExtraordinaryExpensesProvider filters extraordinary transactions', () async {
    when(() => mockGroupRepo.getGroupById('g1')).thenAnswer((_) async => tGroup);
    when(() => mockGroupRepo.getGroupBudgetWeeks('g1')).thenAnswer((_) async => [tWeek1]);
    when(() => mockTxRepo.getTransactions(userId: 'u1', groupId: 'g1'))
        .thenAnswer((_) async => [tTx1, tTx2]);

    final container = createContainer();
    addTearDown(container.dispose);

    await container.read(dashboardNotifierProvider('g1').notifier).stream.firstWhere((s) => s.hasValue);

    final extraordinary = container.read(dashboardExtraordinaryExpensesProvider('g1'));

    expect(extraordinary.length, equals(1));
    expect(extraordinary.first.id, equals('tx2'));
    expect(extraordinary.first.isExtraordinary, isTrue);
  });
}

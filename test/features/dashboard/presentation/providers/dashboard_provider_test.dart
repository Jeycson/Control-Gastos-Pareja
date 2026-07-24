import 'package:finanzas_compartidas/features/auth/domain/entities/user_entity.dart';
import 'package:finanzas_compartidas/features/auth/domain/repositories/auth_repository.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/login_usecase.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/register_usecase.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:finanzas_compartidas/features/auth/presentation/providers/auth_provider.dart';
import 'package:finanzas_compartidas/features/auth/presentation/providers/auth_state.dart';
import 'package:finanzas_compartidas/features/dashboard/presentation/providers/dashboard_provider.dart';
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
class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}

class SynchronousAuthNotifier extends AuthNotifier {
  SynchronousAuthNotifier(UserEntity user, AuthRepository repo)
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

void main() {
  late MockGroupRepository mockGroupRepo;
  late MockTransactionRepository mockTxRepo;
  late MockAuthRepository mockAuthRepo;

  const testUser = UserEntity(
    id: 'user123',
    email: 'test@example.com',
    fullName: 'Usuario Prueba',
  );

  setUp(() {
    mockGroupRepo = MockGroupRepository();
    mockTxRepo = MockTransactionRepository();
    mockAuthRepo = MockAuthRepository();

    when(() => mockAuthRepo.getCurrentUser()).thenAnswer((_) async => testUser);
    when(() => mockAuthRepo.authStateChanges)
        .thenAnswer((_) => Stream.value(testUser));
  });

  ProviderContainer makeContainer() {
    return ProviderContainer(
      overrides: [
        groupRepositoryProvider.overrideWithValue(mockGroupRepo),
        transactionRepositoryProvider.overrideWithValue(mockTxRepo),
        authNotifierProvider.overrideWith(
          (ref) => SynchronousAuthNotifier(testUser, mockAuthRepo),
        ),
      ],
    );
  }

  group('Dashboard Riverpod Providers', () {
    test('dashboardNotifierProvider loads data and provides metrics', () async {
      final group = GroupEntity(
        id: 'g1',
        name: 'Grupo Pareja',
        inviteCode: '123456',
        budgetTotal: 1000.0,
        startDate: DateTime(2026, 7, 1),
        endDate: DateTime(2026, 7, 31),
        weeksCount: 4,
        createdBy: 'user123',
      );

      when(() => mockGroupRepo.getGroupById('g1'))
          .thenAnswer((_) async => group);
      when(() => mockGroupRepo.getGroupBudgetWeeks('g1'))
          .thenAnswer((_) async => []);
      when(() => mockTxRepo.getTransactions(
            userId: 'user123',
            groupId: 'g1',
          )).thenAnswer((_) async => [
            TransactionEntity(
              id: 'tx1',
              walletId: 'w1',
              userId: 'user123',
              groupId: 'g1',
              amount: 200.0,
              category: 'Comida',
              isShared: true,
              isExtraordinary: false,
              description: 'Super',
              createdAt: DateTime.now(),
            ),
          ]);

      final container = makeContainer();

      final notifier =
          container.read(dashboardNotifierProvider('g1').notifier);
      await notifier.loadDashboard(isRefresh: true);

      final state = container.read(dashboardNotifierProvider('g1'));
      expect(state.hasValue, isTrue);

      final metrics = state.value;
      expect(metrics, isNotNull);
      expect(metrics!.groupId, 'g1');
      expect(metrics.totalBudget, 1000.0);
      expect(metrics.totalSpent, 200.0);

      // Verify fine-grained family providers
      final progress = container.read(dashboardProgressProvider('g1'));
      expect(progress, isNotNull);
      expect(progress!.totalSpent, 200.0);

      final categories =
          container.read(dashboardCategoryExpensesProvider('g1'));
      expect(categories.length, 1);
      expect(categories.first.category, 'Comida');
    });
  });
}

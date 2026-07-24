import 'package:finanzas_compartidas/features/auth/domain/entities/user_entity.dart';
import 'package:finanzas_compartidas/features/auth/domain/repositories/auth_repository.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/login_usecase.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/register_usecase.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:finanzas_compartidas/features/auth/presentation/providers/auth_provider.dart';
import 'package:finanzas_compartidas/features/auth/presentation/providers/auth_state.dart';
import 'package:finanzas_compartidas/features/groups/domain/usecases/close_week_usecase.dart';
import 'package:finanzas_compartidas/features/groups/domain/usecases/create_group_usecase.dart';
import 'package:finanzas_compartidas/features/groups/domain/usecases/get_group_summary_usecase.dart';
import 'package:finanzas_compartidas/features/groups/domain/usecases/get_user_groups_usecase.dart';
import 'package:finanzas_compartidas/features/groups/domain/usecases/join_group_usecase.dart';
import 'package:finanzas_compartidas/features/groups/presentation/providers/groups_provider.dart';
import 'package:finanzas_compartidas/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:finanzas_compartidas/features/wallets/domain/entities/wallet_entity.dart';
import 'package:finanzas_compartidas/features/wallets/domain/usecases/create_wallet_usecase.dart';
import 'package:finanzas_compartidas/features/wallets/domain/usecases/delete_wallet_usecase.dart';
import 'package:finanzas_compartidas/features/wallets/domain/usecases/get_wallets_usecase.dart';
import 'package:finanzas_compartidas/features/wallets/domain/usecases/update_balance_usecase.dart';
import 'package:finanzas_compartidas/features/wallets/presentation/providers/wallets_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}

class MockGetWalletsUseCase extends Mock implements GetWalletsUseCase {}
class MockCreateWalletUseCase extends Mock implements CreateWalletUseCase {}
class MockUpdateBalanceUseCase extends Mock implements UpdateBalanceUseCase {}
class MockDeleteWalletUseCase extends Mock implements DeleteWalletUseCase {}

class MockGetUserGroupsUseCase extends Mock implements GetUserGroupsUseCase {}
class MockCreateGroupUseCase extends Mock implements CreateGroupUseCase {}
class MockJoinGroupUseCase extends Mock implements JoinGroupUseCase {}
class MockGetGroupSummaryUseCase extends Mock implements GetGroupSummaryUseCase {}
class MockCloseWeekUseCase extends Mock implements CloseWeekUseCase {}

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

class TestWalletsNotifier extends WalletsNotifier {
  TestWalletsNotifier(WalletsState initialState, Ref ref)
      : super(
          getWalletsUseCase: MockGetWalletsUseCase(),
          createWalletUseCase: MockCreateWalletUseCase(),
          updateBalanceUseCase: MockUpdateBalanceUseCase(),
          deleteWalletUseCase: MockDeleteWalletUseCase(),
          ref: ref,
        ) {
    state = initialState;
  }

  @override
  Future<void> loadWallets() async {}
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

void main() {
  late MockAuthRepository mockAuthRepo;

  const testUser = UserEntity(
    id: 'u1',
    email: 'test@example.com',
    fullName: 'Juan Pérez',
  );

  const testWallet = WalletEntity(
    id: 'w1',
    name: 'Efectivo',
    balance: 500.0,
    type: WalletType.cash,
    isShared: false,
    userId: 'u1',
  );

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    when(() => mockAuthRepo.getCurrentUser()).thenAnswer((_) async => testUser);
    when(() => mockAuthRepo.authStateChanges)
        .thenAnswer((_) => Stream.value(testUser));
  });

  Widget createWidgetUnderTest() {
    return ProviderScope(
      overrides: [
        authNotifierProvider.overrideWith(
          (ref) => TestAuthNotifier(testUser, mockAuthRepo),
        ),
        walletsNotifierProvider.overrideWith((ref) => TestWalletsNotifier(
              const WalletsState(isLoading: false, wallets: [testWallet]),
              ref,
            )),
        groupsNotifierProvider.overrideWith(
          (ref) => TestGroupsNotifier(ref),
        ),
      ],
      child: const MaterialApp(
        home: AddTransactionScreen(),
      ),
    );
  }

  group('AddTransactionScreen Widget Tests', () {
    testWidgets('renders all key components (header, amount display, wallet, categories, submit button)',
        (WidgetTester tester) async {
      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      expect(find.text('Registro Rápido de Gasto ⚡'), findsOneWidget);
      expect(find.text('Monto del Gasto'), findsOneWidget);
      expect(find.text('Selecciona Billetera'), findsOneWidget);
      expect(find.text('Efectivo'), findsOneWidget);
      expect(find.text('Categoría'), findsOneWidget);
      expect(find.text('Comida'), findsOneWidget);
      expect(find.text('Transporte'), findsOneWidget);
      expect(find.text('Guardar Transacción Instantánea'), findsOneWidget);
    });

    testWidgets('keypad updates amount display when pressed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createWidgetUnderTest());
      await tester.pump();

      await tester.ensureVisible(find.text('5'));
      await tester.tap(find.text('5'));
      await tester.pump();
      await tester.tap(find.text('0'));
      await tester.pump();

      expect(find.text('\$ 50'), findsOneWidget);
    });
  });
}

import 'package:finanzas_compartidas/features/auth/domain/entities/user_entity.dart';
import 'package:finanzas_compartidas/features/auth/domain/repositories/auth_repository.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/login_usecase.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/register_usecase.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/reset_password_usecase.dart';
import 'package:finanzas_compartidas/features/auth/domain/usecases/sign_out_usecase.dart';
import 'package:finanzas_compartidas/features/auth/presentation/providers/auth_provider.dart';
import 'package:finanzas_compartidas/features/auth/presentation/providers/auth_state.dart';
import 'package:finanzas_compartidas/main.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockLoginUseCase extends Mock implements LoginUseCase {}
class MockRegisterUseCase extends Mock implements RegisterUseCase {}
class MockResetPasswordUseCase extends Mock implements ResetPasswordUseCase {}
class MockSignOutUseCase extends Mock implements SignOutUseCase {}

class FakeAuthNotifier extends AuthNotifier {
  FakeAuthNotifier(AuthRepository repo)
      : super(
          loginUseCase: MockLoginUseCase(),
          registerUseCase: MockRegisterUseCase(),
          resetPasswordUseCase: MockResetPasswordUseCase(),
          signOutUseCase: MockSignOutUseCase(),
          authRepository: repo,
        ) {
    state = AuthState.unauthenticated();
  }
}

void main() {
  testWidgets('App smoke test renders login screen when unauthenticated',
      (WidgetTester tester) async {
    final mockAuthRepo = MockAuthRepository();
    when(() => mockAuthRepo.getCurrentUser()).thenAnswer((_) async => null);
    when(() => mockAuthRepo.authStateChanges)
        .thenAnswer((_) => const Stream<UserEntity?>.empty());

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authNotifierProvider.overrideWith((ref) => FakeAuthNotifier(mockAuthRepo)),
        ],
        child: const FinanzasCompartidasApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Iniciar Sesión'), findsOneWidget);
  });
}

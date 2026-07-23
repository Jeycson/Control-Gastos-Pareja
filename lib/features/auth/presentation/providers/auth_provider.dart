import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../domain/usecases/reset_password_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import 'auth_state.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(ref.watch(supabaseClientProvider));
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final loginUseCaseProvider = Provider<LoginUseCase>((ref) {
  return LoginUseCase(ref.watch(authRepositoryProvider));
});

final registerUseCaseProvider = Provider<RegisterUseCase>((ref) {
  return RegisterUseCase(ref.watch(authRepositoryProvider));
});

final resetPasswordUseCaseProvider = Provider<ResetPasswordUseCase>((ref) {
  return ResetPasswordUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final LoginUseCase loginUseCase;
  final RegisterUseCase registerUseCase;
  final ResetPasswordUseCase resetPasswordUseCase;
  final SignOutUseCase signOutUseCase;
  final AuthRepository authRepository;
  StreamSubscription? _authSubscription;

  AuthNotifier({
    required this.loginUseCase,
    required this.registerUseCase,
    required this.resetPasswordUseCase,
    required this.signOutUseCase,
    required this.authRepository,
  }) : super(AuthState.initial()) {
    _init();
  }

  Future<void> _init() async {
    state = AuthState.loading();
    try {
      final user = await authRepository.getCurrentUser();
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (_) {
      state = AuthState.unauthenticated();
    }

    _authSubscription = authRepository.authStateChanges.listen((user) {
      if (user != null) {
        state = AuthState.authenticated(user);
      } else {
        state = AuthState.unauthenticated();
      }
    });
  }

  Future<void> login(String email, String password) async {
    state = AuthState.loading();
    try {
      final user = await loginUseCase(LoginParams(email: email, password: password));
      state = AuthState.authenticated(user);
    } on ServerException catch (e) {
      state = AuthState.error(e.message);
    } catch (_) {
      state = AuthState.error('Ocurrió un error inesperado al iniciar sesión.');
    }
  }

  Future<void> register(String email, String password, String fullName) async {
    state = AuthState.loading();
    try {
      final user = await registerUseCase(
        RegisterParams(email: email, password: password, fullName: fullName),
      );
      state = AuthState.authenticated(user);
    } on ServerException catch (e) {
      state = AuthState.error(e.message);
    } catch (_) {
      state = AuthState.error('Ocurrió un error inesperado al registrar el usuario.');
    }
  }

  Future<bool> resetPassword(String email) async {
    state = AuthState.loading();
    try {
      await resetPasswordUseCase(ResetPasswordParams(email: email));
      state = AuthState.unauthenticated();
      return true;
    } on ServerException catch (e) {
      state = AuthState.error(e.message);
      return false;
    } catch (_) {
      state = AuthState.error('Ocurrió un error inesperado al solicitar el restablecimiento.');
      return false;
    }
  }

  Future<void> logout() async {
    state = AuthState.loading();
    try {
      await signOutUseCase(const NoParams());
      state = AuthState.unauthenticated();
    } catch (_) {
      state = AuthState.unauthenticated();
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    resetPasswordUseCase: ref.watch(resetPasswordUseCaseProvider),
    signOutUseCase: ref.watch(signOutUseCaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

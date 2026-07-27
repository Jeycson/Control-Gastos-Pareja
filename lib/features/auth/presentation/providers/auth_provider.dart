import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/exceptions.dart';
import '../../../../core/network/supabase_client.dart';
import '../../../../core/providers/shared_preferences_provider.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/datasources/auth_remote_data_source.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/identify_user_usecase.dart';
import '../../domain/usecases/sign_out_usecase.dart';
import 'auth_state.dart';

final authRemoteDataSourceProvider = Provider<AuthRemoteDataSource>((ref) {
  return AuthRemoteDataSourceImpl(
    supabaseClient: ref.watch(supabaseClientProvider),
    sharedPreferences: ref.watch(sharedPreferencesProvider),
  );
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepositoryImpl(ref.watch(authRemoteDataSourceProvider));
});

final identifyUserUseCaseProvider = Provider<IdentifyUserUseCase>((ref) {
  return IdentifyUserUseCase(ref.watch(authRepositoryProvider));
});

final signOutUseCaseProvider = Provider<SignOutUseCase>((ref) {
  return SignOutUseCase(ref.watch(authRepositoryProvider));
});

class AuthNotifier extends StateNotifier<AuthState> {
  final IdentifyUserUseCase identifyUserUseCase;
  final SignOutUseCase signOutUseCase;
  final AuthRepository authRepository;
  StreamSubscription? _authSubscription;

  AuthNotifier({
    required this.identifyUserUseCase,
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

  Future<void> identify(String fullName) async {
    final name = fullName.trim();
    if (name.isEmpty) {
      state = AuthState.error('Por favor ingresa tu nombre.');
      return;
    }

    state = AuthState.loading();
    try {
      final user = await identifyUserUseCase(IdentifyUserParams(fullName: name));
      state = AuthState.authenticated(user);
    } on ServerException catch (e) {
      state = AuthState.error(e.message);
    } catch (_) {
      state = AuthState.error('Ocurrió un error inesperado al guardar tu nombre.');
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
    identifyUserUseCase: ref.watch(identifyUserUseCaseProvider),
    signOutUseCase: ref.watch(signOutUseCaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

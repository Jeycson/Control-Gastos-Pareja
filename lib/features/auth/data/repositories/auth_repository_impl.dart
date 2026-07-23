import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/errors/exceptions.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl(this.remoteDataSource);

  @override
  Future<UserEntity?> getCurrentUser() async {
    try {
      return await remoteDataSource.getCurrentUser();
    } catch (e) {
      throw ServerException(message: _mapErrorMessage(e));
    }
  }

  @override
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await remoteDataSource.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw ServerException(message: _mapErrorMessage(e));
    }
  }

  @override
  Future<UserEntity> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      return await remoteDataSource.signUpWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
      );
    } catch (e) {
      throw ServerException(message: _mapErrorMessage(e));
    }
  }

  @override
  Future<void> sendPasswordResetEmail({
    required String email,
  }) async {
    try {
      await remoteDataSource.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw ServerException(message: _mapErrorMessage(e));
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await remoteDataSource.signOut();
    } catch (e) {
      throw ServerException(message: _mapErrorMessage(e));
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges => remoteDataSource.authStateChanges;

  String _mapErrorMessage(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid login credentials')) {
        return 'Correo o contraseña incorrectos.';
      }
      if (msg.contains('user already registered') || msg.contains('already exists')) {
        return 'Este correo electrónico ya está registrado.';
      }
      if (msg.contains('password should be at least')) {
        return 'La contraseña debe tener al menos 6 caracteres.';
      }
      if (msg.contains('unable to validate email address') || msg.contains('invalid email')) {
        return 'El correo electrónico ingresado no es válido.';
      }
      return error.message;
    }
    return 'Ocurrió un error inesperado al procesar la solicitud.';
  }
}

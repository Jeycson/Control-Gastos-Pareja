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
      throw const ServerException(message: 'Error al obtener el usuario actual.');
    }
  }

  @override
  Future<UserEntity> identifyUser({required String fullName}) async {
    try {
      return await remoteDataSource.identifyUser(fullName: fullName);
    } catch (e) {
      throw const ServerException(message: 'Error al registrar el nombre.');
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await remoteDataSource.signOut();
    } catch (e) {
      throw const ServerException(message: 'Error al cerrar sesión.');
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges => remoteDataSource.authStateChanges;
}

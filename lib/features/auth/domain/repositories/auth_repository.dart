import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> identifyUser({required String fullName});
  Future<void> signOut();
  Stream<UserEntity?> get authStateChanges;
}

import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity?> getCurrentUser();
  Future<UserEntity> signInWithEmailAndPassword({
    required String email,
    required String password,
  });
  Future<UserEntity> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  });
  Future<void> sendPasswordResetEmail({
    required String email,
  });
  Future<void> signOut();
  Stream<UserEntity?> get authStateChanges;
}

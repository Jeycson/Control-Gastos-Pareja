import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/utils/uuid_generator.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel?> getCurrentUser();
  Future<UserModel> identifyUser({required String fullName});
  Future<void> signOut();
  Stream<UserModel?> get authStateChanges;
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final SupabaseClient supabaseClient;
  final SharedPreferences sharedPreferences;
  final StreamController<UserModel?> _authStateController = StreamController<UserModel?>.broadcast();

  static const String _userIdKey = 'current_user_id';
  static const String _userNameKey = 'current_user_name';

  AuthRemoteDataSourceImpl({
    required this.supabaseClient,
    required this.sharedPreferences,
  });

  @override
  Future<UserModel?> getCurrentUser() async {
    final userId = sharedPreferences.getString(_userIdKey);
    final userName = sharedPreferences.getString(_userNameKey);

    if (userId != null && userId.isNotEmpty && userName != null && userName.isNotEmpty) {
      return UserModel(id: userId, fullName: userName);
    }
    return null;
  }

  @override
  Future<UserModel> identifyUser({required String fullName}) async {
    String? userId = sharedPreferences.getString(_userIdKey);
    if (userId == null || userId.isEmpty) {
      userId = UuidGenerator.generateV4();
    }

    try {
      await supabaseClient.from('profiles').upsert({
        'id': userId,
        'full_name': fullName,
      });
    } catch (_) {
      // In case offline, offline/local storage still works
    }

    await sharedPreferences.setString(_userIdKey, userId);
    await sharedPreferences.setString(_userNameKey, fullName);

    final user = UserModel(id: userId, fullName: fullName);
    _authStateController.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await sharedPreferences.remove(_userIdKey);
    await sharedPreferences.remove(_userNameKey);
    _authStateController.add(null);
  }

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;
}

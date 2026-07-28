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
    final cleanName = fullName.trim();
    String? userId;
    String matchedName = cleanName;

    try {
      final List<dynamic> existingProfiles = await supabaseClient
          .from('profiles')
          .select()
          .ilike('full_name', cleanName);

      if (existingProfiles.isNotEmpty) {
        final profile = existingProfiles.first as Map<String, dynamic>;
        userId = profile['id'] as String?;
        if (profile['full_name'] != null &&
            (profile['full_name'] as String).isNotEmpty) {
          matchedName = profile['full_name'] as String;
        }
      }
    } catch (_) {
      // If offline or query fails, fall back to local stored credentials
    }

    if (userId == null || userId.isEmpty) {
      final currentName = sharedPreferences.getString(_userNameKey);
      final currentId = sharedPreferences.getString(_userIdKey);

      if (currentId != null &&
          currentId.isNotEmpty &&
          currentName != null &&
          currentName.trim().toLowerCase() == cleanName.toLowerCase()) {
        userId = currentId;
      } else {
        userId = UuidGenerator.generateV4();
      }
    }

    await sharedPreferences.setString(_userIdKey, userId);
    await sharedPreferences.setString(_userNameKey, matchedName);

    try {
      await supabaseClient.from('profiles').upsert({
        'id': userId,
        'full_name': matchedName,
      });
    } catch (_) {
      // In case offline, offline/local storage still works
    }

    final user = UserModel(id: userId, fullName: matchedName);
    _authStateController.add(user);
    return user;
  }

  @override
  Future<void> signOut() async {
    await sharedPreferences.remove(_userIdKey);
    await sharedPreferences.remove(_userNameKey);
    await sharedPreferences.remove('user_budget_start_date');
    await sharedPreferences.remove('user_budget_end_date');
    await sharedPreferences.remove('user_budget_weeks_count');
    _authStateController.add(null);
  }

  @override
  Stream<UserModel?> get authStateChanges => _authStateController.stream;
}

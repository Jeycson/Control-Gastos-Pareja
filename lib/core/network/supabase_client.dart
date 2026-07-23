import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/env_constants.dart';

Future<void> initSupabase() async {
  if (EnvConstants.supabaseUrl.isEmpty || EnvConstants.supabaseAnonKey.isEmpty) {
    return;
  }
  await Supabase.initialize(
    url: EnvConstants.supabaseUrl,
    publishableKey: EnvConstants.supabaseAnonKey,
  );
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

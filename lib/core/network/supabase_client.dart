import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/env_constants.dart';

Future<void> initSupabase() async {
  final url = EnvConstants.supabaseUrl.isNotEmpty
      ? EnvConstants.supabaseUrl
      : 'https://placeholder-project.supabase.co';
  final anonKey = EnvConstants.supabaseAnonKey.isNotEmpty
      ? EnvConstants.supabaseAnonKey
      : 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InBsYWNlaG9sZGVyIiwicm9sZSI6ImFub24iLCJpYXQiOjE2Nzc2MDAwMDAsImV4cCI6MTk5MzE3NjAwMH0.placeholder';

  try {
    await Supabase.initialize(
      url: url,
      publishableKey: anonKey,
    );
  } catch (_) {
    // Gracefully handle if already initialized or error occurs
  }
}

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

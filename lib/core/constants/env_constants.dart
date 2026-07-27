abstract class EnvConstants {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://evrxdxrtfecyjctsioet.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_b7DHZxfgnE-LK0cuRsNQhQ_6gZzVh-c',
  );
}

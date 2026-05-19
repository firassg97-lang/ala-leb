import 'package:supabase_flutter/supabase_flutter.dart';
import '../constants/app_strings.dart';

class SupabaseConfig {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    await Supabase.initialize(
      url: AppStrings.supabaseUrl,
      anonKey: AppStrings.supabaseAnonKey,
    );
  }
}

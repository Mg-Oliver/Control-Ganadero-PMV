import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      // Si .env no está presente en el bundle (e.g. entorno de producción)
    }

    final envUrl = dotenv.env['SUPABASE_URL'] ?? '';
    final envKey = dotenv.env['SUPABASE_ANON_KEY'] ?? '';

    const dartDefineUrl = String.fromEnvironment('SUPABASE_URL');
    const dartDefineKey = String.fromEnvironment('SUPABASE_ANON_KEY');

    final supabaseUrl = dartDefineUrl.isNotEmpty ? dartDefineUrl : envUrl;
    final supabaseAnonKey = dartDefineKey.isNotEmpty ? dartDefineKey : envKey;

    if (supabaseUrl.isEmpty ||
        supabaseAnonKey.isEmpty ||
        supabaseUrl.contains('tu-proyecto.supabase.co')) {
      throw Exception(
        'SUPABASE_URL o SUPABASE_ANON_KEY no configurados o tienen valores de plantilla',
      );
    }

    await Supabase.initialize(
      url: supabaseUrl,
      // ignore: deprecated_member_use
      anonKey: supabaseAnonKey,
    );
  }
}

// ============================================
// File: lib/core/config/supabase_config.dart
// ============================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SupabaseConfig {
  static SupabaseClient? _instance;

  // Singleton instance
  static SupabaseClient get instance {
    if (_instance == null) {
      throw Exception('Supabase not initialized. Call init() first.');
    }
    return _instance!;
  }

  // Initialize Supabase
  static Future<void> init() async {
    try {
      // Load .env file
      await dotenv.load(fileName: '.env');

      final supabaseUrl = dotenv.env['SUPABASE_URL'];
      final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

      if (supabaseUrl == null || supabaseAnonKey == null) {
        throw Exception('Missing Supabase credentials in .env file');
      }

      // Initialize Supabase
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );

      _instance = Supabase.instance.client;

      if (kDebugMode) {
        debugPrint('✅ Supabase initialized successfully');
        debugPrint('📡 URL: $supabaseUrl');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ Supabase initialization failed: $e');
      }
      rethrow;
    }
  }

  // Helper getters
  static SupabaseClient get client => instance;
  static GoTrueClient get auth => instance.auth;
  static SupabaseStorageClient get storage => instance.storage;
  static RealtimeClient get realtime => instance.realtime;

  // Check if user is logged in
  static bool get isLoggedIn => auth.currentUser != null;

  // Get current user
  static User? get currentUser => auth.currentUser;

  // Get current user ID
  static String? get currentUserId => auth.currentUser?.id;
}

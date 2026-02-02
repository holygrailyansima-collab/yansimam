// ============================================
// File: lib/main.dart
// FIXED: All routing and initialization issues
// ============================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// Core
import 'core/config/supabase_config.dart';

// Screens
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/settings/settings_screen.dart';
import 'screens/leaderboard/leaderboard_screen.dart';
import 'screens/premium/premium_screen.dart';
import 'screens/voting/voting_start_screen.dart';
import 'screens/voting/voting_share_screen.dart';
import 'screens/voting/voting_progress_screen.dart';
import 'screens/voting/voting_result_screen.dart';

// Utils
import 'utils/constants.dart';

// Firebase options
import 'firebase_options.dart';

// ============================================
// Firebase Background Message Handler
// ============================================
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  debugPrint('📩 Background message: ${message.messageId}');
}

// ============================================
// Main Entry Point
// ============================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // 1. Load .env file
    await dotenv.load(fileName: '.env');
    debugPrint('✅ .env loaded');

    // 2. Initialize Firebase with platform options
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
    debugPrint('✅ Firebase initialized');

    // 3. Initialize Supabase
    await SupabaseConfig.init();
    debugPrint('✅ Supabase initialized');

    runApp(const MyApp());
  } catch (e) {
    debugPrint('❌ Initialization error: $e');
    runApp(ErrorApp(error: e.toString()));
  }
}

// ============================================
// Error Fallback App
// ============================================
class ErrorApp extends StatelessWidget {
  final String error;
  const ErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 80, color: Colors.red),
                const SizedBox(height: 20),
                const Text(
                  'Başlatma Hatası',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ============================================
// Main App
// ============================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YANSIMAM v1',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(),
      initialRoute: AppRoutes.splash, // ✅ Splash screen'den başlar
      routes: _buildRoutes(),
      onGenerateRoute: _onGenerateRoute,
    );
  }

  // ============================================
  // Theme Configuration
  // ============================================
  ThemeData _buildTheme() {
    return ThemeData(
      primaryColor: AppColors.primary,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        primary: AppColors.primary,
        secondary: AppColors.secondary,
        error: AppColors.error,
        surface: AppColors.surface,
        brightness: Brightness.light,
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.secondary,
        foregroundColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.greyLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.greyLight),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      useMaterial3: true,
    );
  }

  // ============================================
  // Static Routes (No Parameters)
  // ============================================
  Map<String, WidgetBuilder> _buildRoutes() {
    return {
      AppRoutes.splash: (context) => const SplashScreen(),
      AppRoutes.login: (context) => const LoginScreen(),
      AppRoutes.register: (context) => const RegisterScreen(),
      AppRoutes.home: (context) => const HomeScreen(),
      AppRoutes.profile: (context) => const ProfileScreen(),
      AppRoutes.settings: (context) => const SettingsScreen(),
      AppRoutes.leaderboard: (context) => const LeaderboardScreen(),
      AppRoutes.premium: (context) => const PremiumScreen(),
      AppRoutes.votingStart: (context) => const VotingStartScreen(),
    };
  }

  // ============================================
  // Dynamic Routes (With Parameters)
  // ============================================
  Route<dynamic>? _onGenerateRoute(RouteSettings settings) {
    final String routeName = settings.name ?? '';
    final Object? args = settings.arguments;

    // ============================================
    // Voting Share Screen
    // Requires: Map<String, dynamic> { 'sessionId', 'votingLink' }
    // ============================================
    if (routeName == AppRoutes.votingShare) {
      if (args is Map<String, dynamic>) {
        return MaterialPageRoute(
          builder: (context) => VotingShareScreen(
            votingLink: args['votingLink'] as String,
            sessionId: args['sessionId'] as String,
          ),
        );
      }
      return _buildErrorRoute('Missing parameters for Voting Share');
    }

    // ============================================
    // Voting Progress Screen
    // Requires: Map<String, dynamic> { 'sessionId', 'votingLink' }
    // ============================================
    if (routeName == AppRoutes.votingProgress) {
      if (args is Map<String, dynamic>) {
        return MaterialPageRoute(
          builder: (context) => VotingProgressScreen(
            sessionId: args['sessionId'] as String,
            votingLink: args['votingLink'] as String,
          ),
        );
      }
      return _buildErrorRoute('Missing parameters for Voting Progress');
    }

    // ============================================
    // Voting Result Screen
    // Requires: String (votingSessionId)
    // ============================================
    if (routeName == AppRoutes.votingResult) {
      if (args is String) {
        return MaterialPageRoute(
          builder: (context) => VotingResultScreen(
            votingSessionId: args,
          ),
        );
      }
      return _buildErrorRoute('Missing votingSessionId for Voting Result');
    }

    // Unknown Route
    return _buildErrorRoute('Route not found: $routeName');
  }

  // ============================================
  // Error Route Builder
  // ============================================
  MaterialPageRoute _buildErrorRoute(String error) {
    return MaterialPageRoute(
      builder: (context) => Scaffold(
        appBar: AppBar(
          title: const Text('Hata'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  size: 80,
                  color: AppColors.error,
                ),
                const SizedBox(height: 20),
                const Text(
                  'Sayfa Bulunamadı',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.grey),
                ),
                const SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Geri Dön'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

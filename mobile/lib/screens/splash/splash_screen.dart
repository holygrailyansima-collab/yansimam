// ============================================
// File: lib/screens/splash/splash_screen.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/config/supabase_config.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String _statusMessage = 'Yükleniyor...';
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _initializeApp();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
          parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  Future<void> _initializeApp() async {
    try {
      // Firebase check
      setState(() => _statusMessage = 'Firebase bağlanıyor...');
      await Future.delayed(const Duration(milliseconds: 500));

      final firebaseInitialized = Firebase.apps.isNotEmpty;
      if (!firebaseInitialized) {
        throw Exception('Firebase başlatılamadı');
      }
      debugPrint('✅ Firebase başlatıldı');

      // Supabase connection check
      setState(() => _statusMessage = 'Supabase bağlanıyor...');
      await Future.delayed(const Duration(milliseconds: 500));

      final supabase = SupabaseConfig.client;

      // Simple query to test connection
      try {
        await supabase.from('users').select('count').count();
        debugPrint('✅ Supabase bağlantısı başarılı');
      } catch (e) {
        debugPrint('⚠️ Supabase users tablosu bulunamadı (normal): $e');
        // Continue even if users table doesn't exist
      }

      // ✅ TEST MODE: Session check temporarily disabled
      setState(() => _statusMessage = 'Test modu aktif...');
      await Future.delayed(const Duration(milliseconds: 500));

      debugPrint(
          '🧪 TEST MODU: Session kontrolü atlanıyor, direkt login\'e gidiliyor...');

      if (!mounted) return;

      setState(() => _statusMessage = 'Başarılı!');
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // ✅ TEST MODE: Go directly to login (no session check)
      debugPrint('ℹ️ Login sayfasına yönlendiriliyor...');
      Navigator.of(context).pushReplacementNamed('/login');

      /* ========================================
         REAL SESSION CHECK (CURRENTLY DISABLED)
         Enable this code in production:
         1. Remove test mode code above (lines 75-95)
         2. Uncomment code below
         ======================================== */

      /*
      // Session check
      setState(() => _statusMessage = 'Oturum kontrol ediliyor...');
      await Future.delayed(const Duration(milliseconds: 500));
      
      final session = SupabaseConfig.auth.currentSession;
      final user = SupabaseConfig.currentUser;
      
      debugPrint('🔍 Session Check:');
      debugPrint('   User ID: ${user?.id}');
      debugPrint('   Email: ${user?.email}');
      debugPrint('   Session exists: ${session != null}');
      
      if (session?.accessToken != null) {
        debugPrint('   Access Token: ${session!.accessToken.substring(0, 20)}...');
      }
      
      if (!mounted) return;

      setState(() => _statusMessage = 'Başarılı!');
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // Navigation
      if (session != null && user != null) {
        debugPrint('✅ Oturum açık, ana sayfaya yönlendiriliyor...');
        Navigator.of(context).pushReplacementNamed('/home');
      } else {
        debugPrint('ℹ️ Oturum yok, giriş sayfasına yönlendiriliyor...');
        Navigator.of(context).pushReplacementNamed('/login');
      }
      */
    } catch (e) {
      debugPrint('❌ Splash Error: $e');
      setState(() {
        _hasError = true;
        _statusMessage = 'Hata: ${e.toString()}';
      });

      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        debugPrint('🔄 Yeniden deneniyor...');
        setState(() => _hasError = false);
        _initializeApp();
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF004563), // Dark Navy
              Color(0xFF009DE0), // Logo Blue
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo animation
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Y',
                          style: TextStyle(
                            fontSize: 80,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF009DE0),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // App name
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'YANSIMAM',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 2,
                    ),
                  ),
                ),

                const SizedBox(height: 8),

                // Tagline
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'Dijital Kimlik Doğrulama',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.white70,
                    ),
                  ),
                ),

                const SizedBox(height: 60),

                // Loading indicator or error icon
                if (!_hasError)
                  const CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  )
                else
                  const Icon(
                    Icons.error_outline,
                    color: Color(0xFFFF6B6B),
                    size: 48,
                  ),

                const SizedBox(height: 20),

                // Status message
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    _statusMessage,
                    style: TextStyle(
                      fontSize: 14,
                      color: _hasError
                          ? const Color(0xFFFF6B6B)
                          : Colors.white70,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

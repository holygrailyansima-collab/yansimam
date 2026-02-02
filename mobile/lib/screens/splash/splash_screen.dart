// ============================================
// File: lib/screens/splash/splash_screen.dart
// FIXED: Smart routing based on user status
// Session var → User status kontrolü → Doğru yönlendirme
// ============================================

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../core/config/supabase_config.dart';

/// Splash Screen
/// 
/// Features:
/// - Firebase initialization check
/// - Supabase connection check
/// - Session validation
/// - User verification
/// - Smart routing based on user status:
///   * No session → LOGIN
///   * Session + unapproved → LOGIN (user needs to complete flow)
///   * Session + pending → HOME (voting in progress)
///   * Session + approved → HOME
///   * Session + rejected → HOME (can retry after 30 days)
/// 
/// FIXED: User status kontrolü eklendi
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

  // ============================================
  // ANIMATIONS SETUP
  // ============================================

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

  // ============================================
  // APP INITIALIZATION
  // ============================================

  Future<void> _initializeApp() async {
    try {
      // 1. Firebase Check
      setState(() => _statusMessage = 'Firebase kontrol ediliyor...');
      await Future.delayed(const Duration(milliseconds: 500));

      final firebaseInitialized = Firebase.apps.isNotEmpty;
      if (!firebaseInitialized) {
        throw Exception('Firebase başlatılamadı');
      }
      debugPrint('✅ Firebase başlatıldı');

      // 2. Supabase Connection Check
      setState(() => _statusMessage = 'Supabase bağlanıyor...');
      await Future.delayed(const Duration(milliseconds: 500));

      final supabase = SupabaseConfig.client;

      // Test connection with a simple query
      try {
        await supabase.from('users').select('count').limit(1);
        debugPrint('✅ Supabase bağlantısı başarılı');
      } catch (e) {
        debugPrint('⚠️ Supabase bağlantı testi hatası (devam ediliyor): $e');
        // Continue even if test fails - table might not exist yet
      }

      // 3. Session Check
      setState(() => _statusMessage = 'Oturum kontrol ediliyor...');
      await Future.delayed(const Duration(milliseconds: 500));

      final session = SupabaseConfig.auth.currentSession;
      final user = SupabaseConfig.auth.currentUser;

      debugPrint('🔍 Session Validation:');
      debugPrint('   Session exists: ${session != null}');
      debugPrint('   User exists: ${user != null}');
      debugPrint('   User ID: ${user?.id}');
      debugPrint('   Email: ${user?.email}');
      
      if (session != null) {
        debugPrint('   Session expires at: ${session.expiresAt}');
        debugPrint('   Access token length: ${session.accessToken.length}');
        
        // Check if session is expired
        final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
        final expiresAt = session.expiresAt;
        
        if (expiresAt != null && expiresAt <= now) {
          debugPrint('⚠️ Session expired, clearing...');
          await SupabaseConfig.auth.signOut();
          if (!mounted) return;
          setState(() => _statusMessage = 'Oturum süresi doldu, giriş yapın');
          await Future.delayed(const Duration(seconds: 1));
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/login');
          return;
        }
      }

      // 4. User Verification (if session exists)
      String? userStatus;
      
      if (session != null && user != null) {
        setState(() => _statusMessage = 'Kullanıcı doğrulanıyor...');
        await Future.delayed(const Duration(milliseconds: 500));

        try {
          // Verify user exists in database
          final userData = await supabase
              .from('users')
              .select('id, email, status, full_name, username')
              .eq('auth_user_id', user.id)
              .maybeSingle();

          debugPrint('   Database user: ${userData != null ? "Found" : "Not found"}');
          
          if (userData != null) {
            userStatus = userData['status'] as String?;
            debugPrint('   User status: $userStatus');
            debugPrint('   User email: ${userData['email']}');
            debugPrint('   Full name: ${userData['full_name']}');
            debugPrint('   Username: ${userData['username']}');
          }

          // If user not found in database, clear session
          if (userData == null) {
            debugPrint('⚠️ User not found in database, clearing session...');
            await SupabaseConfig.auth.signOut();
            if (!mounted) return;
            Navigator.of(context).pushReplacementNamed('/login');
            return;
          }
        } catch (e) {
          debugPrint('⚠️ User verification error: $e');
          // If verification fails, clear session and go to login
          await SupabaseConfig.auth.signOut();
          if (!mounted) return;
          Navigator.of(context).pushReplacementNamed('/login');
          return;
        }
      }

      if (!mounted) return;

      setState(() => _statusMessage = 'Başarılı!');
      await Future.delayed(const Duration(milliseconds: 800));

      if (!mounted) return;

      // ============================================
      // 5. SMART NAVIGATION BASED ON USER STATUS
      // ============================================
      
      if (session == null || user == null) {
        // No session → Go to LOGIN
        debugPrint('ℹ️ No valid session, navigating to LOGIN');
        Navigator.of(context).pushReplacementNamed('/login');
        return;
      }

      // Session exists, check user status
      debugPrint('🎯 Smart routing based on status: $userStatus');
      
      switch (userStatus) {
        case 'unapproved':
          // User registered but hasn't completed voting flow
          // Send to LOGIN so they can start voting
          debugPrint('➡️ Status: unapproved → Navigating to LOGIN');
          Navigator.of(context).pushReplacementNamed('/login');
          break;
          
        case 'pending':
          // Voting in progress → Go to HOME
          debugPrint('➡️ Status: pending → Navigating to HOME');
          Navigator.of(context).pushReplacementNamed('/home');
          break;
          
        case 'approved':
          // Approved user → Go to HOME
          debugPrint('➡️ Status: approved → Navigating to HOME');
          Navigator.of(context).pushReplacementNamed('/home');
          break;
          
        case 'rejected':
          // Rejected but can retry → Go to HOME
          debugPrint('➡️ Status: rejected → Navigating to HOME');
          Navigator.of(context).pushReplacementNamed('/home');
          break;
          
        default:
          // Unknown status → Go to LOGIN for safety
          debugPrint('⚠️ Unknown status: $userStatus → Navigating to LOGIN');
          Navigator.of(context).pushReplacementNamed('/login');
      }
      
    } catch (e) {
      debugPrint('❌ Splash Screen Error: $e');
      
      if (mounted) {
        setState(() {
          _hasError = true;
          _statusMessage = 'Bir hata oluştu. Yeniden deneniyor...';
        });

        // Auto-retry after 3 seconds
        await Future.delayed(const Duration(seconds: 3));
        
        if (mounted) {
          debugPrint('🔄 Retrying initialization...');
          setState(() {
            _hasError = false;
            _statusMessage = 'Yeniden deneniyor...';
          });
          _initializeApp();
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ============================================
  // BUILD METHOD
  // ============================================

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
                // ============================================
                // LOGO ANIMATION
                // ============================================
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
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                            spreadRadius: 5,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(30),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              // Fallback if logo not found
                              return const Center(
                                child: Text(
                                  'Y',
                                  style: TextStyle(
                                    fontSize: 80,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF009DE0),
                                  ),
                                ),
                              );
                            },
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
                    strokeWidth: 3,
                  )
                else
                  Column(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Color(0xFFFF6B6B),
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _statusMessage = 'Yeniden deneniyor...';
                          });
                          _initializeApp();
                        },
                        child: const Text(
                          'Manuel Yeniden Dene',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
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
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),

                // Version info
                const SizedBox(height: 40),
                FadeTransition(
                  opacity: _fadeAnimation,
                  child: const Text(
                    'v1.0.0',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white38,
                    ),
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

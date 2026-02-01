// ============================================
// File: lib/screens/auth/login_screen.dart
// With safety check for public.users table
// ============================================

import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with TickerProviderStateMixin {
  bool _isLoading = false;
  bool _showEmailLogin = false;

  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    );
    _fadeController.forward();
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ⚡ NEW: SAFETY CHECK - Ensure user exists in public.users
  Future<void> _ensureUserRecordExists(User authUser) async {
    try {
      // Check if user exists in public.users
      final userData = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('auth_user_id', authUser.id)
          .maybeSingle();

      if (userData == null) {
        debugPrint('⚠️ User missing in public.users, creating...');

        // Get username from metadata or email
        String username = authUser.userMetadata?['username'] as String? ?? 
                         authUser.email!.split('@')[0];

        // Make username unique if needed
        final existingUser = await SupabaseConfig.client
            .from('users')
            .select('id')
            .eq('username', username)
            .maybeSingle();

        if (existingUser != null) {
          username = '${username}_${authUser.id.substring(0, 4)}';
        }

        // Create missing user record
        await SupabaseConfig.client.from('users').insert({
          'auth_user_id': authUser.id,
          'email': authUser.email!,
          'username': username,
          'full_name': authUser.userMetadata?['full_name'] ?? 
                      authUser.email!.split('@')[0],
          'profile_photo_url': authUser.userMetadata?['avatar_url'],
          'status': 'unapproved',
          'is_premium': false,
          'average_score': 0.0,
          'total_votes': 0,
          'created_at': DateTime.now().toUtc().toIso8601String(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });

        debugPrint('✅ User record created successfully');
      } else {
        debugPrint('✅ User record exists in public.users');
      }
    } catch (e) {
      debugPrint('❌ Error ensuring user record: $e');
      // Don't throw - allow login to continue
    }
  }

  // EMAIL OR USERNAME LOGIN (UPDATED WITH SAFETY CHECK)
  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final input = _emailController.text.trim();
      String email = input;

      // If no @ symbol, search for username in users table
      if (!input.contains('@')) {
        try {
          final userData = await SupabaseConfig.client
              .from('users')
              .select('email')
              .eq('username', input)
              .maybeSingle();

          if (userData == null) {
            if (mounted) {
              _showErrorSnackBar('Kullanıcı adı bulunamadı');
            }
            setState(() => _isLoading = false);
            return;
          }

          email = userData['email'];
        } catch (e) {
          if (mounted) {
            _showErrorSnackBar('Kullanıcı adı sorgulanırken hata: $e');
          }
          setState(() => _isLoading = false);
          return;
        }
      }

      final response = await SupabaseConfig.auth.signInWithPassword(
        email: email,
        password: _passwordController.text,
      );

      if (response.user != null) {
        // ⚡ SAFETY CHECK: Ensure user exists in public.users
        await _ensureUserRecordExists(response.user!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Giriş başarılı!'),
              backgroundColor: Color(0xFF25D366),
              duration: Duration(seconds: 1),
            ),
          );

          await Future.delayed(const Duration(milliseconds: 500));

          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          }
        }
      }
    } on AuthException catch (e) {
      if (mounted) {
        _showErrorSnackBar('Giriş hatası: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Beklenmeyen hata: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // GOOGLE SIGN IN (WITH SAFETY CHECK)
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw 'Google auth tokens are null';
      }

      final response = await SupabaseConfig.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      if (response.user != null) {
        // ⚡ SAFETY CHECK
        await _ensureUserRecordExists(response.user!);

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Google ile giriş hatası: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // APPLE SIGN IN (WITH SAFETY CHECK)
  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        webAuthenticationOptions: Platform.isAndroid
            ? WebAuthenticationOptions(
                clientId: 'com.yansimam.mobile',
                redirectUri: Uri.parse(
                  'https://mwuvhprizozvpcqhfkvi.supabase.co/auth/v1/callback',
                ),
              )
            : null,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        throw 'Apple ID token is null';
      }

      final response = await SupabaseConfig.auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );

      if (response.user != null) {
        // ⚡ SAFETY CHECK
        await _ensureUserRecordExists(response.user!);

        if (mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/home',
            (route) => false,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Apple ile giriş hatası: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // FACEBOOK SIGN IN (WITH SAFETY CHECK)
  Future<void> _signInWithFacebook() async {
    setState(() => _isLoading = true);
    try {
      final LoginResult result = await FacebookAuth.instance.login();

      if (result.status == LoginStatus.success) {
        final accessToken = result.accessToken!.tokenString;

        final response = await SupabaseConfig.auth.signInWithIdToken(
          provider: OAuthProvider.facebook,
          idToken: accessToken,
        );

        if (response.user != null) {
          // ⚡ SAFETY CHECK
          await _ensureUserRecordExists(response.user!);

          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil(
              '/home',
              (route) => false,
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Facebook ile giriş hatası: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // PLACEHOLDER FOR OTHER PROVIDERS
  Future<void> _signInWithProvider(String provider) async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$provider ile giriş yakında eklenecek!'),
        backgroundColor: const Color(0xFF009DE0),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF6B6B),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
              Color(0xFF004563),
              Color(0xFF009DE0),
            ],
          ),
        ),
        child: SafeArea(
          child: _isLoading
              ? const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 3,
                  ),
                )
              : FadeTransition(
                  opacity: _fadeAnimation,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      children: [
                        const SizedBox(height: 60),

                        // Logo
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 30,
                                offset: const Offset(0, 10),
                                spreadRadius: 5,
                              ),
                            ],
                          ),
                          child: const Center(
                            child: Text(
                              'Y',
                              style: TextStyle(
                                fontSize: 58,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF009DE0),
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        // App name
                        const Text(
                          'YANSIMAM',
                          style: TextStyle(
                            fontSize: 34,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            letterSpacing: 2.5,
                            shadows: [
                              Shadow(
                                color: Colors.black26,
                                offset: Offset(0, 2),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Tagline
                        const Text(
                          'Dijital Kimlik Doğrulama',
                          style: TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),

                        const SizedBox(height: 40),

                        // EMAIL/USERNAME LOGIN FORM
                        if (_showEmailLogin)
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.95),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 20,
                                  offset: const Offset(0, 5),
                                ),
                              ],
                            ),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                children: [
                                  TextFormField(
                                    controller: _emailController,
                                    keyboardType: TextInputType.emailAddress,
                                    decoration: InputDecoration(
                                      labelText: 'E-posta veya Kullanıcı Adı',
                                      prefixIcon: const Icon(Icons.person),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'E-posta veya kullanıcı adı zorunludur';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),
                                  TextFormField(
                                    controller: _passwordController,
                                    obscureText: true,
                                    decoration: InputDecoration(
                                      labelText: 'Şifre',
                                      prefixIcon: const Icon(Icons.lock),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      filled: true,
                                      fillColor: Colors.white,
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Şifre zorunludur';
                                      }
                                      if (value.length < 6) {
                                        return 'Şifre en az 6 karakter olmalı';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 20),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 50,
                                    child: ElevatedButton(
                                      onPressed: _signInWithEmail,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor:
                                            const Color(0xFF009DE0),
                                        foregroundColor: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: const Text(
                                        'Giriş Yap',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  TextButton(
                                    onPressed: () {
                                      setState(() => _showEmailLogin = false);
                                    },
                                    child: const Text(
                                      'Sosyal Medya ile Giriş Yap',
                                      style:
                                          TextStyle(color: Color(0xFF009DE0)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          Column(
                            children: [
                              _buildPremiumOAuthButton(
                                'E-posta ile Giriş Yap',
                                '',
                                Colors.white,
                                const Color(0xFF004563),
                                () {
                                  setState(() => _showEmailLogin = true);
                                },
                                icon: Icons.email,
                              ),

                              const SizedBox(height: 24),

                              // Divider
                              Row(
                                children: [
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      thickness: 1,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16),
                                    child: Text(
                                      'veya',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Divider(
                                      color: Colors.white.withValues(alpha: 0.3),
                                      thickness: 1,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),

                              // OAuth Buttons (10 providers)
                              _buildPremiumOAuthButton(
                                'Google ile Devam Et',
                                '',
                                Colors.white,
                                const Color(0xFF004563),
                                _signInWithGoogle,
                                icon: Icons.g_mobiledata,
                              ),

                              const SizedBox(height: 14),

                              if (Platform.isIOS)
                                _buildPremiumOAuthButton(
                                  'Apple ile Devam Et',
                                  '',
                                  Colors.black,
                                  Colors.white,
                                  _signInWithApple,
                                  icon: Icons.apple,
                                ),

                              if (Platform.isIOS) const SizedBox(height: 14),

                              _buildPremiumOAuthButton(
                                'Facebook ile Devam Et',
                                '',
                                const Color(0xFF1877F2),
                                Colors.white,
                                _signInWithFacebook,
                                icon: Icons.facebook,
                              ),

                              const SizedBox(height: 14),

                              _buildPremiumOAuthButton(
                                'X ile Devam Et',
                                '',
                                Colors.black,
                                Colors.white,
                                () => _signInWithProvider('X'),
                                icon: Icons.close,
                              ),

                              const SizedBox(height: 14),

                              _buildPremiumOAuthButton(
                                'Instagram ile Devam Et',
                                '',
                                const Color(0xFFE4405F),
                                Colors.white,
                                () => _signInWithProvider('Instagram'),
                                icon: Icons.camera_alt,
                              ),

                              const SizedBox(height: 14),

                              _buildPremiumOAuthButton(
                                'WhatsApp ile Devam Et',
                                '',
                                const Color(0xFF25D366),
                                Colors.white,
                                () => _signInWithProvider('WhatsApp'),
                                icon: Icons.chat,
                              ),

                              const SizedBox(height: 14),

                              _buildPremiumOAuthButton(
                                'LinkedIn ile Devam Et',
                                '',
                                const Color(0xFF0A66C2),
                                Colors.white,
                                () => _signInWithProvider('LinkedIn'),
                                icon: Icons.business,
                              ),

                              const SizedBox(height: 14),

                              _buildPremiumOAuthButton(
                                'TikTok ile Devam Et',
                                '',
                                Colors.black,
                                Colors.white,
                                () => _signInWithProvider('TikTok'),
                                icon: Icons.music_note,
                              ),

                              const SizedBox(height: 14),

                              _buildPremiumOAuthButton(
                                'Pinterest ile Devam Et',
                                '',
                                const Color(0xFFE60023),
                                Colors.white,
                                () => _signInWithProvider('Pinterest'),
                                icon: Icons.push_pin,
                              ),

                              const SizedBox(height: 14),

                              _buildPremiumOAuthButton(
                                'Snapchat ile Devam Et',
                                '',
                                const Color(0xFFFFFC00),
                                Colors.black,
                                () => _signInWithProvider('Snapchat'),
                                icon: Icons.camera,
                              ),
                            ],
                          ),

                        const SizedBox(height: 40),

                        // Register prompt
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'Hesabınız yok mu? ',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 15,
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  Navigator.of(context).pushNamed('/register');
                                },
                                child: const Text(
                                  'Kayıt Olun',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    decoration: TextDecoration.underline,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  // Premium OAuth Button Widget
  Widget _buildPremiumOAuthButton(
    String text,
    String iconPath,
    Color backgroundColor,
    Color textColor,
    VoidCallback onPressed, {
    IconData? icon,
  }) {
    return Container(
      width: double.infinity,
      height: 58,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: backgroundColor.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        child: Row(
          children: [
            if (icon != null)
              Icon(icon, size: 24, color: textColor)
            else
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: textColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                text,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: textColor.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}

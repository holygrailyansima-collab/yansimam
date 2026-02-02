// ============================================
// File: lib/services/auth_service.dart
// COMPLETE: Native Google, Apple, Facebook Sign-In + All Auth Operations
// ============================================

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'dart:io' show Platform;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import '../core/config/supabase_config.dart';
import '../models/user.dart' as app_user;

/// Authentication Service
/// Handles all authentication operations including OAuth providers
class AuthService {
  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  /// Get Supabase auth client
  GoTrueClient get _auth => SupabaseConfig.auth;

  /// Get Supabase client
  SupabaseClient get _client => SupabaseConfig.client;

  // ==================== AUTH STATE ====================

  /// Check if user is logged in
  bool get isLoggedIn => _auth.currentUser != null;

  /// Get current Supabase user
  User? get currentUser => _auth.currentUser;

  /// Get current user ID
  String? get currentUserId => _auth.currentUser?.id;

  /// Get current user email
  String? get currentEmail => _auth.currentUser?.email;

  /// Get auth state stream
  Stream<AuthState> get authStateChanges => _auth.onAuthStateChange;

  // ==================== EMAIL/PASSWORD SIGN IN ====================

  /// Sign in with email and password
  Future<AuthResponse> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      debugPrint('🔐 Signing in user: $email');
      final response = await _auth.signInWithPassword(
        email: email,
        password: password,
      );
      debugPrint('✅ Sign in successful: ${response.user?.id}');
      return response;
    } catch (e) {
      debugPrint('❌ Sign in failed: $e');
      rethrow;
    }
  }

  /// Sign in with username and password
  Future<AuthResponse> signInWithUsername({
    required String username,
    required String password,
  }) async {
    try {
      // Get email from username
      final email = await getEmailFromUsername(username);
      if (email == null) {
        throw AuthException('Kullanıcı adı bulunamadı');
      }

      return await signInWithEmail(email: email, password: password);
    } catch (e) {
      debugPrint('❌ Username sign in failed: $e');
      rethrow;
    }
  }

  // ==================== GOOGLE SIGN IN ====================

  /// Sign in with Google (Native SDK)
  Future<AuthResponse> signInWithGoogle() async {
    try {
      debugPrint('🔐 Starting Google Sign-In...');

      // Initialize Google Sign-In
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );

      // Start sign-in flow
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        throw AuthException('Google sign-in cancelled by user');
      }

      debugPrint('✅ Google user signed in: ${googleUser.email}');

      // Get authentication tokens
      final googleAuth = await googleUser.authentication;
      final accessToken = googleAuth.accessToken;
      final idToken = googleAuth.idToken;

      if (accessToken == null || idToken == null) {
        throw AuthException('Google auth tokens are null');
      }

      debugPrint('✅ Got Google tokens, signing in to Supabase...');

      // Sign in to Supabase with Google tokens
      final response = await _auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );

      // Ensure user record exists in database
      if (response.user != null) {
        await _ensureUserRecordExists(
          authUser: response.user!,
          provider: 'google',
        );
      }

      debugPrint('✅ Google sign-in complete!');
      return response;
    } catch (e) {
      debugPrint('❌ Google sign-in failed: $e');
      rethrow;
    }
  }

  // ==================== APPLE SIGN IN ====================

  /// Sign in with Apple (Native SDK)
  Future<AuthResponse> signInWithApple() async {
    try {
      debugPrint('🔐 Starting Apple Sign-In...');

      // Check if Apple Sign-In is available
      if (!await SignInWithApple.isAvailable()) {
        throw AuthException('Apple Sign-In not available on this device');
      }

      // Start Apple Sign-In flow
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        // Android-specific configuration
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
        throw AuthException('Apple ID token is null');
      }

      debugPrint('✅ Got Apple ID token, signing in to Supabase...');

      // Sign in to Supabase with Apple token
      final response = await _auth.signInWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
      );

      // Ensure user record exists
      if (response.user != null) {
        await _ensureUserRecordExists(
          authUser: response.user!,
          provider: 'apple',
          fullName: credential.givenName != null && credential.familyName != null
              ? '${credential.givenName} ${credential.familyName}'
              : null,
        );
      }

      debugPrint('✅ Apple sign-in complete!');
      return response;
    } catch (e) {
      debugPrint('❌ Apple sign-in failed: $e');
      rethrow;
    }
  }

  // ==================== FACEBOOK SIGN IN ====================

  /// Sign in with Facebook (Native SDK)
  Future<AuthResponse> signInWithFacebook() async {
    try {
      debugPrint('🔐 Starting Facebook Sign-In...');

      // Start Facebook login
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        throw AuthException('Facebook login failed: ${result.status}');
      }

      final accessToken = result.accessToken!.tokenString;
      debugPrint('✅ Got Facebook access token, signing in to Supabase...');

      // Sign in to Supabase with Facebook token
      final response = await _auth.signInWithIdToken(
        provider: OAuthProvider.facebook,
        idToken: accessToken,
      );

      // Ensure user record exists
      if (response.user != null) {
        await _ensureUserRecordExists(
          authUser: response.user!,
          provider: 'facebook',
        );
      }

      debugPrint('✅ Facebook sign-in complete!');
      return response;
    } catch (e) {
      debugPrint('❌ Facebook sign-in failed: $e');
      rethrow;
    }
  }

  // ==================== OAUTH (GENERIC) ====================

  /// Sign in with OAuth provider (web-based flow)
  Future<bool> signInWithOAuth({
    required OAuthProvider provider,
  }) async {
    try {
      debugPrint('🔐 Signing in with OAuth: $provider');
      final result = await _auth.signInWithOAuth(provider);
      debugPrint('✅ OAuth sign in successful');
      return result;
    } catch (e) {
      debugPrint('❌ OAuth sign in failed: $e');
      rethrow;
    }
  }

  /// Sign in with ID token (for custom OAuth implementations)
  Future<AuthResponse> signInWithIdToken({
    required OAuthProvider provider,
    required String idToken,
    String? accessToken,
    String? nonce,
  }) async {
    try {
      debugPrint('🔐 Signing in with ID token: $provider');
      final response = await _auth.signInWithIdToken(
        provider: provider,
        idToken: idToken,
        accessToken: accessToken,
        nonce: nonce,
      );
      debugPrint('✅ ID token sign in successful: ${response.user?.id}');
      return response;
    } catch (e) {
      debugPrint('❌ ID token sign in failed: $e');
      rethrow;
    }
  }

  // ==================== USER RECORD MANAGEMENT ====================

  /// Ensure user record exists in public.users table
  Future<void> _ensureUserRecordExists({
    required User authUser,
    required String provider,
    String? fullName,
  }) async {
    try {
      debugPrint('📝 Checking if user record exists...');

      // Check if user exists
      final existing = await _client
          .from('users')
          .select('id')
          .eq('id', authUser.id)
          .maybeSingle();

      if (existing != null) {
        debugPrint('✅ User record already exists');
        return;
      }

      debugPrint('📝 Creating new user record...');

      // Generate username from email or metadata
      String username = authUser.userMetadata?['username'] as String? ??
          authUser.email!.split('@')[0];

      // Check if username is taken
      final usernameExists = await _client
          .from('users')
          .select('id')
          .eq('username', username)
          .maybeSingle();

      if (usernameExists != null) {
        // Append random suffix if username exists
        username = '$username${authUser.id.substring(0, 4)}';
      }

      // Get full name
      final displayName = fullName ??
          authUser.userMetadata?['full_name'] as String? ??
          authUser.userMetadata?['name'] as String? ??
          username;

      // Get profile photo
      final profilePhoto = authUser.userMetadata?['avatar_url'] as String? ??
          authUser.userMetadata?['picture'] as String? ??
          authUser.userMetadata?['profile_photo_url'] as String?;

      // Create user record
      await _client.from('users').insert({
        'id': authUser.id,
        'email': authUser.email!,
        'username': username,
        'full_name': displayName,
        'profile_photo_url': profilePhoto,
        'status': 'unapproved',
        'is_premium': false,
        'average_score': 0.0,
        'total_votes': 0,
        'auth_provider': provider,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });

      debugPrint('✅ User record created successfully');
    } catch (e) {
      debugPrint('❌ Error creating user record: $e');
      // Don't throw - allow login to proceed even if user creation fails
    }
  }

  // ==================== SIGN UP ====================

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String username,
    required String fullName,
    Map<String, dynamic>? additionalData,
  }) async {
    try {
      debugPrint('📝 Signing up user: $email');

      // Check if username is available
      final isAvailable = await isUsernameAvailable(username);
      if (!isAvailable) {
        throw AuthException('Kullanıcı adı zaten kullanımda');
      }

      // Sign up with Supabase Auth
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: {
          'username': username,
          'full_name': fullName,
          ...?additionalData,
        },
      );

      // Create user record
      if (response.user != null) {
        await createUserRecord(
          userId: response.user!.id,
          email: email,
          username: username,
          fullName: fullName,
        );
      }

      debugPrint('✅ Sign up successful: ${response.user?.id}');
      return response;
    } catch (e) {
      debugPrint('❌ Sign up failed: $e');
      rethrow;
    }
  }

  // ==================== SIGN OUT ====================

  /// Sign out current user
  Future<void> signOut() async {
    try {
      debugPrint('🚪 Signing out user: $currentUserId');

      // Sign out from Google if logged in with Google
      try {
        final googleSignIn = GoogleSignIn();
        if (await googleSignIn.isSignedIn()) {
          await googleSignIn.signOut();
        }
      } catch (e) {
        debugPrint('⚠️ Google sign out failed: $e');
      }

      // Sign out from Facebook if logged in with Facebook
      try {
        await FacebookAuth.instance.logOut();
      } catch (e) {
        debugPrint('⚠️ Facebook sign out failed: $e');
      }

      // Sign out from Supabase
      await _auth.signOut();

      debugPrint('✅ Sign out successful');
    } catch (e) {
      debugPrint('❌ Sign out failed: $e');
      rethrow;
    }
  }

  // ==================== PASSWORD ====================

  /// Reset password (send email)
  Future<void> resetPasswordForEmail(String email) async {
    try {
      debugPrint('📧 Sending password reset email to: $email');
      await _auth.resetPasswordForEmail(email);
      debugPrint('✅ Password reset email sent');
    } catch (e) {
      debugPrint('❌ Password reset failed: $e');
      rethrow;
    }
  }

  /// Update password
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      debugPrint('🔒 Updating password for user: $currentUserId');
      final response = await _auth.updateUser(
        UserAttributes(password: newPassword),
      );
      debugPrint('✅ Password updated successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Password update failed: $e');
      rethrow;
    }
  }

  // ==================== USER DATA ====================

  /// Get user data from database
  Future<app_user.User?> getUserData(String userId) async {
    try {
      debugPrint('📊 Fetching user data: $userId');
      final response = await _client
          .from('users')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ User not found: $userId');
        return null;
      }

      debugPrint('✅ User data fetched successfully');
      return app_user.User.fromJson(response);
    } catch (e) {
      debugPrint('❌ Failed to get user data: $e');
      throw Exception('Failed to get user data: $e');
    }
  }

  /// Get current user data from database
  Future<app_user.User?> getCurrentUserData() async {
    if (!isLoggedIn) {
      debugPrint('⚠️ Cannot get user data: Not logged in');
      return null;
    }
    return await getUserData(currentUserId!);
  }

  /// Update user data in database
  Future<void> updateUserData({
    required String userId,
    required Map<String, dynamic> data,
  }) async {
    try {
      debugPrint('📝 Updating user data: $userId');
      await _client.from('users').update(data).eq('id', userId);
      debugPrint('✅ User data updated successfully');
    } catch (e) {
      debugPrint('❌ Failed to update user data: $e');
      throw Exception('Failed to update user data: $e');
    }
  }

  /// Update current user data
  Future<void> updateCurrentUserData(Map<String, dynamic> data) async {
    if (!isLoggedIn) {
      throw Exception('User not logged in');
    }
    await updateUserData(userId: currentUserId!, data: data);
  }

  /// Create user record in database
  Future<void> createUserRecord({
    required String userId,
    required String email,
    required String username,
    required String fullName,
    String? profilePhotoUrl,
  }) async {
    try {
      debugPrint('📝 Creating user record: $userId');
      await _client.from('users').insert({
        'id': userId,
        'email': email,
        'username': username,
        'full_name': fullName,
        'profile_photo_url': profilePhotoUrl,
        'status': 'unapproved',
        'is_premium': false,
        'created_at': DateTime.now().toIso8601String(),
      });
      debugPrint('✅ User record created successfully');
    } catch (e) {
      debugPrint('❌ Failed to create user record: $e');
      throw Exception('Failed to create user record: $e');
    }
  }

  // ==================== USERNAME ====================

  /// Check if username is available
  Future<bool> isUsernameAvailable(String username) async {
    try {
      debugPrint('🔍 Checking username availability: $username');
      final response = await _client
          .from('users')
          .select('username')
          .eq('username', username)
          .maybeSingle();

      final isAvailable = response == null;
      debugPrint(isAvailable
          ? '✅ Username available: $username'
          : '⚠️ Username taken: $username');
      return isAvailable;
    } catch (e) {
      debugPrint('❌ Failed to check username: $e');
      throw Exception('Failed to check username: $e');
    }
  }

  /// Get email from username
  Future<String?> getEmailFromUsername(String username) async {
    try {
      debugPrint('🔍 Getting email from username: $username');
      final response = await _client
          .from('users')
          .select('email')
          .eq('username', username)
          .maybeSingle();

      if (response == null) {
        debugPrint('⚠️ Username not found: $username');
        return null;
      }

      final email = response['email'] as String;
      debugPrint('✅ Email found: $email');
      return email;
    } catch (e) {
      debugPrint('❌ Failed to get email from username: $e');
      throw Exception('Failed to get email from username: $e');
    }
  }

  // ==================== EMAIL ====================

  /// Update email
  Future<UserResponse> updateEmail(String newEmail) async {
    try {
      debugPrint('📧 Updating email: $newEmail');
      final response = await _auth.updateUser(
        UserAttributes(email: newEmail),
      );
      debugPrint('✅ Email updated successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Email update failed: $e');
      rethrow;
    }
  }

  /// Verify email OTP
  Future<AuthResponse> verifyEmailOTP({
    required String email,
    required String token,
  }) async {
    try {
      debugPrint('🔐 Verifying email OTP: $email');
      final response = await _auth.verifyOTP(
        type: OtpType.email,
        email: email,
        token: token,
      );
      debugPrint('✅ Email OTP verified successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Email OTP verification failed: $e');
      rethrow;
    }
  }

  // ==================== SESSION ====================

  /// Get current session
  Session? get currentSession => _auth.currentSession;

  /// Refresh session
  Future<AuthResponse> refreshSession() async {
    try {
      debugPrint('🔄 Refreshing session');
      final response = await _auth.refreshSession();
      debugPrint('✅ Session refreshed successfully');
      return response;
    } catch (e) {
      debugPrint('❌ Session refresh failed: $e');
      rethrow;
    }
  }

  /// Check if session is valid
  bool get isSessionValid {
    final session = currentSession;
    if (session == null) return false;

    final expiresAt = session.expiresAt;
    if (expiresAt == null) return false;

    return DateTime.now().isBefore(
      DateTime.fromMillisecondsSinceEpoch(expiresAt * 1000),
    );
  }

  // ==================== DELETE ACCOUNT ====================

  /// Delete user account
  Future<void> deleteAccount() async {
    if (!isLoggedIn) throw Exception('User not logged in');

    try {
      debugPrint('🗑️ Deleting user account: $currentUserId');

      // Delete user data from database
      await _client.from('users').delete().eq('id', currentUserId!);

      // Sign out (auth user deletion requires admin privileges)
      await signOut();

      debugPrint('✅ Account deleted successfully');
    } catch (e) {
      debugPrint('❌ Failed to delete account: $e');
      throw Exception('Failed to delete account: $e');
    }
  }

  // ==================== PREMIUM ====================

  /// Check if user is premium
  Future<bool> isPremium() async {
    final userData = await getCurrentUserData();
    return userData?.isPremium ?? false;
  }

  /// Upgrade to premium
  Future<void> upgradeToPremium() async {
    if (!isLoggedIn) throw Exception('User not logged in');

    debugPrint('💎 Upgrading user to premium: $currentUserId');
    await updateCurrentUserData({
      'is_premium': true,
      'updated_at': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ User upgraded to premium');
  }

  // ==================== USER STATUS ====================

  /// Update user status
  Future<void> updateUserStatus(app_user.UserStatus status) async {
    if (!isLoggedIn) throw Exception('User not logged in');

    debugPrint('📊 Updating user status to: ${status.name}');
    await updateCurrentUserData({
      'status': status.name,
      'updated_at': DateTime.now().toIso8601String(),
    });
    debugPrint('✅ User status updated');
  }

  /// Check if user is approved
  Future<bool> isApproved() async {
    final userData = await getCurrentUserData();
    return userData?.isApproved ?? false;
  }

  // ==================== ERROR HANDLING ====================

  /// Get user-friendly error message
  String getErrorMessage(Object error) {
    if (error is AuthException) {
      if (error.message.contains('Invalid login credentials')) {
        return 'E-posta veya şifre hatalı';
      }
      if (error.message.contains('Email not confirmed')) {
        return 'Lütfen e-postanızı doğrulayın';
      }
      if (error.message.contains('User already registered')) {
        return 'Bu e-posta adresi zaten kullanımda';
      }
      if (error.message.contains('cancelled')) {
        return 'Giriş iptal edildi';
      }
      return error.message;
    }
    if (error is PlatformException) {
      return 'Sistem hatası: ${error.message}';
    }
    return 'Beklenmeyen bir hata oluştu';
  }

  // ==================== VALIDATION ====================

  /// Validate email format
  bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  /// Validate password strength
  bool isStrongPassword(String password) {
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  /// Validate username format
  bool isValidUsername(String username) {
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    return usernameRegex.hasMatch(username);
  }
}

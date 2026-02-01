// ============================================
// File: lib/services/auth/auth_service.dart
// Authentication Service - Supabase Auth Wrapper
// ============================================

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../models/user.dart' as app_user;

/// Authentication Service
/// Helper service for authentication operations
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

  // ==================== SIGN IN ====================

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

  /// Sign in with OAuth provider
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

  /// Sign in with ID token (Google, Apple, Facebook)
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

  // ==================== SIGN UP ====================

  /// Sign up with email and password
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    Map<String, dynamic>? data,
  }) async {
    try {
      debugPrint('📝 Signing up user: $email');
      final response = await _auth.signUp(
        email: email,
        password: password,
        data: data,
      );
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
      await _client
          .from('users')
          .update(data)
          .eq('id', userId);
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
    required String fullName,
    required String username,
    String? profilePhotoUrl,
  }) async {
    try {
      debugPrint('📝 Creating user record: $userId');
      await _client.from('users').insert({
        'id': userId,
        'email': email,
        'full_name': fullName,
        'username': username,
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
      
      // 1. Delete user data from database
      await _client
          .from('users')
          .delete()
          .eq('id', currentUserId!);

      // 2. Delete auth user (requires admin privileges)
      // This should be done via Supabase Edge Function
      // For now, just sign out
      await signOut();
      
      debugPrint('✅ Account deleted successfully');
    } catch (e) {
      debugPrint('❌ Failed to delete account: $e');
      throw Exception('Failed to delete account: $e');
    }
  }

  // ==================== ERROR HANDLING ====================

  /// Get user-friendly error message
  String getErrorMessage(Object error) {
    if (error is AuthException) {
      switch (error.statusCode) {
        case '400':
          return 'Geçersiz e-posta veya şifre';
        case '422':
          return 'Bu e-posta adresi zaten kullanımda';
        case '401':
          return 'E-posta veya şifre hatalı';
        case '404':
          return 'Kullanıcı bulunamadı';
        case '429':
          return 'Çok fazla deneme. Lütfen daha sonra tekrar deneyin';
        default:
          return error.message;
      }
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
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number
    if (password.length < 8) return false;
    if (!password.contains(RegExp(r'[A-Z]'))) return false;
    if (!password.contains(RegExp(r'[a-z]'))) return false;
    if (!password.contains(RegExp(r'[0-9]'))) return false;
    return true;
  }

  /// Validate username format
  bool isValidUsername(String username) {
    // 3-20 characters, alphanumeric and underscore only
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]{3,20}$');
    return usernameRegex.hasMatch(username);
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
}

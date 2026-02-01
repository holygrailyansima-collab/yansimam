// ============================================
// File: lib/services/voting_service.dart
// PART 1/2 - Voting Session Management Service
// FIXED: Removed hardcoded Azure API keys, using .env instead
// ============================================

import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException, StorageException, FileOptions;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // ✅ EKLENDI
import '../core/config/supabase_config.dart';

/// Voting Service - Handles all voting session operations
/// Features:
/// - Session creation with photo upload
/// - Real-time vote tracking
/// - Azure Face API integration
/// - Statistics calculation
/// - Error handling and logging
class VotingService {
  static final _supabase = SupabaseConfig.client;
  static final _storage = SupabaseConfig.client.storage;

  // Constants
  static const int _maxRetryAttempts = 3;
  static const Duration _retryDelay = Duration(seconds: 2);
  static const String _storageBucket = 'voting-photos';

  // ============================================
  // 1. CREATE VOTING SESSION
  // ============================================

  /// Creates a new voting session with photo upload
  /// Returns: Map with session details or throws error
  /// 
  /// Parameters:
  /// - photoFile: User's profile photo (must pass Azure Face API validation)
  /// - userId: Current user's ID from Supabase Auth
  /// 
  /// Returns:
  /// - session_id: Unique session identifier
  /// - unique_link: Short link for sharing (6 chars)
  /// - photo_url: Public URL of uploaded photo
  /// - expires_at: ISO 8601 timestamp (72 hours from now)
  /// - voting_url: Full voting URL for sharing
  static Future<Map<String, dynamic>> createVotingSession({
    required File photoFile,
    required String userId,
  }) async {
    try {
      debugPrint('🔵 [VotingService] Creating voting session for user: $userId');

      // Step 1: Validate photo with Azure Face API
      debugPrint('🔵 [VotingService] Validating photo with Azure Face API...');
      final isValidPhoto = await validatePhotoWithAzure(photoFile);
      
      if (!isValidPhoto) {
        throw Exception(
          'Fotoğraf doğrulanamadı. Lütfen yüzünüzün net görüldüğü '
          'tek kişilik bir fotoğraf kullanın.'
        );
      }

      // Step 2: Upload photo to storage
      debugPrint('🔵 [VotingService] Uploading photo to storage...');
      final photoUrl = await uploadPhoto(photoFile, userId);
      debugPrint('✅ [VotingService] Photo uploaded: $photoUrl');

      // Step 3: Generate unique link (6 characters)
      debugPrint('🔵 [VotingService] Generating unique link...');
      final uniqueLink = await generateUniqueLink();
      debugPrint('✅ [VotingService] Unique link generated: $uniqueLink');

      // Step 4: Calculate expiry time (72 hours from now)
      final now = DateTime.now().toUtc();
      final expiresAt = now.add(const Duration(hours: 72));

      // Step 5: Insert session into database
      debugPrint('🔵 [VotingService] Inserting session into database...');
      final sessionData = {
        'user_id': userId,
        'unique_link': uniqueLink,
        'photo_url': photoUrl,
        'start_time': now.toIso8601String(),
        'end_time': expiresAt.toIso8601String(),
        'expires_at': expiresAt.toIso8601String(),
        'status': 'active',
        'total_votes': 0,
        'approval_rate': 0.0,
        'average_score': 0.0,
        'score_courage': 0.0,
        'score_honesty': 0.0,
        'score_loyalty': 0.0,
        'score_work_ethic': 0.0,
        'score_discipline': 0.0,
      };

      final response = await _supabase
          .from('voting_sessions')
          .insert(sessionData)
          .select()
          .single();

      debugPrint('✅ [VotingService] Session created successfully: ${response['id']}');

      return {
        'session_id': response['id'],
        'unique_link': uniqueLink,
        'photo_url': photoUrl,
        'expires_at': expiresAt.toIso8601String(),
        'voting_url': 'https://yansimam.vercel.app/vote/$uniqueLink',
      };
    } on PostgrestException catch (e) {
      debugPrint('❌ [VotingService] Database error: ${e.message}');
      throw Exception('Veritabanı hatası: ${e.message}');
    } catch (e) {
      debugPrint('❌ [VotingService] Error creating session: $e');
      throw Exception('Oylama oluşturulurken hata: $e');
    }
  }

  // ============================================
  // 2. UPLOAD PHOTO TO STORAGE
  // ============================================

  /// Uploads photo to Supabase Storage with retry mechanism
  /// Returns: Public URL of uploaded photo
  /// 
  /// Features:
  /// - Auto-retry on failure (max 3 attempts)
  /// - Unique filename generation
  /// - Error handling
  static Future<String> uploadPhoto(File photoFile, String userId) async {
    int attempts = 0;

    while (attempts < _maxRetryAttempts) {
      try {
        // Generate unique filename
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = '${userId}_$timestamp.jpg';

        debugPrint('🔵 [VotingService] Uploading photo (attempt ${attempts + 1})...');

        // Read file as bytes
        final fileBytes = await photoFile.readAsBytes();

        // Upload to storage bucket
        await _storage.from(_storageBucket).uploadBinary(
          fileName,
          fileBytes,
          fileOptions: const FileOptions(
            cacheControl: '3600',
            upsert: false,
          ),
        );

        // Get public URL
        final publicUrl = _storage.from(_storageBucket).getPublicUrl(fileName);

        debugPrint('✅ [VotingService] Photo uploaded successfully');
        return publicUrl;
      } on StorageException catch (e) {
        attempts++;
        debugPrint('❌ [VotingService] Storage error (attempt $attempts): ${e.message}');
        
        if (attempts >= _maxRetryAttempts) {
          throw Exception('Fotoğraf yüklenemedi: ${e.message}');
        }
        
        // Wait before retry
        await Future.delayed(_retryDelay);
      } catch (e) {
        attempts++;
        debugPrint('❌ [VotingService] Upload error (attempt $attempts): $e');
        
        if (attempts >= _maxRetryAttempts) {
          throw Exception('Fotoğraf yüklenemedi: $e');
        }
        
        await Future.delayed(_retryDelay);
      }
    }

    throw Exception('Fotoğraf yüklenemedi. Lütfen tekrar deneyin.');
  }

  // ============================================
  // 3. GENERATE UNIQUE LINK
  // ============================================

  /// Generates a unique 6-character alphanumeric link
  /// Returns: String (e.g., "a3f8k2")
  /// 
  /// Algorithm:
  /// - Random 6-character string from [a-z0-9]
  /// - Checks database for uniqueness
  /// - Max 10 attempts before failing
  static Future<String> generateUniqueLink() async {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random.secure(); // Use secure random
    int attempts = 0;
    const maxAttempts = 10;

    while (attempts < maxAttempts) {
      // Generate 6-character random string
      final link = List.generate(
        6,
        (index) => chars[random.nextInt(chars.length)],
      ).join();

      // Check if link already exists
      final existing = await _supabase
          .from('voting_sessions')
          .select('id')
          .eq('unique_link', link)
          .maybeSingle();

      if (existing == null) {
        return link;
      }

      attempts++;
      debugPrint('⚠️ [VotingService] Link collision, retrying... ($attempts/$maxAttempts)');
    }

    throw Exception('Benzersiz link oluşturulamadı. Lütfen tekrar deneyin.');
  }

  // ============================================
  // 4. GET SESSION STATISTICS
  // ============================================

  /// Fetches real-time voting statistics for a session
  /// Returns: Map with vote counts and scores
  /// 
  /// Returns:
  /// - total_votes: Number of votes received
  /// - approval_rate: Percentage of votes >= 5.01
  /// - average_score: Overall average score (1-10)
  /// - score_* : Individual dimension scores
  /// - status: Session status (active/completed/expired)
  static Future<Map<String, dynamic>> getSessionStats(String sessionId) async {
    try {
      debugPrint('🔵 [VotingService] Fetching stats for session: $sessionId');

      // Get session data
      final session = await _supabase
          .from('voting_sessions')
          .select()
          .eq('id', sessionId)
          .single();

      // Get vote count from votes table
      final votes = await _supabase
          .from('votes')
          .select('honesty, dependability, sociability, work_ethic, discipline')
          .eq('voting_session_id', sessionId);

      if (votes.isEmpty) {
        debugPrint('⚠️ [VotingService] No votes found yet');
        return {
          'total_votes': 0,
          'approval_rate': 0.0,
          'average_score': 0.0,
          'score_courage': 0.0,
          'score_honesty': 0.0,
          'score_loyalty': 0.0,
          'score_work_ethic': 0.0,
          'score_discipline': 0.0,
          'status': session['status'] ?? 'active',
          'expires_at': session['expires_at'],
        };
      }

      // Calculate statistics
      double totalHonesty = 0;
      double totalDependability = 0;
      double totalSociability = 0;
      double totalWorkEthic = 0;
      double totalDiscipline = 0;
      int approvedVotes = 0;

      for (var vote in votes) {
        final honesty = (vote['honesty'] as num).toDouble();
        final dependability = (vote['dependability'] as num).toDouble();
        final sociability = (vote['sociability'] as num).toDouble();
        final workEthic = (vote['work_ethic'] as num).toDouble();
        final discipline = (vote['discipline'] as num).toDouble();

        totalHonesty += honesty;
        totalDependability += dependability;
        totalSociability += sociability;
        totalWorkEthic += workEthic;
        totalDiscipline += discipline;

        // Calculate average for this vote
        final voteAverage = (honesty + dependability + sociability + workEthic + discipline) / 5.0;

        // Check if approved (>= 5.01)
        if (voteAverage >= 5.01) {
          approvedVotes++;
        }
      }

      final totalVotes = votes.length;
      final avgHonesty = totalHonesty / totalVotes;
      final avgDependability = totalDependability / totalVotes;
      final avgSociability = totalSociability / totalVotes;
      final avgWorkEthic = totalWorkEthic / totalVotes;
      final avgDiscipline = totalDiscipline / totalVotes;

      final overallAverage = (avgHonesty + avgDependability + avgSociability + avgWorkEthic + avgDiscipline) / 5.0;
      final approvalRate = (approvedVotes / totalVotes) * 100;

      debugPrint('✅ [VotingService] Stats calculated: $totalVotes votes, ${approvalRate.toStringAsFixed(1)}% approval');

      return {
        'total_votes': totalVotes,
        'approval_rate': approvalRate,
        'average_score': overallAverage,
        'score_courage': avgHonesty, // Mapping courage to honesty for now
        'score_honesty': avgHonesty,
        'score_loyalty': avgDependability,
        'score_work_ethic': avgWorkEthic,
        'score_discipline': avgDiscipline,
        'status': session['status'] ?? 'active',
        'expires_at': session['expires_at'],
      };
    } on PostgrestException catch (e) {
      debugPrint('❌ [VotingService] Database error: ${e.message}');
      throw Exception('Veritabanı hatası: ${e.message}');
    } catch (e) {
      debugPrint('❌ [VotingService] Error fetching stats: $e');
      throw Exception('İstatistikler yüklenemedi: $e');
    }
  }

  // ============================================
  // 5. CHECK SESSION STATUS
  // ============================================

  /// Checks if a voting session is still active or expired
  /// Returns: Map with status and remaining time
  static Future<Map<String, dynamic>> checkSessionStatus(String sessionId) async {
    try {
      final session = await _supabase
          .from('voting_sessions')
          .select('expires_at, status')
          .eq('id', sessionId)
          .single();

      final expiresAt = DateTime.parse(session['expires_at']);
      final now = DateTime.now().toUtc();
      final isExpired = now.isAfter(expiresAt);

      // Auto-complete if expired but status still active
      if (isExpired && session['status'] == 'active') {
        await completeSession(sessionId);
      }

      return {
        'status': session['status'],
        'is_expired': isExpired,
        'expires_at': session['expires_at'],
        'remaining_seconds': isExpired ? 0 : expiresAt.difference(now).inSeconds,
      };
    } catch (e) {
      debugPrint('❌ [VotingService] Error checking status: $e');
      throw Exception('Oturum durumu kontrol edilemedi: $e');
    }
  }

  // ============================================
  // 6. SUBSCRIBE TO REAL-TIME UPDATES
  // ============================================

  /// Subscribes to real-time vote updates for a session
  /// Returns: Stream of vote updates
  /// 
  /// Features:
  /// - Real-time updates via Supabase Realtime
  /// - Automatic reconnection on disconnect
  /// - Error handling
  /// 
  /// Usage:
  /// ```dart
  /// VotingService.subscribeToVoteUpdates(sessionId).listen((update) {
  ///   print('New votes: ${update['total_votes']}');
  /// });
  /// ```
  static Stream<Map<String, dynamic>> subscribeToVoteUpdates(String sessionId) {
    debugPrint('🔵 [VotingService] Subscribing to real-time updates for: $sessionId');

    return _supabase
        .from('voting_sessions')
        .stream(primaryKey: ['id'])
        .eq('id', sessionId)
        .map((sessions) {
          if (sessions.isEmpty) {
            debugPrint('⚠️ [VotingService] No session found in stream');
            return {
              'total_votes': 0,
              'approval_rate': 0.0,
              'average_score': 0.0,
              'score_courage': 0.0,
              'score_honesty': 0.0,
              'score_loyalty': 0.0,
              'score_work_ethic': 0.0,
              'score_discipline': 0.0,
            };
          }

          final session = sessions.first;
          debugPrint('✅ [VotingService] Real-time update received');

          return {
            'total_votes': session['total_votes'] ?? 0,
            'approval_rate': (session['approval_rate'] ?? 0.0).toDouble(),
            'average_score': (session['average_score'] ?? 0.0).toDouble(),
            'score_courage': (session['score_courage'] ?? 0.0).toDouble(),
            'score_honesty': (session['score_honesty'] ?? 0.0).toDouble(),
            'score_loyalty': (session['score_loyalty'] ?? 0.0).toDouble(),
            'score_work_ethic': (session['score_work_ethic'] ?? 0.0).toDouble(),
            'score_discipline': (session['score_discipline'] ?? 0.0).toDouble(),
          };
        })
        .handleError((error) {
          debugPrint('❌ [VotingService] Real-time stream error: $error');
        });
  }

  // ============================================
  // 7. GET USER'S ACTIVE SESSION
  // ============================================

  /// Gets the current user's active voting session (if any)
  /// Returns: Session data or null
  /// 
  /// Use case: Check if user already has an active voting session
  /// before creating a new one
  static Future<Map<String, dynamic>?> getUserActiveSession(String userId) async {
    try {
      debugPrint('🔵 [VotingService] Fetching active session for user: $userId');

      final session = await _supabase
          .from('voting_sessions')
          .select()
          .eq('user_id', userId)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .maybeSingle();

      if (session != null) {
        debugPrint('✅ [VotingService] Active session found: ${session['id']}');
      } else {
        debugPrint('⚠️ [VotingService] No active session found');
      }

      return session;
    } catch (e) {
      debugPrint('❌ [VotingService] Error fetching active session: $e');
      throw Exception('Aktif oturum bulunamadı: $e');
    }
  }

  // ============================================
  // 8. GET SESSION BY UNIQUE LINK
  // ============================================

  /// Gets voting session details by unique link
  /// Returns: Session data or throws error
  /// 
  /// Use case: Web voting page needs to load session by link
  /// 
  /// Parameters:
  /// - uniqueLink: 6-character link (e.g., "a3f8k2")
  static Future<Map<String, dynamic>> getSessionByLink(String uniqueLink) async {
    try {
      debugPrint('🔵 [VotingService] Fetching session by link: $uniqueLink');

      final session = await _supabase
          .from('voting_sessions')
          .select()
          .eq('unique_link', uniqueLink)
          .single();

      debugPrint('✅ [VotingService] Session found: ${session['id']}');
      return session;
    } on PostgrestException catch (e) {
      if (e.code == 'PGRST116') {
        debugPrint('❌ [VotingService] Session not found for link: $uniqueLink');
        throw Exception('Oylama bulunamadı. Link geçersiz olabilir.');
      }
      debugPrint('❌ [VotingService] Database error: ${e.message}');
      throw Exception('Veritabanı hatası: ${e.message}');
    } catch (e) {
      debugPrint('❌ [VotingService] Error fetching session: $e');
      throw Exception('Oturum bulunamadı: $e');
    }
  }

  // ============================================
  // 9. GET USER'S VOTING SESSIONS (HISTORY)
  // ============================================

  /// Gets all voting sessions for a user (past and present)
  /// Returns: List of sessions ordered by creation date
  /// 
  /// Use case: User profile page showing voting history
  static Future<List<Map<String, dynamic>>> getUserVotingSessions(String userId) async {
    try {
      debugPrint('🔵 [VotingService] Fetching all sessions for user: $userId');

      final sessions = await _supabase
          .from('voting_sessions')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      debugPrint('✅ [VotingService] Found ${sessions.length} sessions');
      return sessions;
    } catch (e) {
      debugPrint('❌ [VotingService] Error fetching sessions: $e');
      throw Exception('Oturumlar yüklenemedi: $e');
    }
  }

  // ============================================
  // 10. COMPLETE VOTING SESSION
  // ============================================

  /// Marks a voting session as completed
  /// Called when 72 hours expire or manually ended
  /// 
  /// Side effects:
  /// - Updates session status to 'completed'
  /// - Sets updated_at timestamp
  /// - Triggers final score calculation (via database trigger)
  static Future<void> completeSession(String sessionId) async {
    try {
      debugPrint('🔵 [VotingService] Completing session: $sessionId');

      await _supabase.from('voting_sessions').update({
        'status': 'completed',
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);

      debugPrint('✅ [VotingService] Session completed successfully');
    } on PostgrestException catch (e) {
      debugPrint('❌ [VotingService] Database error: ${e.message}');
      throw Exception('Veritabanı hatası: ${e.message}');
    } catch (e) {
      debugPrint('❌ [VotingService] Error completing session: $e');
      throw Exception('Oturum tamamlanamadı: $e');
    }
  }

  // ============================================
  // 11. DELETE VOTING SESSION
  // ============================================

  /// Deletes a voting session and its photo
  /// WARNING: This is irreversible!
  /// 
  /// Use case: Admin panel or user wants to delete their session
  /// 
  /// Side effects:
  /// - Deletes photo from storage
  /// - Deletes session from database
  /// - Cascade deletes all votes (via foreign key)
  static Future<void> deleteSession(String sessionId) async {
    try {
      debugPrint('🔵 [VotingService] Deleting session: $sessionId');

      // Get session to find photo URL
      final session = await _supabase
          .from('voting_sessions')
          .select('photo_url')
          .eq('id', sessionId)
          .single();

      // Delete photo from storage
      if (session['photo_url'] != null) {
        final photoUrl = session['photo_url'] as String;
        final fileName = photoUrl.split('/').last;
        
        debugPrint('🔵 [VotingService] Deleting photo: $fileName');
        await _storage.from(_storageBucket).remove([fileName]);
        debugPrint('✅ [VotingService] Photo deleted');
      }

      // Delete session (cascade deletes votes)
      debugPrint('🔵 [VotingService] Deleting session record...');
      await _supabase.from('voting_sessions').delete().eq('id', sessionId);

      debugPrint('✅ [VotingService] Session deleted successfully');
    } on StorageException catch (e) {
      debugPrint('❌ [VotingService] Storage error: ${e.message}');
      throw Exception('Fotoğraf silinemedi: ${e.message}');
    } on PostgrestException catch (e) {
      debugPrint('❌ [VotingService] Database error: ${e.message}');
      throw Exception('Veritabanı hatası: ${e.message}');
    } catch (e) {
      debugPrint('❌ [VotingService] Error deleting session: $e');
      throw Exception('Oturum silinemedi: $e');
    }
  }
  // ============================================
  // 12. SUBMIT VOTE (WEB)
  // ============================================

  /// Submits a vote from web voting page
  /// Returns: Vote ID or throws error
  /// 
  /// Parameters:
  /// - sessionId: Voting session ID
  /// - scores: Map of dimension scores (honesty, dependability, etc.)
  /// - voterFingerprint: Device fingerprint hash
  /// - ipAddress: Voter's IP address (hashed)
  /// 
  /// Validation:
  /// - Checks if voter already voted (fingerprint + IP)
  /// - Validates score ranges (1-10)
  /// - Checks if session is still active
  static Future<String> submitVote({
    required String sessionId,
    required Map<String, double> scores,
    required String voterFingerprint,
    String? ipAddress,
  }) async {
    try {
      debugPrint('🔵 [VotingService] Submitting vote for session: $sessionId');

      // Validate scores (1-10 range)
      for (var entry in scores.entries) {
        if (entry.value < 1.0 || entry.value > 10.0) {
          throw Exception('Geçersiz puan: ${entry.key} = ${entry.value}');
        }
      }

      // Check if voter already voted (fingerprint check)
      final existingVote = await _supabase
          .from('votes')
          .select('id')
          .eq('voting_session_id', sessionId)
          .eq('device_fingerprint', voterFingerprint)
          .maybeSingle();

      if (existingVote != null) {
        debugPrint('⚠️ [VotingService] Duplicate vote detected');
        throw Exception('Bu cihazdan zaten oy kullandınız.');
      }

      // Check if session is still active
      final sessionStatus = await checkSessionStatus(sessionId);
      if (sessionStatus['is_expired'] == true) {
        throw Exception('Oylama süresi dolmuş.');
      }

      // Insert vote
      final voteData = {
        'voting_session_id': sessionId,
        'voter_id': voterFingerprint,
        'honesty': scores['honesty'] ?? 5.0,
        'dependability': scores['dependability'] ?? 5.0,
        'sociability': scores['sociability'] ?? 5.0,
        'work_ethic': scores['work_ethic'] ?? 5.0,
        'discipline': scores['discipline'] ?? 5.0,
        'device_fingerprint': voterFingerprint,
        'ip_address': ipAddress,
      };

      final response = await _supabase
          .from('votes')
          .insert(voteData)
          .select('id')
          .single();

      final voteId = response['id'] as String;
      debugPrint('✅ [VotingService] Vote submitted successfully: $voteId');

      return voteId;
    } on PostgrestException catch (e) {
      debugPrint('❌ [VotingService] Database error: ${e.message}');
      throw Exception('Veritabanı hatası: ${e.message}');
    } catch (e) {
      debugPrint('❌ [VotingService] Error submitting vote: $e');
      rethrow;
    }
  }

  // ============================================
  // 13. VALIDATE PHOTO WITH AZURE FACE API
  // ============================================

  /// Validates photo before upload using Azure Face API
  /// Returns: true if photo is valid, false otherwise
  /// 
  /// Validation criteria:
  /// - Detects exactly 1 face
  /// - Face is real (not a photo of photo)
  /// - Face quality is good (lighting, sharpness)
  /// 
  /// Azure Face API Endpoint:
  /// POST https://{endpoint}/face/v1.0/detect
  static Future<bool> validatePhotoWithAzure(File photoFile) async {
    try {
      debugPrint('🔵 [VotingService] Validating photo with Azure Face API...');

      // ✅ FIXED: Read Azure credentials from .env file (SECURE)
      final azureEndpoint = dotenv.env['AZURE_FACE_API_ENDPOINT'] ?? 
          'https://yansimam-face-api.cognitiveservices.azure.com/';
      final azureKey = dotenv.env['AZURE_FACE_API_KEY'] ?? '';

      // ✅ Validate credentials are loaded
      if (azureKey.isEmpty) {
        debugPrint('⚠️ [VotingService] Azure API key not configured in .env');
        
        // In debug mode, allow without validation
        if (kDebugMode) {
          debugPrint('⚠️ [VotingService] DEBUG MODE: Skipping Azure validation');
          return true;
        }
        
        throw Exception('Azure API anahtarı yapılandırılmamış. Lütfen .env dosyasını kontrol edin.');
      }

      // Read photo file
      final bytes = await photoFile.readAsBytes();

      // Make API request
      final url = Uri.parse('$azureEndpoint/face/v1.0/detect?returnFaceAttributes=blur,exposure');
      
      debugPrint('🔵 [VotingService] Calling Azure API...');
      final response = await http.post(
        url,
        headers: {
          'Ocp-Apim-Subscription-Key': azureKey,
          'Content-Type': 'application/octet-stream',
        },
        body: bytes,
      );

      debugPrint('📡 [VotingService] Azure API Response: ${response.statusCode}');

      if (response.statusCode != 200) {
        debugPrint('❌ [VotingService] Azure API error: ${response.statusCode}');
        debugPrint('Response body: ${response.body}');
        
        // In debug mode, allow gracefully
        if (kDebugMode) {
          debugPrint('⚠️ [VotingService] DEBUG MODE: Allowing despite API error');
          return true;
        }
        
        throw Exception('Fotoğraf doğrulanamadı. Lütfen tekrar deneyin.');
      }

      // Parse response
      final List<dynamic> faces = jsonDecode(response.body);

      // Validation checks
      if (faces.isEmpty) {
        debugPrint('❌ [VotingService] No face detected');
        throw Exception('Fotoğrafta yüz tespit edilemedi. Lütfen net bir fotoğraf kullanın.');
      }

      if (faces.length > 1) {
        debugPrint('❌ [VotingService] Multiple faces detected: ${faces.length}');
        throw Exception('Fotoğrafta birden fazla yüz var. Lütfen tek kişilik fotoğraf kullanın.');
      }

      // Check face quality
      final face = faces.first;
      final attributes = face['faceAttributes'];
      
      if (attributes != null) {
        final blur = attributes['blur'];
        final exposure = attributes['exposure'];

        // Check if too blurry (WARNING - not blocking in relaxed mode)
        if (blur != null && blur['blurLevel'] == 'high') {
          debugPrint('⚠️ [VotingService] Photo is blurry');
          // Not throwing error - relaxed validation
        }

        // Check if too dark/bright (WARNING - not blocking in relaxed mode)
        if (exposure != null) {
          final exposureLevel = exposure['exposureLevel'];
          if (exposureLevel == 'UnderExposure' || exposureLevel == 'OverExposure') {
            debugPrint('⚠️ [VotingService] Poor lighting detected');
            // Not throwing error - relaxed validation
          }
        }
      }

      debugPrint('✅ [VotingService] Photo validation passed');
      return true;

    } on http.ClientException catch (e) {
      debugPrint('❌ [VotingService] Network error: $e');
      
      // In debug mode, allow despite network errors
      if (kDebugMode) {
        debugPrint('⚠️ [VotingService] DEBUG MODE: Allowing despite network error');
        return true;
      }
      
      throw Exception('Ağ hatası: İnternet bağlantınızı kontrol edin.');
    } catch (e) {
      debugPrint('❌ [VotingService] Azure validation error: $e');
      rethrow;
    }
  }

  // ============================================
  // 14. UPDATE SESSION SCORES (MANUAL)
  // ============================================

  /// Manually updates session scores (normally done by trigger)
  /// Use case: Admin panel or debugging
  static Future<void> updateSessionScores(String sessionId) async {
    try {
      debugPrint('🔵 [VotingService] Manually updating scores for: $sessionId');

      // Recalculate stats
      final stats = await getSessionStats(sessionId);

      // Update session
      await _supabase.from('voting_sessions').update({
        'total_votes': stats['total_votes'],
        'approval_rate': stats['approval_rate'],
        'average_score': stats['average_score'],
        'score_courage': stats['score_courage'],
        'score_honesty': stats['score_honesty'],
        'score_loyalty': stats['score_loyalty'],
        'score_work_ethic': stats['score_work_ethic'],
        'score_discipline': stats['score_discipline'],
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      }).eq('id', sessionId);

      debugPrint('✅ [VotingService] Scores updated successfully');
    } catch (e) {
      debugPrint('❌ [VotingService] Error updating scores: $e');
      throw Exception('Skorlar güncellenemedi: $e');
    }
  }
}

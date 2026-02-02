// ============================================
// File: lib/screens/home/home_screen.dart
// PART 1/2 - State Management & Data Loading
// FIXED: onPopInvoked deprecated warning resolved
// FIXED: Logo, no auto-notification, centered UI
// ============================================

import 'package:flutter/material.dart';
import '../../core/config/supabase_config.dart';
import '../voting/voting_start_screen.dart';
import '../leaderboard/leaderboard_screen.dart';
import '../profile/profile_screen.dart';

/// Home Screen
/// 
/// Features:
/// - Welcome card with user info
/// - Active voting session card (if exists)
/// - Status card (approved/pending/rejected/unapproved)
/// - Stats grid (approval rate, votes, score, rank)
/// - Quick actions
/// - Recent activity
/// 
/// FIXED: onPopInvoked deprecated, no auto-notification, centered UI
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  bool _isLoading = true;

  // ============================================
  // USER DATA
  // ============================================
  
  String? _userId;
  String? _fullName;
  String? _username;
  String? _profilePhotoUrl;
  String _userStatus = 'unapproved';
  bool _isPremium = false;
  String? _deservepageId;
  DateTime? _nextVotingDate;

  // ============================================
  // STATS
  // ============================================
  
  double _approvalRate = 0.0;
  int _totalVotes = 0;
  double _averageScore = 0.0;
  int _rank = 0;

  // ============================================
  // ACTIVE VOTING SESSION
  // ============================================
  
  String? _activeSessionId;
  DateTime? _activeSessionExpiry;
  int _activeSessionVotes = 0;

  // ============================================
  // RECENT SESSIONS
  // ============================================
  
  List<Map<String, dynamic>> _recentSessions = [];

  // ============================================
  // LIFECYCLE
  // ============================================

  @override
  void initState() {
    super.initState();
    _loadUserData();
    // ✅ REMOVED: Auto notification check
  }

  // ============================================
  // DATA LOADING
  // ============================================

  Future<void> _loadUserData() async {
    setState(() => _isLoading = true);

    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) {
        _redirectToLogin();
        return;
      }

      setState(() {
        _userId = user.id;
        _fullName = user.userMetadata?['full_name'];
        _username = user.userMetadata?['username'];
      });

      // Load user data from database
      final userData = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (userData != null) {
        setState(() {
          _profilePhotoUrl = userData['profile_photo_url'];
          _userStatus = userData['status'] ?? 'unapproved';
          _isPremium = userData['is_premium'] ?? false;
          _deservepageId = userData['deservepage_id']?.toString();
          _totalVotes = userData['total_votes'] ?? 0;
          _averageScore = (userData['average_score'] ?? 0.0).toDouble();
          
          if (userData['next_voting_date'] != null) {
            _nextVotingDate = DateTime.parse(userData['next_voting_date']);
          }
        });
      }

      // Load user stats
      await _loadUserStats();
      
      // Load active voting session - ✅ SILENTLY, NO NOTIFICATION
      await _loadActiveSession();
      
      // Load recent sessions
      await _loadRecentSessions();
    } catch (e) {
      debugPrint('❌ Error loading user data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadUserStats() async {
    if (_userId == null) return;

    try {
      // Calculate approval rate from latest completed session
      final latestSession = await SupabaseConfig.client
          .from('voting_sessions')
          .select('approval_rate, total_votes, average_score')
          .eq('user_id', _userId!)
          .eq('status', 'completed')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (latestSession != null && mounted) {
        setState(() {
          _approvalRate = (latestSession['approval_rate'] ?? 0.0) / 100.0;
        });
      }

      // Get leaderboard rank if premium
      if (_isPremium && _userStatus == 'approved') {
        final leaderboardData = await SupabaseConfig.client
            .from('leaderboard')
            .select('rank')
            .eq('user_id', _userId!)
            .maybeSingle();

        if (leaderboardData != null && mounted) {
          setState(() {
            _rank = leaderboardData['rank'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading stats: $e');
    }
  }

  Future<void> _loadActiveSession() async {
    if (_userId == null) return;

    try {
      final activeSession = await SupabaseConfig.client
          .from('voting_sessions')
          .select('id, unique_link, expires_at, total_votes, status')
          .eq('user_id', _userId!)
          .eq('status', 'active')
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      if (activeSession != null) {
        final expiresAt = DateTime.parse(activeSession['expires_at']);
        
        // Check if expired
        if (expiresAt.isBefore(DateTime.now())) {
          if (mounted) {
            setState(() {
              _activeSessionId = null;
              _activeSessionExpiry = null;
              _activeSessionVotes = 0;
            });
          }
        } else {
          if (mounted) {
            setState(() {
              _activeSessionId = activeSession['unique_link'];
              _activeSessionExpiry = expiresAt;
              _activeSessionVotes = activeSession['total_votes'] ?? 0;
            });
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Error loading active session: $e');
    }
  }

  Future<void> _loadRecentSessions() async {
    if (_userId == null) return;

    try {
      final sessions = await SupabaseConfig.client
          .from('voting_sessions')
          .select('id, unique_link, status, total_votes, approval_rate, average_score, created_at')
          .eq('user_id', _userId!)
          .order('created_at', ascending: false)
          .limit(5);

      if (mounted) {
        setState(() {
          _recentSessions = List<Map<String, dynamic>>.from(sessions);
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading recent sessions: $e');
    }
  }

  // ============================================
  // HELPERS
  // ============================================

  void _redirectToLogin() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      '/login',
      (route) => false,
    );
  }

  String _getTimeRemaining(DateTime expiryDate) {
    final now = DateTime.now();
    final difference = expiryDate.difference(now);

    if (difference.isNegative) {
      return 'Süresi doldu';
    }

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    if (hours > 24) {
      final days = (hours / 24).floor();
      return '$days gün ${hours % 24} saat';
    } else if (hours > 0) {
      return '$hours saat $minutes dakika';
    } else {
      return '$minutes dakika';
    }
  }

  // ============================================
  // BUILD METHOD
  // ============================================

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: Back button handler with onPopInvokedWithResult
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          // Don't allow back navigation from home screen
          return;
        }
      },
      child: Scaffold(
        appBar: AppBar(
          // ✅ FIXED: Logo in AppBar
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo_white.png',
                  width: 32,
                  height: 32,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.verified_user, size: 28);
                  },
                ),
              ),
              const SizedBox(width: 12),
              const Text('YANSIMAM'),
            ],
          ),
          backgroundColor: const Color(0xFF004563),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          automaticallyImplyLeading: false, // ✅ No back button
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Bildirimler yakında eklenecek!')),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () {
                Navigator.of(context).pushNamed('/settings');
              },
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() => _currentIndex = index);
          },
          type: BottomNavigationBarType.fixed,
          selectedItemColor: const Color(0xFF009DE0),
          unselectedItemColor: Colors.grey,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Ana Sayfa',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.how_to_vote),
              label: 'Oylama',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.leaderboard),
              label: 'Lider Tablosu',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // BODY BUILDER
  // ============================================

  Widget _buildBody() {
    switch (_currentIndex) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const VotingStartScreen();
      case 2:
        return const LeaderboardScreen();
      case 3:
        return const ProfileScreen();
      default:
        return _buildHomeTab();
    }
  }

  // ============================================
  // HOME TAB
  // ============================================

  Widget _buildHomeTab() {
    return RefreshIndicator(
      onRefresh: _loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 20),
            // ✅ Active session card shown ONLY if exists, NO notification
            if (_activeSessionId != null) ...[
              _buildActiveSessionCard(),
              const SizedBox(height: 20),
            ],
            _buildStatusCard(),
            const SizedBox(height: 20),
            _buildStatsGrid(),
            const SizedBox(height: 20),
            _buildQuickActions(),
            const SizedBox(height: 20),
            _buildRecentActivity(),
          ],
        ),
      ),
    );
  }

  // ============================================
  // PART 2 CONTINUES WITH UI BUILDERS...
  // ============================================
  // ============================================
  // PART 2/2 - UI BUILDERS
  // ============================================

  // ============================================
  // UI COMPONENTS - WELCOME CARD
  // ============================================

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF004563), Color(0xFF009DE0)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF009DE0).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 3),
              image: _profilePhotoUrl != null
                  ? DecorationImage(
                      image: NetworkImage(_profilePhotoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
              color: _profilePhotoUrl == null ? Colors.white24 : null,
            ),
            child: _profilePhotoUrl == null
                ? const Icon(Icons.person, size: 40, color: Colors.white)
                : null,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Merhaba, ${_fullName ?? _username ?? 'Kullanıcı'}!',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '@${_username ?? 'username'}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
                if (_deservepageId != null) ...[
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'ID: $_deservepageId',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - ACTIVE SESSION CARD
  // ============================================

  Widget _buildActiveSessionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4CAF50), Color(0xFF66BB6A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4CAF50).withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // ✅ FIXED: Centered row with proper alignment
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.timer, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Aktif Oylama',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$_activeSessionVotes oy',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF4CAF50),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // ✅ FIXED: Centered time remaining box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.access_time, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Kalan Süre: ${_getTimeRemaining(_activeSessionExpiry!)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // ✅ FIXED: Centered button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pushNamed(
                  '/voting_progress',
                  arguments: {
                    'sessionId': _activeSessionId,
                    'votingLink': _activeSessionId,
                  },
                );
              },
              icon: const Icon(Icons.visibility),
              label: const Text('Detayları Gör'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF4CAF50),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - STATUS CARD
  // ============================================

  Widget _buildStatusCard() {
    Color statusColor;
    String statusText;
    IconData statusIcon;
    String statusDescription;

    switch (_userStatus) {
      case 'approved':
        statusColor = const Color(0xFF4CAF50);
        statusText = 'Onaylandı ✓';
        statusIcon = Icons.check_circle;
        statusDescription = _isPremium
            ? 'Premium üyesiniz! Leaderboard\'a erişebilirsiniz.'
            : 'Profiliniz aktif. Premium için yükselt!';
        break;
      case 'pending':
        statusColor = const Color(0xFF009DE0);
        statusText = 'Oylama Devam Ediyor';
        statusIcon = Icons.hourglass_empty;
        statusDescription = 'Oylamalar toplanıyor. Sonuç bekleniyor...';
        break;
      case 'rejected':
        statusColor = const Color(0xFFFF6B6B);
        statusText = 'Başarısız';
        statusIcon = Icons.cancel;
        if (_nextVotingDate != null) {
          final daysLeft = _nextVotingDate!.difference(DateTime.now()).inDays;
          statusDescription = 'Tekrar deneme: $daysLeft gün sonra';
        } else {
          statusDescription = '30 gün sonra tekrar deneyebilirsiniz';
        }
        break;
      default:
        statusColor = const Color(0xFFFFA726);
        statusText = 'Henüz Oylama Yok';
        statusIcon = Icons.info_outline;
        statusDescription = 'Onay süreci başlatmak için oylama yapın.';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor, width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 32),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusText,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  statusDescription,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - STATS GRID
  // ============================================

  Widget _buildStatsGrid() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'İstatistiklerim',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF004563),
          ),
        ),
        const SizedBox(height: 12),
        // ✅ FIXED: Centered grid with mainAxisAlignment
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // ✅ CENTERED
          children: [
            Expanded(
              child: _buildStatCard(
                'Onay Oranı',
                '${(_approvalRate * 100).toStringAsFixed(1)}%',
                Icons.thumb_up,
                const Color(0xFF4CAF50),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Toplam Oy',
                _totalVotes.toString(),
                Icons.how_to_vote,
                const Color(0xFF009DE0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // ✅ CENTERED
          children: [
            Expanded(
              child: _buildStatCard(
                'Ortalama Puan',
                _averageScore.toStringAsFixed(1),
                Icons.star,
                const Color(0xFFFFA726),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                'Sıralama',
                _rank > 0 ? '#$_rank' : '-',
                Icons.leaderboard,
                const Color(0xFF9C27B0),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
      String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // ✅ CENTERED
        crossAxisAlignment: CrossAxisAlignment.center, // ✅ CENTERED
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - QUICK ACTIONS
  // ============================================

  Widget _buildQuickActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hızlı İşlemler',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF004563),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center, // ✅ CENTERED
          children: [
            Expanded(
              child: _buildActionButton(
                'Oylama Başlat',
                Icons.how_to_vote,
                const Color(0xFF009DE0),
                () {
                  setState(() => _currentIndex = 1);
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Profil',
                Icons.person,
                const Color(0xFF4CAF50),
                () {
                  setState(() => _currentIndex = 3);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // ✅ CENTERED
          crossAxisAlignment: CrossAxisAlignment.center, // ✅ CENTERED
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - RECENT ACTIVITY
  // ============================================

  Widget _buildRecentActivity() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Son Aktiviteler',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF004563),
          ),
        ),
        const SizedBox(height: 12),
        if (_recentSessions.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                'Henüz aktivite yok',
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...List.generate(_recentSessions.length, (index) {
            final session = _recentSessions[index];
            return _buildActivityItem(session);
          }),
      ],
    );
  }

  Widget _buildActivityItem(Map<String, dynamic> session) {
    final status = session['status'];
    Color statusColor;
    IconData statusIcon;
    String statusLabel;

    switch (status) {
      case 'active':
        statusColor = const Color(0xFF009DE0);
        statusIcon = Icons.timelapse;
        statusLabel = 'Devam Ediyor';
        break;
      case 'completed':
        statusColor = const Color(0xFF4CAF50);
        statusIcon = Icons.check_circle;
        statusLabel = 'Tamamlandı';
        break;
      case 'expired':
        statusColor = const Color(0xFFFF6B6B);
        statusIcon = Icons.close;
        statusLabel = 'Başarısız';
        break;
      default:
        statusColor = Colors.grey;
        statusIcon = Icons.help_outline;
        statusLabel = 'Bilinmiyor';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  statusLabel,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${session['total_votes'] ?? 0} oy • ID: ${session['unique_link']}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (session['approval_rate'] != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${session['approval_rate'].toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

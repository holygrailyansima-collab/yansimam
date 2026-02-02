// ============================================
// File: lib/screens/leaderboard/leaderboard_screen.dart
// PART 1/2 - State Management & Data Loading
// FIXED: Premium logic - Everyone can view, only premium users listed
// FIXED: No paywall, inner join fixed
// ============================================

import 'package:flutter/material.dart';
import '../../core/config/supabase_config.dart';
import '../../utils/constants.dart';

/// Leaderboard Screen
/// 
/// Features:
/// - Real-time leaderboard from Supabase
/// - Anyone can view (no paywall)
/// - Only premium users appear in list
/// - User search functionality
/// - Detailed user stats modal
/// 
/// FIXED: Premium logic corrected, production-ready
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool isLoading = true;
  bool currentUserIsPremium = false;
  bool currentUserQualifies = false;
  List<LeaderboardUser> users = [];
  List<LeaderboardUser> filteredUsers = [];
  final searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLeaderboard();
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  // ============================================
  // LOAD LEADERBOARD FROM SUPABASE
  // ============================================

  Future<void> _loadLeaderboard() async {
    setState(() => isLoading = true);

    try {
      final user = SupabaseConfig.currentUser;

      if (user == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // ✅ NEW: Check current user's premium status and qualification
      final userData = await SupabaseConfig.client
          .from('users')
          .select('is_premium, status, total_votes, average_score')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (userData == null) {
        throw Exception('Kullanıcı kaydı bulunamadı');
      }

      currentUserIsPremium = userData['is_premium'] ?? false;
      
      // Check if user qualifies for leaderboard (approved + 50+ votes + 7.5+ score)
      final status = userData['status'] as String?;
      final totalVotes = userData['total_votes'] as int? ?? 0;
      final avgScore = (userData['average_score'] as num?)?.toDouble() ?? 0.0;
      
      currentUserQualifies = status == 'approved' && 
                            totalVotes >= 50 && 
                            avgScore >= 7.5;

      debugPrint('👤 Current user qualification:');
      debugPrint('   Premium: $currentUserIsPremium');
      debugPrint('   Qualifies: $currentUserQualifies');
      debugPrint('   Status: $status, Votes: $totalVotes, Score: $avgScore');

      // ✅ FIXED: Fetch leaderboard - Only show PREMIUM users
      // Inner join removed to prevent null errors
      final leaderboardData = await SupabaseConfig.client
          .from('users')
          .select('''
            id,
            full_name,
            username,
            profile_photo_url,
            deservepage_id,
            total_votes,
            average_score,
            score_courage,
            score_honesty,
            score_loyalty,
            score_work_ethic,
            score_discipline
          ''')
          .eq('status', 'approved')
          .eq('is_premium', true)
          .gte('total_votes', 50)
          .gte('average_score', 7.5)
          .order('average_score', ascending: false)
          .order('total_votes', ascending: false)
          .limit(100);

      if (mounted) {
        users = leaderboardData.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          
          return LeaderboardUser(
            rank: index + 1, // Calculate rank based on order
            fullName: item['full_name'] as String? ?? 'Unknown',
            username: item['username'] as String? ?? 'unknown',
            profileImageUrl: item['profile_photo_url'] as String?,
            averageScore: (item['average_score'] as num?)?.toDouble() ?? 0.0,
            totalVotes: item['total_votes'] as int? ?? 0,
            deservepageId: item['deservepage_id'] as int? ?? 0,
            courageScore: (item['score_courage'] as num?)?.toDouble() ?? 0.0,
            honestyScore: (item['score_honesty'] as num?)?.toDouble() ?? 0.0,
            loyaltyScore: (item['score_loyalty'] as num?)?.toDouble() ?? 0.0,
            workEthicScore: (item['score_work_ethic'] as num?)?.toDouble() ?? 0.0,
            disciplineScore: (item['score_discipline'] as num?)?.toDouble() ?? 0.0,
          );
        }).toList();

        filteredUsers = users;
        setState(() => isLoading = false);
        
        debugPrint('✅ Leaderboard loaded: ${users.length} premium users');
      }
    } catch (e) {
      debugPrint('❌ Error loading leaderboard: $e');
      
      if (mounted) {
        setState(() => isLoading = false);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Leaderboard yüklenirken hata oluştu: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  // ============================================
  // SEARCH USERS
  // ============================================

  void _searchUsers(String query) {
    setState(() {
      if (query.isEmpty) {
        filteredUsers = users;
      } else {
        filteredUsers = users
            .where((user) =>
                user.fullName.toLowerCase().contains(query.toLowerCase()) ||
                user.username.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });
  }

  // ============================================
  // SHOW USER DETAIL MODAL
  // ============================================

  void _showUserDetailModal(LeaderboardUser user) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),

            // Profile photo
            Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(50),
                    border: Border.all(color: AppColors.primary, width: 3),
                    color: user.profileImageUrl == null
                        ? Colors.grey[300]
                        : null,
                    image: user.profileImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(user.profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: user.profileImageUrl == null
                      ? const Icon(Icons.person, size: 50, color: Colors.grey)
                      : null,
                ),
                if (user.rank <= 3)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: _getRankColor(user.rank),
                        borderRadius: BorderRadius.circular(15),
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: Text(
                        _getRankEmoji(user.rank),
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 16),

            // Name
            Text(
              user.fullName,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),

            // Username
            Text(
              '@${user.username}',
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.grey,
              ),
            ),

            const SizedBox(height: 16),

            // DeservePage ID
            if (user.deservepageId > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.verified_user,
                      color: AppColors.primary,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ID: ${user.deservepageId}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStatColumn(
                  Icons.star,
                  user.averageScore.toStringAsFixed(1),
                  'Ortalama',
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildStatColumn(
                  Icons.how_to_vote,
                  '${user.totalVotes}',
                  'Oy',
                ),
                Container(width: 1, height: 40, color: Colors.grey[300]),
                _buildStatColumn(
                  Icons.emoji_events,
                  '#${user.rank}',
                  'Sıra',
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Detailed scores
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Detaylı Puanlar',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.secondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildScoreRow('Cesaret', user.courageScore),
                  const SizedBox(height: 12),
                  _buildScoreRow('Dürüstlük', user.honestyScore),
                  const SizedBox(height: 12),
                  _buildScoreRow('Bağlılık', user.loyaltyScore),
                  const SizedBox(height: 12),
                  _buildScoreRow('Çalışkanlık', user.workEthicScore),
                  const SizedBox(height: 12),
                  _buildScoreRow('Disiplin', user.disciplineScore),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Close button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Kapat'),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: AppColors.primary, size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.grey,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreRow(String label, double score) {
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.secondary,
            ),
          ),
        ),
        Expanded(
          flex: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score > 0 ? (score / 10) : 0,
              minHeight: 8,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                score >= 8.0
                    ? const Color(0xFF25D366)
                    : score >= 6.0
                        ? const Color(0xFFFFA000)
                        : AppColors.error,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 35,
          child: Text(
            score > 0 ? score.toStringAsFixed(1) : '--',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }

  // ============================================
  // BUILD METHOD
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Lider Tablosu'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLeaderboard,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Column(
              children: [
                // ✅ NEW: Show premium banner if user qualifies but not premium
                if (currentUserQualifies && !currentUserIsPremium)
                  _buildPremiumBanner(),
                
                Expanded(child: _buildLeaderboard()),
              ],
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
  // UI COMPONENTS - PREMIUM BANNER
  // ============================================

  Widget _buildPremiumBanner() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF009DE0), Color(0xFF004563)],
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
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.diamond,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Listede Yer Alın!',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Premium ile leaderboard\'da görünün',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white70,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(context).pushNamed('/premium');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF009DE0),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Premium\'a Geç',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - LEADERBOARD LIST
  // ============================================

  Widget _buildLeaderboard() {
    return Column(
      children: [
        // Search bar
        Container(
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: TextField(
            controller: searchController,
            onChanged: _searchUsers,
            decoration: InputDecoration(
              hintText: 'İsim veya kullanıcı adı ile ara...',
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.grey),
                      onPressed: () {
                        searchController.clear();
                        _searchUsers('');
                      },
                    )
                  : null,
              filled: true,
              fillColor: AppColors.background,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),

        // Leaderboard list
        Expanded(
          child: filteredUsers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.search_off, size: 64, color: AppColors.grey),
                      const SizedBox(height: 16),
                      Text(
                        searchController.text.isNotEmpty
                            ? 'Kullanıcı bulunamadı'
                            : 'Henüz leaderboard\'da kullanıcı yok',
                        style: const TextStyle(
                          fontSize: 18,
                          color: AppColors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Premium üyeler bu listede görünür',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadLeaderboard,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredUsers.length,
                    itemBuilder: (context, index) {
                      final user = filteredUsers[index];
                      return _buildUserCard(user);
                    },
                  ),
                ),
        ),
      ],
    );
  }

  // ============================================
  // UI COMPONENTS - USER CARD
  // ============================================

  Widget _buildUserCard(LeaderboardUser user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: () => _showUserDetailModal(user),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rank badge
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getRankColor(user.rank).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: user.rank <= 3
                      ? Text(
                          _getRankEmoji(user.rank),
                          style: const TextStyle(fontSize: 20),
                        )
                      : Text(
                          '${user.rank}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _getRankColor(user.rank),
                          ),
                        ),
                ),
              ),

              const SizedBox(width: 12),

              // Profile photo
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: AppColors.primary, width: 2),
                  color: user.profileImageUrl == null ? Colors.grey[300] : null,
                  image: user.profileImageUrl != null
                      ? DecorationImage(
                          image: NetworkImage(user.profileImageUrl!),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: user.profileImageUrl == null
                    ? const Icon(Icons.person, size: 28, color: Colors.grey)
                    : null,
              ),

              const SizedBox(width: 12),

              // User info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.secondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '@${user.username}',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              // Score and votes
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Color(0xFFFFA000), size: 18),
                      const SizedBox(width: 4),
                      Text(
                        user.averageScore.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.secondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${user.totalVotes} oy',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.grey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // HELPER METHODS
  // ============================================

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return const Color(0xFFFFD700); // Gold
      case 2:
        return const Color(0xFFC0C0C0); // Silver
      case 3:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return AppColors.primary;
    }
  }

  String _getRankEmoji(int rank) {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }
}

// ============================================
// LEADERBOARD USER MODEL
// ============================================

class LeaderboardUser {
  final int rank;
  final String fullName;
  final String username;
  final String? profileImageUrl;
  final double averageScore;
  final int totalVotes;
  final int deservepageId;
  final double courageScore;
  final double honestyScore;
  final double loyaltyScore;
  final double workEthicScore;
  final double disciplineScore;

  LeaderboardUser({
    required this.rank,
    required this.fullName,
    required this.username,
    this.profileImageUrl,
    required this.averageScore,
    required this.totalVotes,
    required this.deservepageId,
    required this.courageScore,
    required this.honestyScore,
    required this.loyaltyScore,
    required this.workEthicScore,
    required this.disciplineScore,
  });
}

// ============================================
// File: lib/screens/leaderboard/leaderboard_screen.dart
// PART 1/2 - State management and data loading
// FIXED: Added constants.dart import for AppColors
// ============================================

import 'package:flutter/material.dart';
import '../../utils/constants.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  bool isLoading = true;
  bool isPremium = false;
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

  Future<void> _loadLeaderboard() async {
    setState(() => isLoading = true);

    try {
      // TEST MODE - Check premium status and load fake data
      await Future.delayed(const Duration(milliseconds: 800));

      // Simulate premium user (set to false to test paywall)
      isPremium = true;

      if (isPremium) {
        // Fake leaderboard data
        users = [
          LeaderboardUser(
            rank: 1,
            fullName: 'Ayşe Demir',
            username: 'aysedemir',
            profileImageUrl: null,
            averageScore: 9.2,
            totalVotes: 156,
            deservepageId: 48291034,
            courageScore: 9.1,
            honestyScore: 9.5,
            loyaltyScore: 9.0,
            workEthicScore: 9.3,
            disciplineScore: 9.1,
          ),
          LeaderboardUser(
            rank: 2,
            fullName: 'Mehmet Kaya',
            username: 'mehmetkaya',
            profileImageUrl: null,
            averageScore: 9.0,
            totalVotes: 142,
            deservepageId: 47382910,
            courageScore: 8.9,
            honestyScore: 9.2,
            loyaltyScore: 8.8,
            workEthicScore: 9.1,
            disciplineScore: 8.9,
          ),
          LeaderboardUser(
            rank: 3,
            fullName: 'Ahmet Yılmaz',
            username: 'ahmetyilmaz',
            profileImageUrl: null,
            averageScore: 8.9,
            totalVotes: 138,
            deservepageId: 46273819,
            courageScore: 8.7,
            honestyScore: 9.1,
            loyaltyScore: 8.6,
            workEthicScore: 9.0,
            disciplineScore: 8.8,
          ),
          LeaderboardUser(
            rank: 4,
            fullName: 'Zeynep Arslan',
            username: 'zeyneparslan',
            profileImageUrl: null,
            averageScore: 8.7,
            totalVotes: 129,
            deservepageId: 45182736,
            courageScore: 8.5,
            honestyScore: 8.9,
            loyaltyScore: 8.4,
            workEthicScore: 8.8,
            disciplineScore: 8.7,
          ),
          LeaderboardUser(
            rank: 5,
            fullName: 'Can Öztürk',
            username: 'canozturk',
            profileImageUrl: null,
            averageScore: 8.6,
            totalVotes: 121,
            deservepageId: 44091625,
            courageScore: 8.4,
            honestyScore: 8.8,
            loyaltyScore: 8.3,
            workEthicScore: 8.7,
            disciplineScore: 8.6,
          ),
        ];

        filteredUsers = users;
      }

      setState(() => isLoading = false);

      /* PRODUCTION CODE
      final supabase = Supabase.instance.client;
      final user = supabase.auth.currentUser;

      if (user == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      // Check premium status
      final userData = await supabase
          .from('users')
          .select('is_premium')
          .eq('id', user.id)
          .single();

      isPremium = userData['is_premium'] ?? false;

      if (!isPremium) {
        setState(() => isLoading = false);
        return;
      }

      // Fetch leaderboard
      final leaderboardData = await supabase
          .from('users')
          .select()
          .eq('status', 'verified')
          .gte('total_votes', 50)
          .gte('average_score', 7.5)
          .order('leaderboard_score', ascending: false)
          .limit(50);

      users = leaderboardData.map((item) {
        return LeaderboardUser(
          rank: 0, // Will be set after sorting
          fullName: item['full_name'],
          username: item['username'],
          profileImageUrl: item['profile_image_url'],
          averageScore: item['average_score'],
          totalVotes: item['total_votes'],
          deservepageId: item['deservepage_id'],
          courageScore: item['courage_score'],
          honestyScore: item['honesty_score'],
          loyaltyScore: item['loyalty_score'],
          workEthicScore: item['work_ethic_score'],
          disciplineScore: item['discipline_score'],
        );
      }).toList();

      // Set ranks
      for (int i = 0; i < users.length; i++) {
        users[i].rank = i + 1;
      }

      filteredUsers = users;
      setState(() => isLoading = false);
      */
    } catch (e) {
      debugPrint('Error loading leaderboard: $e');
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

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
                  _buildScoreRow('Çalışma', user.workEthicScore),
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
              value: score / 10,
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
            score.toStringAsFixed(1),
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
  // PART 2/2 - UI Build Methods
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Leaderboard'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : !isPremium
              ? _buildPaywall()
              : _buildLeaderboard(),
    );
  }

  // ============================================
  // UI COMPONENTS - PAYWALL
  // ============================================

  Widget _buildPaywall() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.diamond,
                size: 80,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Premium Özellik',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: AppColors.secondary,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Leaderboard\'u görüntülemek için Premium üyeliğe geçmelisiniz.',
              style: TextStyle(
                fontSize: 16,
                color: AppColors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
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
              child: Column(
                children: [
                  _buildPremiumFeature(Icons.emoji_events, 'Leaderboard Erişimi'),
                  const SizedBox(height: 12),
                  _buildPremiumFeature(Icons.star, 'Profil Öne Çıkarma'),
                  const SizedBox(height: 12),
                  _buildPremiumFeature(Icons.all_inclusive, 'Kalıcı Aktif'),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Tek Seferlik Ödeme',
              style: TextStyle(
                fontSize: 14,
                color: AppColors.grey,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              '₺149.99',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Premium satın alma özelliği yakında eklenecek!'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Premium Satın Al',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('Daha Sonra'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPremiumFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Text(
          text,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.secondary,
          ),
        ),
      ],
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
                        'Kullanıcı bulunamadı',
                        style: TextStyle(
                          fontSize: 18,
                          color: AppColors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredUsers.length,
                  itemBuilder: (context, index) {
                    final user = filteredUsers[index];
                    return _buildUserCard(user);
                  },
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
  int rank;
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

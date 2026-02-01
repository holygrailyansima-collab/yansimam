// ============================================
// File: lib/widgets/leaderboard/profile_modal.dart
// PART 1/2 - Leaderboard Profile Detail Modal
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../utils/constants.dart';

/// Profile Modal Widget
/// 
/// Shows detailed user profile when tapped from leaderboard
/// 
/// Features:
/// - User profile photo
/// - Full name and username
/// - DeservePage ID
/// - Overall score with badge
/// - 5 dimension detailed scores (bar charts)
/// - Total votes count
/// - Premium badge (if premium)
/// - Rank badge (medals for top 3)
/// - Close button
/// 
/// Usage:
/// ```dart
/// showProfileModal(context, leaderboardUser);
/// ```
class ProfileModal extends StatefulWidget {
  final Map<String, dynamic> userData;

  const ProfileModal({
    super.key,
    required this.userData,
  });

  /// Show modal as bottom sheet
  static Future<void> show(
    BuildContext context,
    Map<String, dynamic> userData,
  ) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProfileModal(userData: userData),
    );
  }

  @override
  State<ProfileModal> createState() => _ProfileModalState();
}

class _ProfileModalState extends State<ProfileModal> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ============================================
  // ANIMATION SETUP
  // ============================================

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    );

    _animationController.forward();
  }

  // ============================================
  // COPY DESERVEPAGE ID
  // ============================================

  void _copyDeservepageId() {
    final deservepageId = widget.userData['deservepage_id']?.toString() ?? '';
    Clipboard.setData(ClipboardData(text: deservepageId));
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('DeservePage ID kopyalandı!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  // ============================================
  // GET SCORE COLOR
  // ============================================

  Color _getScoreColor(double score) {
    if (score >= 9.0) return const Color(0xFFFFD700); // Gold
    if (score >= 8.5) return const Color(0xFFC0C0C0); // Silver
    if (score >= 8.0) return const Color(0xFFCD7F32); // Bronze
    if (score >= 7.5) return AppColors.success; // Green
    return AppColors.grey;
  }

  // ============================================
  // GET RANK BADGE
  // ============================================

  Widget _getRankBadge(int rank) {
    if (rank == 1) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFFD700).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🥇', style: TextStyle(fontSize: 16)),
            SizedBox(width: 4),
            Text(
              '#1',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else if (rank == 2) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFC0C0C0), Color(0xFF999999)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFC0C0C0).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🥈', style: TextStyle(fontSize: 16)),
            SizedBox(width: 4),
            Text(
              '#2',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else if (rank == 3) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFCD7F32), Color(0xFF8B4513)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFCD7F32).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🥉', style: TextStyle(fontSize: 16)),
            SizedBox(width: 4),
            Text(
              '#3',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.grey.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          '#$rank',
          style: const TextStyle(
            color: AppColors.secondary,
            fontWeight: FontWeight.bold,
            fontSize: 14,
          ),
        ),
      );
    }
  }

  String _getScoreBadgeText(double score) {
    if (score >= 9.5) return '🏆 Mükemmel';
    if (score >= 9.0) return '⭐ Harika';
    if (score >= 8.5) return '🌟 Çok İyi';
    if (score >= 8.0) return '✨ İyi';
    if (score >= 7.5) return '👍 Güzel';
    return '📊 Ortalama';
  }

  // ============================================
  // BUILD METHOD
  // ============================================

  @override
  Widget build(BuildContext context) {
    final rank = widget.userData['rank'] as int? ?? 0;
    final averageScore = (widget.userData['average_score'] as num?)?.toDouble() ?? 0.0;

    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.black54,
        child: GestureDetector(
          onTap: () {}, // Prevent closing when tapping modal content
          child: DraggableScrollableSheet(
            initialChildSize: 0.85,
            minChildSize: 0.5,
            maxChildSize: 0.95,
            builder: (context, scrollController) {
              return ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildDragHandle(),
                      Expanded(
                        child: SingleChildScrollView(
                          controller: scrollController,
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              _buildProfileHeader(rank, averageScore),
                              const SizedBox(height: 24),
                              _buildDeservepageIdCard(),
                              const SizedBox(height: 24),
                              _buildStatsRow(rank),
                              const SizedBox(height: 24),
                              _buildScoreCard(averageScore),
                              const SizedBox(height: 24),
                              _buildDetailedScores(),
                              const SizedBox(height: 40),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - DRAG HANDLE
  // ============================================

  Widget _buildDragHandle() {
    return Container(
      margin: const EdgeInsets.only(top: 12, bottom: 8),
      width: 40,
      height: 4,
      decoration: BoxDecoration(
        color: AppColors.grey.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - PROFILE HEADER
  // ============================================

  Widget _buildProfileHeader(int rank, double averageScore) {
    final fullName = widget.userData['full_name'] as String? ?? 'Kullanıcı';
    final username = widget.userData['username'] as String? ?? 'user';
    final profileImageUrl = widget.userData['profile_image_url'] as String?;
    final isPremium = widget.userData['is_premium'] as bool? ?? false;

    return Column(
      children: [
        // Close button
        Align(
          alignment: Alignment.topRight,
          child: IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.close),
            color: AppColors.grey,
          ),
        ),
        const SizedBox(height: 8),
        
        // Profile photo with rank badge
        Stack(
          children: [
            // Profile photo
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _getScoreColor(averageScore),
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: _getScoreColor(averageScore).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipOval(
                child: profileImageUrl != null
                    ? Image.network(
                        profileImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderAvatar();
                        },
                      )
                    : _buildPlaceholderAvatar(),
              ),
            ),
            
            // Rank badge (top right)
            Positioned(
              top: 0,
              right: 0,
              child: _getRankBadge(rank),
            ),
          ],
        ),
        const SizedBox(height: 16),
        
        // Full name
        Text(
          fullName,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: AppColors.secondary,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        
        // Username with premium badge
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '@$username',
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.grey,
              ),
            ),
            if (isPremium) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primary, AppColors.secondary],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.diamond, color: Colors.white, size: 12),
                    SizedBox(width: 4),
                    Text(
                      'Premium',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholderAvatar() {
    return Container(
      color: AppColors.grey.withValues(alpha: 0.2),
      child: const Icon(
        Icons.person,
        size: 60,
        color: AppColors.grey,
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - DESERVEPAGE ID CARD
  // ============================================

  Widget _buildDeservepageIdCard() {
    final deservepageId = widget.userData['deservepage_id']?.toString() ?? 'N/A';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DeservePage ID',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  deservepageId,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: _copyDeservepageId,
            icon: const Icon(Icons.copy, size: 20),
            color: AppColors.primary,
            tooltip: 'Kopyala',
          ),
        ],
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - STATS ROW
  // ============================================

  Widget _buildStatsRow(int rank) {
    final totalVotes = widget.userData['total_votes'] as int? ?? 0;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Toplam Oy',
            '$totalVotes',
            Icons.how_to_vote,
            AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Sıralama',
            '#$rank',
            Icons.leaderboard,
            AppColors.secondary,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }
  // ============================================
  // UI COMPONENTS - SCORE CARD
  // ============================================

  Widget _buildScoreCard(double averageScore) {
    final scoreColor = _getScoreColor(averageScore);
    
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scoreColor.withValues(alpha: 0.2),
            scoreColor.withValues(alpha: 0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: scoreColor.withValues(alpha: 0.3),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.star,
                color: scoreColor,
                size: 32,
              ),
              const SizedBox(width: 12),
              const Text(
                'Ortalama Puan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Circular progress indicator
          SizedBox(
            width: 160,
            height: 160,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Background circle
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: 1.0,
                    strokeWidth: 12,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppColors.grey.withValues(alpha: 0.2),
                    ),
                  ),
                ),
                // Foreground circle (score)
                SizedBox(
                  width: 160,
                  height: 160,
                  child: CircularProgressIndicator(
                    value: averageScore / 10,
                    strokeWidth: 12,
                    backgroundColor: Colors.transparent,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                    strokeCap: StrokeCap.round,
                  ),
                ),
                // Score text
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      averageScore.toStringAsFixed(1),
                      style: TextStyle(
                        fontSize: 56,
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                        height: 1,
                      ),
                    ),
                    const Text(
                      '/10',
                      style: TextStyle(
                        fontSize: 20,
                        color: AppColors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          
          // Score badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: scoreColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: scoreColor.withValues(alpha: 0.5),
              ),
            ),
            child: Text(
              _getScoreBadgeText(averageScore),
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: scoreColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - DETAILED SCORES
  // ============================================

  Widget _buildDetailedScores() {
    final courageScore = (widget.userData['courage_score'] as num?)?.toDouble() ?? 0.0;
    final honestyScore = (widget.userData['honesty_score'] as num?)?.toDouble() ?? 0.0;
    final loyaltyScore = (widget.userData['loyalty_score'] as num?)?.toDouble() ?? 0.0;
    final workEthicScore = (widget.userData['work_ethic_score'] as num?)?.toDouble() ?? 0.0;
    final disciplineScore = (widget.userData['discipline_score'] as num?)?.toDouble() ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: AppColors.primary, size: 24),
              SizedBox(width: 12),
              Text(
                'Detaylı Puanlar',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // 5 dimension scores
          _buildScoreBar(
            'Cesaret',
            courageScore,
            Icons.local_fire_department,
            const Color(0xFFFF5722),
          ),
          const SizedBox(height: 16),
          _buildScoreBar(
            'Dürüstlük',
            honestyScore,
            Icons.handshake,
            const Color(0xFF2196F3),
          ),
          const SizedBox(height: 16),
          _buildScoreBar(
            'Sadakat',
            loyaltyScore,
            Icons.shield,
            const Color(0xFF4CAF50),
          ),
          const SizedBox(height: 16),
          _buildScoreBar(
            'Çalışma Azmi',
            workEthicScore,
            Icons.work,
            const Color(0xFF9C27B0),
          ),
          const SizedBox(height: 16),
          _buildScoreBar(
            'Öz Disiplin',
            disciplineScore,
            Icons.self_improvement,
            const Color(0xFFFFA726),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreBar(
    String label,
    double score,
    IconData icon,
    Color color,
  ) {
    final percentage = (score / 10) * 100;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: AppColors.secondary,
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                score.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        
        // Progress bar
        Stack(
          children: [
            // Background bar
            Container(
              height: 10,
              decoration: BoxDecoration(
                color: AppColors.grey.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(5),
              ),
            ),
            // Foreground bar (animated)
            LayoutBuilder(
              builder: (context, constraints) {
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  width: constraints.maxWidth * (score / 10),
                  height: 10,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        color.withValues(alpha: 0.7),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 6),
        
        // Percentage text
        Text(
          '${percentage.toStringAsFixed(0)}%',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.grey.withValues(alpha: 0.7),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

// ============================================
// HELPER FUNCTION - Show Profile Modal
// ============================================

/// Helper function to show profile modal from anywhere
/// 
/// Usage:
/// ```dart
/// showProfileModal(context, userData);
/// ```
void showProfileModal(BuildContext context, Map<String, dynamic> userData) {
  ProfileModal.show(context, userData);
}

// ============================================
// File: lib/screens/voting/voting_progress_screen.dart
// PART 1/2 - Real-time voting progress with VotingService
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:share_plus/share_plus.dart';
import '../../services/voting_service.dart';

class VotingProgressScreen extends StatefulWidget {
  final String sessionId;
  final String votingLink;

  const VotingProgressScreen({
    super.key,
    required this.sessionId,
    required this.votingLink,
  });

  @override
  State<VotingProgressScreen> createState() => _VotingProgressScreenState();
}

class _VotingProgressScreenState extends State<VotingProgressScreen>
    with SingleTickerProviderStateMixin {
  late Timer _timer;
  Duration _remainingTime = const Duration(hours: 72);
  DateTime? _expiryDate;

  // Voting stats (real data from VotingService)
  int _totalVotes = 0;
  double _approvalRate = 0.0;
  double _averageScore = 0.0;
  String _sessionStatus = 'active';

  // Detailed scores
  double _scoreCourage = 0.0;
  double _scoreHonesty = 0.0;
  double _scoreLoyalty = 0.0;
  double _scoreWorkEthic = 0.0;
  double _scoreDiscipline = 0.0;

  // Animation
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // Refresh
  bool _isRefreshing = false;

  // Real-time subscription
  StreamSubscription? _voteUpdatesSubscription;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
    _loadVotingData();
    _subscribeToRealTimeUpdates();
  }

  @override
  void dispose() {
    _timer.cancel();
    _animationController.dispose();
    _voteUpdatesSubscription?.cancel();
    super.dispose();
  }

  // ============================================
  // ANIMATION SETUP
  // ============================================

  void _setupAnimation() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
  }

  // ============================================
  // LOAD VOTING DATA FROM VOTINGSERVICE
  // ============================================

  Future<void> _loadVotingData() async {
    setState(() => _isRefreshing = true);

    try {
      // Use VotingService to get session stats
      final stats = await VotingService.getSessionStats(widget.sessionId);

      if (mounted) {
        setState(() {
          _totalVotes = stats['total_votes'] ?? 0;
          _approvalRate = (stats['approval_rate'] ?? 0.0).toDouble();
          _averageScore = (stats['average_score'] ?? 0.0).toDouble();
          _sessionStatus = stats['status'] ?? 'active';

          // Detailed scores
          _scoreCourage = (stats['score_courage'] ?? 0.0).toDouble();
          _scoreHonesty = (stats['score_honesty'] ?? 0.0).toDouble();
          _scoreLoyalty = (stats['score_loyalty'] ?? 0.0).toDouble();
          _scoreWorkEthic = (stats['score_work_ethic'] ?? 0.0).toDouble();
          _scoreDiscipline = (stats['score_discipline'] ?? 0.0).toDouble();

          // Parse expiry date
          _expiryDate = DateTime.parse(stats['expires_at']);
          _remainingTime = _expiryDate!.difference(DateTime.now().toUtc());

          _isRefreshing = false;
        });

        _startTimer();
        _checkIfSessionExpired();
      }
    } catch (e) {
      debugPrint('❌ Error loading voting data: $e');
      if (mounted) {
        setState(() => _isRefreshing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Veriler yüklenemedi: $e'),
            backgroundColor: const Color(0xFFFF6B6B),
          ),
        );
      }
    }
  }

  // ============================================
  // SUBSCRIBE TO REAL-TIME UPDATES
  // ============================================

  void _subscribeToRealTimeUpdates() {
    _voteUpdatesSubscription =
        VotingService.subscribeToVoteUpdates(widget.sessionId).listen(
      (update) {
        if (mounted) {
          setState(() {
            _totalVotes = update['total_votes'] ?? _totalVotes;
            _approvalRate = (update['approval_rate'] ?? _approvalRate).toDouble();
            _averageScore = (update['average_score'] ?? _averageScore).toDouble();

            // Update detailed scores
            _scoreCourage = (update['score_courage'] ?? _scoreCourage).toDouble();
            _scoreHonesty = (update['score_honesty'] ?? _scoreHonesty).toDouble();
            _scoreLoyalty = (update['score_loyalty'] ?? _scoreLoyalty).toDouble();
            _scoreWorkEthic =
                (update['score_work_ethic'] ?? _scoreWorkEthic).toDouble();
            _scoreDiscipline =
                (update['score_discipline'] ?? _scoreDiscipline).toDouble();
          });
        }
      },
      onError: (error) {
        debugPrint('❌ Real-time update error: $error');
      },
    );
  }

  // ============================================
  // TIMER & COUNTDOWN
  // ============================================

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        });
      } else {
        timer.cancel();
        _checkFinalResult();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String hours = twoDigits(duration.inHours);
    String minutes = twoDigits(duration.inMinutes.remainder(60));
    String seconds = twoDigits(duration.inSeconds.remainder(60));
    return '$hours:$minutes:$seconds';
  }

  // ============================================
  // CHECK SESSION STATUS
  // ============================================

  void _checkIfSessionExpired() {
    if (_remainingTime.inSeconds <= 0 || _sessionStatus != 'active') {
      _checkFinalResult();
    }
  }

  Future<void> _checkFinalResult() async {
    // Check session status one more time from database
    try {
      final statusCheck =
          await VotingService.checkSessionStatus(widget.sessionId);

      if (statusCheck['is_expired'] == true && mounted) {
        if (_approvalRate >= 50.01 && _totalVotes >= 50) {
          _showSuccessDialog();
        } else {
          _showFailureDialog();
        }
      }
    } catch (e) {
      debugPrint('❌ Error checking final result: $e');
    }
  }

  // ============================================
  // SUCCESS DIALOG
  // ============================================

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF25D366).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.verified,
                size: 64,
                color: Color(0xFF25D366),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tebrikler! 🎉',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004563),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Onay sürecini başarıyla tamamladınız!\n\nDeservePage ID\'niz oluşturuluyor...',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009DE0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // FAILURE DIALOG
  // ============================================

  void _showFailureDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.cancel_outlined,
                size: 64,
                color: Color(0xFFFF6B6B),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Üzgünüz',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF004563),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Onay sürecini tamamlayamadınız.\n\n30 gün sonra tekrar deneyebilirsiniz.',
              style: TextStyle(
                fontSize: 15,
                color: Colors.grey,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009DE0),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Ana Sayfaya Dön'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // SHARE FUNCTIONS
  // ============================================

  Future<void> _copyLink() async {
    await Clipboard.setData(ClipboardData(text: 'https://${widget.votingLink}'));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Link kopyalandı!'),
          backgroundColor: const Color(0xFF25D366),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _shareLink() async {
    await Share.share(
      'YANSIMAM platformunda beni değerlendir: https://${widget.votingLink}',
      subject: 'YANSIMAM - Oyuna İhtiyacım Var',
    );
  }

  // ============================================
  // BUILD METHOD
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FC),
      appBar: AppBar(
        title: const Text('Oylama Süreci'),
        backgroundColor: const Color(0xFF004563),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Icon(Icons.refresh),
            onPressed: _isRefreshing ? null : _loadVotingData,
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: RefreshIndicator(
          onRefresh: _loadVotingData,
          color: const Color(0xFF009DE0),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimerCard(),
                  const SizedBox(height: 24),
                  _buildStatsCards(),
                  const SizedBox(height: 24),
                  _buildProgressCard(),
                  const SizedBox(height: 24),
                  if (_totalVotes > 0) ...[
                    _buildDetailedScores(),
                    const SizedBox(height: 24),
                  ],
                  _buildQuickActions(),
                  const SizedBox(height: 24),
                  _buildInfoBanner(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - TIMER CARD
  // ============================================

  Widget _buildTimerCard() {
    final hours = _remainingTime.inHours;
    final isUrgent = hours < 12;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isUrgent
              ? [
                  const Color(0xFFFFA000),
                  const Color(0xFFFF6B00),
                ]
              : [
                  const Color(0xFF004563),
                  const Color(0xFF009DE0),
                ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (isUrgent ? const Color(0xFFFFA000) : const Color(0xFF009DE0))
                .withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                isUrgent ? Icons.warning_amber : Icons.timer,
                size: 32,
                color: Colors.white,
              ),
              const SizedBox(width: 12),
              Text(
                isUrgent ? 'Süre Azalıyor!' : 'Kalan Süre',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            _formatDuration(_remainingTime),
            style: const TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isUrgent ? 'Hızlıca paylaşın!' : 'Devam eden oylama',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - STATS CARDS
  // ============================================

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            'Toplam Oy',
            '$_totalVotes',
            Icons.how_to_vote,
            const Color(0xFF009DE0),
            subtitle: 'Hedef: 50',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _buildStatCard(
            'Onay Oranı',
            '${_approvalRate.toStringAsFixed(1)}%',
            Icons.trending_up,
            _approvalRate >= 50.01
                ? const Color(0xFF25D366)
                : const Color(0xFFFFA000),
            subtitle: 'Min: %50.01',
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color, {
    String? subtitle,
  }) {
    return Container(
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
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
          ],
        ],
      ),
    );
  }
  // ============================================
  // PART 2/2 - Remaining UI Widgets
  // ============================================

  // ============================================
  // UI COMPONENTS - PROGRESS CARD
  // ============================================

  Widget _buildProgressCard() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Genel İlerleme',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004563),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _averageScore >= 7.0
                      ? const Color(0xFF25D366).withValues(alpha: 0.1)
                      : _averageScore >= 5.0
                          ? const Color(0xFFFFA000).withValues(alpha: 0.1)
                          : const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: _averageScore >= 7.0
                          ? const Color(0xFF25D366)
                          : _averageScore >= 5.0
                              ? const Color(0xFFFFA000)
                              : const Color(0xFFFF6B6B),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _totalVotes > 0
                          ? _averageScore.toStringAsFixed(1)
                          : '--',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: _averageScore >= 7.0
                            ? const Color(0xFF25D366)
                            : _averageScore >= 5.0
                                ? const Color(0xFFFFA000)
                                : const Color(0xFFFF6B6B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _totalVotes > 0 ? (_averageScore / 10) : 0,
              minHeight: 12,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                _averageScore >= 7.0
                    ? const Color(0xFF25D366)
                    : _averageScore >= 5.0
                        ? const Color(0xFFFFA000)
                        : const Color(0xFFFF6B6B),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '0',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                _totalVotes > 0
                    ? '${(_averageScore * 10).toInt()}%'
                    : 'Henüz oy yok',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF009DE0),
                ),
              ),
              const Text(
                '10',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - DETAILED SCORES
  // ============================================

  Widget _buildDetailedScores() {
    return Container(
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detaylı Puanlar',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF004563),
            ),
          ),
          const SizedBox(height: 20),
          _buildScoreRow('Cesaret', _scoreCourage, Icons.shield),
          const SizedBox(height: 16),
          _buildScoreRow('Dürüstlük', _scoreHonesty, Icons.verified_user),
          const SizedBox(height: 16),
          _buildScoreRow('Bağlılık', _scoreLoyalty, Icons.favorite),
          const SizedBox(height: 16),
          _buildScoreRow('Çalışkanlık', _scoreWorkEthic, Icons.work),
          const SizedBox(height: 16),
          _buildScoreRow('Disiplin', _scoreDiscipline, Icons.military_tech),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String label, double score, IconData icon) {
    final Color scoreColor = score >= 8.0
        ? const Color(0xFF25D366)
        : score >= 6.0
            ? const Color(0xFFFFA000)
            : const Color(0xFFFF6B6B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: const Color(0xFF009DE0)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF004563),
                ),
              ),
            ),
            Text(
              score > 0 ? score.toStringAsFixed(1) : '--',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: score > 0 ? scoreColor : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: score > 0 ? (score / 10) : 0,
            minHeight: 8,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              score > 0 ? scoreColor : Colors.grey,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // UI COMPONENTS - QUICK ACTIONS
  // ============================================

  Widget _buildQuickActions() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _copyLink,
            icon: const Icon(Icons.copy, size: 18),
            label: const Text('Linki Kopyala'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF009DE0),
              side: const BorderSide(color: Color(0xFF009DE0)),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _shareLink,
            icon: const Icon(Icons.share, size: 18),
            label: const Text('Paylaş'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009DE0),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // UI COMPONENTS - INFO BANNER
  // ============================================

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF009DE0).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF009DE0).withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF009DE0), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _sessionStatus == 'active'
                  ? 'Sayfa otomatik olarak güncellenir. Daha fazla oy almak için linki paylaşmaya devam edin!'
                  : 'Oylama süreci tamamlandı. Sonuçlarınızı ana sayfadan görebilirsiniz.',
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF004563),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

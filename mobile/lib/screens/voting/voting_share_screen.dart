// ============================================
// File: lib/screens/voting/voting_share_screen.dart
// FIXED: Centered timer card + onPopInvokedWithResult
// PART 1/2
// ============================================

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:async';
import '../../services/voting_service.dart';

/// Voting Share Screen
/// 
/// Features:
/// - Real-time vote tracking
/// - QR code generation
/// - Social media sharing
/// - Countdown timer
/// - Live stats updates
/// 
/// FIXED: Centered timer card + proper navigation
class VotingShareScreen extends StatefulWidget {
  final String votingLink;
  final String sessionId;

  const VotingShareScreen({
    super.key,
    required this.votingLink,
    required this.sessionId,
  });

  @override
  State<VotingShareScreen> createState() => _VotingShareScreenState();
}

class _VotingShareScreenState extends State<VotingShareScreen> {
  late Timer _timer;
  Duration _remainingTime = const Duration(hours: 72);
  DateTime? _expiryDate;

  // Real-time vote tracking
  int _totalVotes = 0;
  double _approvalRate = 0.0;
  double _averageScore = 0.0;
  bool _isLoadingVotes = true;
  String _sessionStatus = 'active';

  // Detailed scores
  double _scoreCourage = 0.0;
  double _scoreHonesty = 0.0;
  double _scoreLoyalty = 0.0;
  double _scoreWorkEthic = 0.0;
  double _scoreDiscipline = 0.0;

  StreamSubscription? _voteUpdatesSubscription;

  // ============================================
  // LIFECYCLE METHODS
  // ============================================

  @override
  void initState() {
    super.initState();
    _loadSessionData();
    _subscribeToRealTimeUpdates();
  }

  @override
  void dispose() {
    _timer.cancel();
    _voteUpdatesSubscription?.cancel();
    super.dispose();
  }

  // ============================================
  // LOAD SESSION DATA FROM DATABASE
  // ============================================

  Future<void> _loadSessionData() async {
    try {
      final stats = await VotingService.getSessionStats(widget.sessionId);

      if (mounted) {
        setState(() {
          _totalVotes = stats['total_votes'] ?? 0;
          _approvalRate = (stats['approval_rate'] ?? 0.0).toDouble();
          _averageScore = (stats['average_score'] ?? 0.0).toDouble();
          _sessionStatus = stats['status'] ?? 'active';

          _scoreCourage = (stats['score_courage'] ?? 0.0).toDouble();
          _scoreHonesty = (stats['score_honesty'] ?? 0.0).toDouble();
          _scoreLoyalty = (stats['score_loyalty'] ?? 0.0).toDouble();
          _scoreWorkEthic = (stats['score_work_ethic'] ?? 0.0).toDouble();
          _scoreDiscipline = (stats['score_discipline'] ?? 0.0).toDouble();

          _expiryDate = DateTime.parse(stats['expires_at']);
          _remainingTime = _expiryDate!.difference(DateTime.now().toUtc());

          _isLoadingVotes = false;
        });

        _startTimer();
        _checkIfExpired();
      }
    } catch (e) {
      debugPrint('❌ Error loading session data: $e');
      if (mounted) {
        setState(() => _isLoadingVotes = false);
      }
      _startTimer();
    }
  }

  void _checkIfExpired() {
    if (_remainingTime.inSeconds <= 0 && _sessionStatus == 'active') {
      _showExpiryDialog();
    }
  }

  void _showExpiryDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Süre Doldu',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'Oylama süreniz tamamlandı. Sonuçlarınızı görüntülemek için ana sayfaya dönün.',
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009DE0),
            ),
            child: const Text('Ana Sayfaya Dön'),
          ),
        ],
      ),
    );
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

            _scoreCourage = (update['score_courage'] ?? _scoreCourage).toDouble();
            _scoreHonesty = (update['score_honesty'] ?? _scoreHonesty).toDouble();
            _scoreLoyalty = (update['score_loyalty'] ?? _scoreLoyalty).toDouble();
            _scoreWorkEthic =
                (update['score_work_ethic'] ?? _scoreWorkEthic).toDouble();
            _scoreDiscipline =
                (update['score_discipline'] ?? _scoreDiscipline).toDouble();

            _isLoadingVotes = false;
          });
        }
      },
      onError: (error) {
        debugPrint('❌ Real-time update error: $error');
      },
    );
  }

  // ============================================
  // TIMER FOR COUNTDOWN
  // ============================================

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingTime.inSeconds > 0) {
        setState(() {
          _remainingTime = Duration(seconds: _remainingTime.inSeconds - 1);
        });
      } else {
        timer.cancel();
        _checkIfExpired();
      }
    });
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final days = duration.inDays;
    final hours = duration.inHours.remainder(24);
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    if (days > 0) {
      return '$days gün ${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
    }
    return '${twoDigits(hours)}:${twoDigits(minutes)}:${twoDigits(seconds)}';
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

  Future<void> _shareViaWhatsApp() async {
    final message = '''
Merhaba! 👋

Sosyal çevremin görüşü benim için çok önemli. YANSIMAM platformunda kimliğimi doğrulamak ve DeservePage ID kazanmak için oyuna ihtiyacım var.

5 basit soruyla beni değerlendirebilir misin? Sadece 2 dakika sürüyor ve tamamen anonim.

https://${widget.votingLink}

Teşekkürler! 💙
''';

    try {
      await Share.share(
        message,
        subject: 'YANSIMAM - Oyuna İhtiyacım Var',
      );
    } catch (e) {
      debugPrint('Error sharing: $e');
    }
  }

  Future<void> _shareViaInstagram() async {
    await Share.share(
      'YANSIMAM platformunda beni değerlendir: https://${widget.votingLink}',
      subject: 'YANSIMAM - Oyuna İhtiyacım Var',
    );
  }

  Future<void> _shareViaTwitter() async {
    final twitterUrl =
        'https://twitter.com/intent/tweet?text=${Uri.encodeComponent(
      'YANSIMAM platformunda beni değerlendir! https://${widget.votingLink}',
    )}';

    await Share.share(
      twitterUrl,
      subject: 'YANSIMAM - Oyuna İhtiyacım Var',
    );
  }

  Future<void> _shareViaSystem() async {
    await Share.share(
      'YANSIMAM platformunda beni değerlendir: https://${widget.votingLink}',
      subject: 'YANSIMAM - Oyuna İhtiyacım Var',
    );
  }

  Future<void> _refreshStats() async {
    setState(() => _isLoadingVotes = true);
    await _loadSessionData();
  }

  // ============================================
  // NAVIGATE TO HOME
  // ============================================

  void _navigateToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  // ============================================
  // BUILD METHOD (FIXED: onPopInvokedWithResult)
  // ============================================

  @override
  Widget build(BuildContext context) {
    // ✅ FIXED: onPopInvoked → onPopInvokedWithResult
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          _navigateToHome();
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F9FC),
        appBar: AppBar(
          title: const Text('Linki Paylaş'),
          backgroundColor: const Color(0xFF004563),
          foregroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _navigateToHome,
          ),
          actions: [
            IconButton(
              icon: _isLoadingVotes
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.refresh),
              onPressed: _isLoadingVotes ? null : _refreshStats,
            ),
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: _navigateToHome,
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _refreshStats,
          color: const Color(0xFF009DE0),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTimerCard(),
                  const SizedBox(height: 20),
                  _buildVoteStatsCard(),
                  const SizedBox(height: 24),
                  if (_totalVotes > 0) ...[
                    _buildDetailedScoresCard(),
                    const SizedBox(height: 24),
                  ],
                  _buildQRCodeCard(),
                  const SizedBox(height: 24),
                  _buildLinkCard(),
                  const SizedBox(height: 24),
                  _buildShareOptionsTitle(),
                  const SizedBox(height: 16),
                  _buildSocialMediaButtons(),
                  const SizedBox(height: 24),
                  _buildTipsSection(),
                  const SizedBox(height: 24),
                  _buildDoneButton(),
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
  // UI COMPONENTS - TIMER CARD (FIXED: FULLY CENTERED)
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
              ? [const Color(0xFFFFA000), const Color(0xFFFF6B00)]
              : [const Color(0xFF004563), const Color(0xFF009DE0)],
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
        // ✅ FIX: Tüm içerik ortalandı
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            isUrgent ? Icons.warning_amber : Icons.timer,
            size: 48,
            color: Colors.white,
          ),
          const SizedBox(height: 12),
          Text(
            isUrgent ? 'Süre Azalıyor!' : 'Kalan Süre',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
            textAlign: TextAlign.center, // ✅ Text ortalandı
          ),
          const SizedBox(height: 8),
          Text(
            _formatDuration(_remainingTime),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              letterSpacing: 1,
            ),
            textAlign: TextAlign.center, // ✅ Text ortalandı
          ),
          const SizedBox(height: 12),
          // ✅ FIX: Container ortalandı
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min, // ✅ Content-based width
                children: [
                  const Icon(Icons.people, color: Colors.white, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Hedef: 50 oy • Toplam: $_totalVotes oy',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - VOTE STATS CARD
  // ============================================

  Widget _buildVoteStatsCard() {
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
            children: [
              const Icon(Icons.analytics, color: Color(0xFF009DE0), size: 24),
              const SizedBox(width: 12),
              const Text(
                'Anlık Sonuçlar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004563),
                ),
              ),
              const Spacer(),
              if (_isLoadingVotes)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.circle, color: Color(0xFF4CAF50), size: 8),
                      SizedBox(width: 4),
                      Text(
                        'Canlı',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF4CAF50),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  'Onay Oranı',
                  '${_approvalRate.toStringAsFixed(1)}%',
                  Icons.thumb_up,
                  _approvalRate >= 50.01
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFFA000),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
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
            children: [
              Expanded(
                child: _buildStatItem(
                  'Ort. Puan',
                  '${_averageScore.toStringAsFixed(1)}/10',
                  Icons.star,
                  _averageScore >= 7.5
                      ? const Color(0xFF4CAF50)
                      : _averageScore >= 5.0
                          ? const Color(0xFFFFA000)
                          : const Color(0xFFFF6B6B),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatItem(
                  'Durum',
                  _sessionStatus == 'active' ? 'Aktif' : 'Bitti',
                  Icons.info,
                  _sessionStatus == 'active'
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFF009DE0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            value: (_totalVotes / 50).clamp(0.0, 1.0),
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              _totalVotes >= 50
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFF009DE0),
            ),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 8),
          Text(
            _totalVotes >= 50
                ? '✅ Hedef tamamlandı!'
                : 'Hedefe ${50 - _totalVotes} oy kaldı',
            style: TextStyle(
              fontSize: 13,
              color: _totalVotes >= 50 ? const Color(0xFF4CAF50) : Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center, // ✅ Centered
        crossAxisAlignment: CrossAxisAlignment.center, // ✅ Centered
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
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
  // UI COMPONENTS - DETAILED SCORES CARD
  // ============================================

  Widget _buildDetailedScoresCard() {
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
          const Row(
            children: [
              Icon(Icons.bar_chart, color: Color(0xFF009DE0), size: 24),
              SizedBox(width: 12),
              Text(
                'Detaylı Puanlar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004563),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildScoreBar('Cesaret', _scoreCourage, Icons.shield),
          const SizedBox(height: 14),
          _buildScoreBar('Dürüstlük', _scoreHonesty, Icons.verified_user),
          const SizedBox(height: 14),
          _buildScoreBar('Bağlılık', _scoreLoyalty, Icons.favorite),
          const SizedBox(height: 14),
          _buildScoreBar('Çalışkanlık', _scoreWorkEthic, Icons.work),
          const SizedBox(height: 14),
          _buildScoreBar('Disiplin', _scoreDiscipline, Icons.military_tech),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, double score, IconData icon) {
    final Color scoreColor = score >= 8.0
        ? const Color(0xFF4CAF50)
        : score >= 6.0
            ? const Color(0xFFFFA000)
            : const Color(0xFFFF6B6B);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF009DE0)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF004563),
                ),
              ),
            ),
            Text(
              score > 0 ? '${score.toStringAsFixed(1)}/10' : '--',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: scoreColor,
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
            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
          ),
        ),
      ],
    );
  }
  // ============================================
  // UI COMPONENTS - QR CODE CARD
  // ============================================

  Widget _buildQRCodeCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'QR Kod',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF004563),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Telefonla tarayarak hızlıca oylama yapabilirler',
            style: TextStyle(fontSize: 13, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: const Color(0xFF009DE0).withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: QrImageView(
              data: 'https://${widget.votingLink}',
              version: QrVersions.auto,
              size: 200,
              backgroundColor: Colors.white,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF004563),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF004563),
              ),
              gapless: false,
              errorStateBuilder: (context, error) {
                return const Center(
                  child: Text(
                    'QR kod oluşturulamadı',
                    style: TextStyle(color: Color(0xFFFF6B6B)),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F9FC),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.info_outline, color: Color(0xFF009DE0), size: 18),
                SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'Ekran görüntüsü alıp paylaşabilirsiniz',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFF004563),
                    ),
                    textAlign: TextAlign.center,
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
  // UI COMPONENTS - LINK CARD
  // ============================================

  Widget _buildLinkCard() {
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
          const Row(
            children: [
              Icon(Icons.link, color: Color(0xFF009DE0), size: 24),
              SizedBox(width: 12),
              Text(
                'Oylama Linki',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004563),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F9FC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF009DE0).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.votingLink,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Color(0xFF009DE0),
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                InkWell(
                  onTap: _copyLink,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF009DE0),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.copy,
                      color: Colors.white,
                      size: 18,
                    ),
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
  // UI COMPONENTS - SHARE OPTIONS
  // ============================================

  Widget _buildShareOptionsTitle() {
    return const Row(
      children: [
        Icon(Icons.share, color: Color(0xFF009DE0), size: 24),
        SizedBox(width: 12),
        Text(
          'Hızlı Paylaşım',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF004563),
          ),
        ),
      ],
    );
  }

  Widget _buildSocialMediaButtons() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                'WhatsApp',
                Icons.chat,
                const Color(0xFF25D366),
                _shareViaWhatsApp,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSocialButton(
                'Instagram',
                Icons.camera_alt,
                const Color(0xFFE4405F),
                _shareViaInstagram,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSocialButton(
                'Twitter',
                Icons.flutter_dash,
                const Color(0xFF1DA1F2),
                _shareViaTwitter,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSocialButton(
                'Diğer',
                Icons.more_horiz,
                const Color(0xFF004563),
                _shareViaSystem,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSocialButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // ✅ Centered
          crossAxisAlignment: CrossAxisAlignment.center, // ✅ Centered
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center, // ✅ Centered
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - TIPS SECTION
  // ============================================

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF009DE0).withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF009DE0).withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline, color: Color(0xFF009DE0), size: 24),
              SizedBox(width: 12),
              Text(
                'İpuçları',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004563),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildTipItem('Arkadaşlarınızla WhatsApp gruplarında paylaşın'),
          const SizedBox(height: 10),
          _buildTipItem('Instagram hikayenizde QR kodu paylaşın'),
          const SizedBox(height: 10),
          _buildTipItem('Minimum 50 oy ve %50.01 onay hedefleyin'),
          const SizedBox(height: 10),
          _buildTipItem('Dürüst oylar için gerçek çevrenizi seçin'),
          const SizedBox(height: 10),
          _buildTipItem('Sayfa otomatik güncellenir, yenilemeye gerek yok'),
        ],
      ),
    );
  }

  Widget _buildTipItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.circle, size: 8, color: Color(0xFF009DE0)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 14,
              color: Color(0xFF004563),
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  // ============================================
  // UI COMPONENTS - DONE BUTTON
  // ============================================

  Widget _buildDoneButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        onPressed: _navigateToHome,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF009DE0),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Ana Sayfaya Dön',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

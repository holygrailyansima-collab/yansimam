// ============================================
// File: lib/screens/voting/voting_result_screen.dart
// Voting Result Screen - Shows final result after 72-hour period
// FIXED: Navigation, Error Handling, AppBar Leading
// ============================================

import 'package:flutter/material.dart';
import 'package:confetti/confetti.dart';
import '../../models/voting_session.dart';
import '../../core/config/supabase_config.dart';

/// Voting Result Screen
/// Shows the final result after 72-hour voting period
class VotingResultScreen extends StatefulWidget {
  final String votingSessionId;

  const VotingResultScreen({
    super.key,
    required this.votingSessionId,
  });

  @override
  State<VotingResultScreen> createState() => _VotingResultScreenState();
}

class _VotingResultScreenState extends State<VotingResultScreen> {
  late ConfettiController _confettiController;
  VotingSession? _session;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 3));
    _loadVotingResult();
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  /// Load voting result from database
  Future<void> _loadVotingResult() async {
    try {
      // ✅ FIX: Better error handling with maybeSingle
      final response = await SupabaseConfig.client
          .from('voting_sessions')
          .select()
          .eq('id', widget.votingSessionId)
          .maybeSingle();

      // ✅ FIX: Handle null response (voting not found)
      if (response == null) {
        setState(() {
          _errorMessage = 'Bu oylama bulunamadı veya silinmiş olabilir.';
          _isLoading = false;
        });
        return;
      }

      setState(() {
        _session = VotingSession.fromJson(response);
        _isLoading = false;
      });

      // Trigger confetti if approved
      if (_session!.isApproved) {
        _confettiController.play();
      }
    } catch (e) {
      debugPrint('❌ Error loading voting result: $e');
      setState(() {
        _errorMessage = 'Sonuç yüklenemedi. Lütfen internet bağlantınızı kontrol edin.';
        _isLoading = false;
      });
    }
  }

  /// Update user status to approved
  Future<void> _updateUserStatus() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) return;

      await SupabaseConfig.client.from('users').update({
        'status': 'approved',
        'deservepage_id': _generateDeservepageId(),
        'average_score': _session!.averageScore,
        'total_votes': _session!.totalVotes,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } catch (e) {
      debugPrint('⚠️ Failed to update user status: $e');
      // Silent fail - don't block user experience
    }
  }

  /// Generate unique DeservePage ID (8 digits)
  String _generateDeservepageId() {
    return DateTime.now().millisecondsSinceEpoch.toString().substring(5, 13);
  }

  /// Share success on social media
  void _shareSuccess() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Paylaşım özelliği yakında eklenecek!'),
        backgroundColor: Color(0xFF009DE0),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Navigate to premium upgrade
  void _navigateToPremium() {
    Navigator.of(context).pushNamed('/premium');
  }

  /// Navigate back to home
  void _navigateToHome() {
    Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return _buildLoadingScreen();
    }

    if (_errorMessage != null) {
      return _buildErrorScreen();
    }

    if (_session == null) {
      return _buildErrorScreen();
    }

    // Check if approved or failed
    if (_session!.isApproved) {
      return _buildSuccessScreen();
    } else {
      return _buildFailureScreen();
    }
  }

  /// Loading screen
  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FC),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              color: Color(0xFF009DE0),
            ),
            const SizedBox(height: 20),
            Text(
              'Sonuçlar yükleniyor...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Error screen
  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FC),
      appBar: AppBar(
        title: const Text('Hata'),
        backgroundColor: const Color(0xFF004563),
        // ✅ FIX: Properly working back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Try to pop first
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              // If can't pop, go to home
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Color(0xFFFF6B6B),
              ),
              const SizedBox(height: 20),
              Text(
                _errorMessage ?? 'Bir hata oluştu',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                onPressed: _navigateToHome,
                icon: const Icon(Icons.home),
                label: const Text('Ana Sayfaya Dön'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009DE0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Success screen (Approved >= 50.01%)
  Widget _buildSuccessScreen() {
    final deservepageId = _generateDeservepageId();
    _updateUserStatus(); // Update user status in background

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FC),
      // ✅ FIX: No back button on success (prevent going back)
      body: Stack(
        children: [
          // Confetti animation
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 20,
              gravity: 0.1,
              colors: const [
                Color(0xFF009DE0),
                Color(0xFF4CAF50),
                Color(0xFFFFA726),
                Color(0xFFFF6B6B),
              ],
            ),
          ),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  const SizedBox(height: 40),
                  // Success icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4CAF50).withOpacity(0.3),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.check_circle_outline,
                      size: 70,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Success title
                  const Text(
                    '🎉 Tebrikler!',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF004563),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Onaylandınız!',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF009DE0),
                    ),
                  ),
                  const SizedBox(height: 40),
                  // DeservePage ID card
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'DeservePage ID\'niz',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          deservepageId,
                          style: const TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF009DE0),
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Statistics card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildStatRow(
                          '📊 Toplam Onay Oranı',
                          '${_session!.approvalRate?.toStringAsFixed(1) ?? '0.0'}%',
                          const Color(0xFF4CAF50),
                        ),
                        const Divider(height: 24),
                        _buildStatRow(
                          '⭐ Ortalama Puan',
                          '${_session!.averageScore?.toStringAsFixed(1) ?? '0.0'}/10',
                          const Color(0xFF009DE0),
                        ),
                        const Divider(height: 24),
                        _buildStatRow(
                          '🗳️ Toplam Oy',
                          '${_session!.totalVotes ?? 0} kişi',
                          const Color(0xFF004563),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Detailed scores
                  if (_session!.detailedScores != null)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 20,
                            offset: const Offset(0, 5),
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
                          const SizedBox(height: 16),
                          _buildScoreBar('Dürüstlük', (_session!.detailedScores!['honesty'] ?? 0).toDouble()),
                          _buildScoreBar('Güvenilirlik', (_session!.detailedScores!['dependability'] ?? 0).toDouble()),
                          _buildScoreBar('Sosyallik', (_session!.detailedScores!['sociability'] ?? 0).toDouble()),
                          _buildScoreBar('Çalışma Azmi', (_session!.detailedScores!['work_ethic'] ?? 0).toDouble()),
                          _buildScoreBar('Öz Disiplin', (_session!.detailedScores!['discipline'] ?? 0).toDouble()),
                        ],
                      ),
                    ),
                  const SizedBox(height: 30),
                  // Share button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: _shareSuccess,
                      icon: const Icon(Icons.share),
                      label: const Text('Sosyal Medyada Paylaş'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF009DE0),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 30),
                  // Premium upgrade prompt
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF009DE0), Color(0xFF004563)],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.workspace_premium,
                          size: 50,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Premium\'a Geçin!',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Leaderboard\'da görünmek ve öne çıkmak için Premium üyeliğe geçin!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Tek Seferlik Ödeme',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        const Text(
                          '2.49 USD',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _navigateToPremium,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: const Color(0xFF009DE0),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Premium Satın Al'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton(
                                onPressed: _navigateToHome,
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Colors.white),
                                  padding: const EdgeInsets.symmetric(vertical: 14),
                                ),
                                child: const Text('Daha Sonra'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Failure screen (< 50.01%)
  Widget _buildFailureScreen() {
    final nextRetryDate = DateTime.now().add(const Duration(days: 30));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F9FC),
      appBar: AppBar(
        title: const Text('Oylama Sonucu'),
        backgroundColor: const Color(0xFF004563),
        // ✅ FIX: Working back button
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              Navigator.of(context).pushReplacementNamed('/home');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const SizedBox(height: 40),
              // Failure icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: const Color(0xFFFF6B6B),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF6B6B).withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 5,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.info_outline,
                  size: 70,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              // Title
              const Text(
                'Yeterli Onay Alınamadı',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004563),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              // Statistics card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildStatRow(
                      '📊 Alınan Oy Oranı',
                      '${_session!.approvalRate?.toStringAsFixed(1) ?? '0.0'}%',
                      const Color(0xFFFF6B6B),
                    ),
                    const Divider(height: 24),
                    _buildStatRow(
                      '⭐ Ortalama Puan',
                      '${_session!.averageScore?.toStringAsFixed(1) ?? '0.0'}/10',
                      const Color(0xFF009DE0),
                    ),
                    const Divider(height: 24),
                    _buildStatRow(
                      '🗳️ Toplam Oy',
                      '${_session!.totalVotes ?? 0} kişi',
                      const Color(0xFF004563),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Feedback card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3CD),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFFFA726),
                    width: 2,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.lightbulb_outline, color: Color(0xFFFFA726)),
                        SizedBox(width: 8),
                        Text(
                          'Geri Bildirim',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF004563),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      '• Daha fazla kişiyle paylaşmayı deneyin\n'
                      '• Sosyal medya hikayelerinde paylaşın\n'
                      '• Yakın arkadaşlarınıza direkt mesaj gönderin\n'
                      '• WhatsApp gruplarınızda paylaşın',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF004563),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Retry info card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 20,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 50,
                      color: Color(0xFF009DE0),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '30 Gün Sonra Tekrar Deneyebilirsiniz',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF004563),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sonraki deneme: ${_formatDate(nextRetryDate)}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF009DE0),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Back to home button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _navigateToHome,
                  icon: const Icon(Icons.home),
                  label: const Text('Ana Sayfaya Dön'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF009DE0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  /// Build stat row
  Widget _buildStatRow(String label, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 16,
            color: Color(0xFF004563),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  /// Build score bar
  Widget _buildScoreBar(String label, double score) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF004563),
                ),
              ),
              Text(
                '${score.toStringAsFixed(1)}/10',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF009DE0),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score / 10,
              backgroundColor: Colors.grey[200],
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF009DE0)),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  /// Format date to Turkish format
  String _formatDate(DateTime date) {
    final months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }
}

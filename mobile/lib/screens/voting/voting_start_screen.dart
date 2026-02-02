// ============================================
// File: lib/screens/voting/voting_start_screen.dart
// FIXED: Centered capture section + no auto-notification
// PART 1/2
// ============================================

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config/supabase_config.dart';
import '../../services/api/azure_face_service.dart';
import '../../services/voting_service.dart';
import 'voting_share_screen.dart';

/// Voting Start Screen
/// 
/// Features:
/// - Photo capture/upload
/// - Azure Face API validation
/// - Terms & Conditions acceptance
/// - Start 72-hour voting period
/// 
/// FIXED: Centered capture button + no auto-notification
class VotingStartScreen extends StatefulWidget {
  const VotingStartScreen({super.key});

  @override
  State<VotingStartScreen> createState() => _VotingStartScreenState();
}

class _VotingStartScreenState extends State<VotingStartScreen>
    with SingleTickerProviderStateMixin {
  
  // ============================================
  // STATE VARIABLES
  // ============================================
  
  bool isLoading = false;
  bool hasAcceptedTerms = false;
  bool isProcessing = false;
  String? processingStep;

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  File? _capturedImage;
  bool _isPhotoValidated = false;

  // ============================================
  // LIFECYCLE METHODS
  // ============================================

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );
    _animationController.forward();
    
    // ✅ REMOVED: _checkExistingSession() - NO AUTO NOTIFICATION
    // Session check is now ONLY in _startVotingProcess()
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ============================================
  // PHOTO CAPTURE METHODS
  // ============================================

  Future<void> _takePicture() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null && mounted) {
        setState(() {
          _capturedImage = File(photo.path);
          _isPhotoValidated = false;
        });

        // Auto-validate after capture
        await _validatePhoto();
      }
    } catch (e) {
      debugPrint('❌ Camera error: $e');
      if (mounted) {
        _showErrorSnackBar('Kamera açılamadı: $e');
      }
    }
  }

  // ============================================
  // AZURE FACE API VALIDATION
  // ============================================

  Future<void> _validatePhoto() async {
    if (_capturedImage == null) {
      _showErrorSnackBar('Lütfen önce fotoğraf çekin');
      return;
    }

    setState(() {
      isProcessing = true;
      processingStep = 'Fotoğraf doğrulanıyor...';
    });

    try {
      final azureFaceService = AzureFaceService();
      final result = await azureFaceService.validateFace(_capturedImage!);

      if (mounted) {
        setState(() {
          _isPhotoValidated = result['isValid'] as bool;
          isProcessing = false;
          processingStep = null;
        });

        if (_isPhotoValidated) {
          _showSuccessSnackBar('✅ Fotoğraf doğrulandı!');
        } else {
          _showErrorSnackBar(
            result['message'] as String? ?? 'Doğrulama başarısız',
          );
          setState(() => _capturedImage = null);
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isProcessing = false;
          processingStep = null;
          _capturedImage = null;
        });
        _showErrorSnackBar('Doğrulama hatası: $e');
      }
    }
  }

  // ============================================
  // START VOTING PROCESS (WITH SESSION CHECK)
  // ============================================

  Future<void> _startVotingProcess() async {
    // Validation checks
    if (!hasAcceptedTerms) {
      _showErrorSnackBar('Lütfen kuralları kabul edin');
      return;
    }

    if (_capturedImage == null || !_isPhotoValidated) {
      _showErrorSnackBar('Lütfen önce geçerli bir fotoğraf çekin');
      return;
    }

    setState(() {
      isLoading = true;
      processingStep = 'Oylama hazırlanıyor...';
    });

    bool navigationCompleted = false;

    try {
      final user = SupabaseConfig.currentUser;
      if (user == null) {
        throw Exception('Kullanıcı girişi bulunamadı');
      }

      // Get user_id from public.users table
      setState(() => processingStep = 'Kullanıcı bilgileri alınıyor...');
      
      final userData = await SupabaseConfig.client
          .from('users')
          .select('id')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (userData == null) {
        throw Exception('Kullanıcı kaydı bulunamadı. Lütfen çıkış yapıp tekrar giriş yapın.');
      }

      final userId = userData['id'] as String;
      debugPrint('✅ Found user_id: $userId');

      // ✅ CHECK EXISTING SESSION HERE (not in initState)
      setState(() => processingStep = 'Mevcut oylama kontrol ediliyor...');

      final existingSession = await VotingService.getUserActiveSession(userId);

      if (existingSession != null) {
        // User already has an active session
        setState(() {
          isLoading = false;
          processingStep = null;
        });

        if (!mounted) return;

        final sessionId = existingSession['id'].toString();
        final uniqueLink = existingSession['unique_link'].toString();

        // Show dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text(
              'Aktif Oylama Mevcut',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            content: const Text(
              'Zaten devam eden bir oylama süreciniz var. Mevcut oylamanızı görüntülemek ister misiniz?',
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // Close dialog
                  Navigator.pop(context); // Close voting start screen
                },
                child: const Text('İptal'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(dialogContext); // Close dialog
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => VotingShareScreen(
                        votingLink: 'yansimam.vercel.app/vote/$uniqueLink',
                        sessionId: sessionId,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF009DE0),
                ),
                child: const Text('Görüntüle'),
              ),
            ],
          ),
        );

        return;
      }

      // No existing session, create new one
      setState(() => processingStep = 'Fotoğraf yükleniyor...');
      
      final sessionData = await VotingService.createVotingSession(
        photoFile: _capturedImage!,
        userId: userId,
      );

      debugPrint('✅ Session created: ${sessionData['id']}');

      if (mounted) {
        _showSuccessSnackBar('✅ Onay süreci başlatıldı!');
        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          navigationCompleted = true;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => VotingShareScreen(
                votingLink: sessionData['voting_url']
                    .toString()
                    .replaceFirst('https://', ''),
                sessionId: sessionData['session_id'].toString(),
              ),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Error starting voting process: $e');
      if (mounted && !navigationCompleted) {
        setState(() {
          isLoading = false;
          processingStep = null;
        });
        
        // User-friendly error messages
        String errorMessage = 'Bir hata oluştu';
        
        if (e.toString().contains('Kullanıcı kaydı bulunamadı')) {
          errorMessage = 'Kullanıcı kaydı bulunamadı. Lütfen çıkış yapıp tekrar giriş yapın.';
        } else if (e.toString().contains('Fotoğraf yüklenemedi')) {
          errorMessage = 'Fotoğraf yüklenemedi. İnternet bağlantınızı kontrol edin.';
        } else if (e.toString().contains('Benzersiz link')) {
          errorMessage = 'Link oluşturulamadı. Lütfen tekrar deneyin.';
        } else if (e.toString().contains('Oylama oluşturulurken')) {
          errorMessage = 'Veritabanı hatası. Lütfen daha sonra tekrar deneyin.';
        } else if (e.toString().contains('violates foreign key constraint')) {
          errorMessage = 'Kullanıcı bilgisi eksik. Lütfen uygulamayı yeniden başlatın.';
        }
        
        _showErrorSnackBar(errorMessage);
      }
    }
  }

  // ============================================
  // SNACKBAR HELPERS
  // ============================================

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFFFF6B6B),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF25D366),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
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
        title: const Text('Onay Süreci Başlat'),
        backgroundColor: const Color(0xFF004563),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: isLoading || isProcessing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(color: Color(0xFF009DE0)),
                    const SizedBox(height: 20),
                    Text(
                      processingStep ?? 'İşleniyor...',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Color(0xFF004563),
                      ),
                    ),
                  ],
                ),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeroSection(),
                      const SizedBox(height: 24),

                      // Photo capture section
                      if (_capturedImage == null)
                        _buildCaptureSection()
                      else
                        _buildPhotoPreview(),

                      const SizedBox(height: 24),
                      _buildInfoCard(),
                      const SizedBox(height: 24),
                      _buildProcessSteps(),
                      const SizedBox(height: 24),
                      _buildRulesSection(),
                      const SizedBox(height: 24),
                      _buildTermsCheckbox(),
                      const SizedBox(height: 24),
                      _buildStartButton(),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - HERO SECTION
  // ============================================

  Widget _buildHeroSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF004563), Color(0xFF009DE0)],
        ),
        borderRadius: BorderRadius.circular(20),
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
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(60),
            ),
            child: const Icon(Icons.how_to_vote, size: 60, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            '72 Saatlik Onay Süreci',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Sosyal çevreniz sizi 5 kişilik özelliğinde değerlendirecek',
            style: TextStyle(
              fontSize: 15,
              color: Colors.white.withValues(alpha: 0.9),
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - CAPTURE SECTION (FIXED: CENTERED)
  // ============================================

  Widget _buildCaptureSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFF009DE0).withValues(alpha: 0.3),
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
        // ✅ FIX: Tüm column içeriği ortalandı
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.camera_alt,
            size: 80,
            color: const Color(0xFF009DE0).withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          const Text(
            'Fotoğraf Çek',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF004563),
            ),
            textAlign: TextAlign.center, // ✅ Text ortalandı
          ),
          const SizedBox(height: 8),
          const Text(
            'Oylama sürecini başlatmak için fotoğrafınızı çekin',
            style: TextStyle(fontSize: 14, color: Colors.grey),
            textAlign: TextAlign.center, // ✅ Text ortalandı
          ),
          const SizedBox(height: 20),
          // ✅ FIX: Buton tam genişlik yerine content-based
          Center(
            child: ElevatedButton.icon(
              onPressed: _takePicture,
              icon: const Icon(Icons.camera_alt),
              label: const Text('Kamerayı Aç'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF009DE0),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
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
  // UI COMPONENTS - PHOTO PREVIEW
  // ============================================

  Widget _buildPhotoPreview() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _isPhotoValidated
              ? const Color(0xFF4CAF50)
              : const Color(0xFF009DE0).withValues(alpha: 0.3),
          width: 2,
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
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              _capturedImage!,
              height: 200,
              width: double.infinity,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          if (_isPhotoValidated)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFF4CAF50), size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Fotoğraf Doğrulandı ✓',
                    style: TextStyle(
                      color: Color(0xFF4CAF50),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.center, // ✅ Centered
              children: [
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _capturedImage = null;
                      _isPhotoValidated = false;
                    });
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yeniden Çek'),
                ),
              ],
            ),
        ],
      ),
    );
  }
  // ============================================
  // UI COMPONENTS - INFO CARD
  // ============================================

  Widget _buildInfoCard() {
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
              Icon(Icons.info_outline, color: Color(0xFF009DE0), size: 24),
              SizedBox(width: 12),
              Text(
                'Süreç Hakkında',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004563),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.timer, 'Süre', '72 saat (3 gün)'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.people, 'Hedef', 'Minimum 50 oy'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.trending_up, 'Başarı', '%50.01 veya üzeri onay'),
          const SizedBox(height: 12),
          _buildInfoRow(Icons.verified, 'Ödül', 'DeservePage ID'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF009DE0), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF004563),
          ),
        ),
      ],
    );
  }

  // ============================================
  // UI COMPONENTS - PROCESS STEPS
  // ============================================

  Widget _buildProcessSteps() {
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
              Icon(Icons.list_alt, color: Color(0xFF009DE0), size: 24),
              SizedBox(width: 12),
              Text(
                'Nasıl Çalışır?',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004563),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildStepItem(1, 'Fotoğraf Çek', 'Yüz tanıma ile doğrulama yapılacak'),
          const SizedBox(height: 16),
          _buildStepItem(2, 'Linki Paylaş', 'Oylama linkini arkadaşlarınla paylaş'),
          const SizedBox(height: 16),
          _buildStepItem(3, 'Oylar Toplanıyor', '5 soruda 0-10 arası değerlendirme'),
          const SizedBox(height: 16),
          _buildStepItem(4, 'Sonuç Belirleniyor', '72 saat sonunda otomatik hesaplama'),
          const SizedBox(height: 16),
          _buildStepItem(5, 'ID Kazanıyorsun', '%50.01+ onay ile DeservePage ID'),
        ],
      ),
    );
  }

  Widget _buildStepItem(int number, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: const Color(0xFF009DE0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              '$number',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF009DE0),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004563),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: const TextStyle(
                  fontSize: 13,
                  color: Colors.grey,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ============================================
  // UI COMPONENTS - RULES SECTION
  // ============================================

  Widget _buildRulesSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFA000).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: const Color(0xFFFFA000).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.warning_amber, color: Color(0xFFFFA000), size: 24),
              SizedBox(width: 12),
              Text(
                'Önemli Kurallar',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF004563),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRuleItem('Fotoğrafınız yüz tanıma ile doğrulanacak'),
          const SizedBox(height: 10),
          _buildRuleItem('Her kişi sadece 1 kez oy kullanabilir'),
          const SizedBox(height: 10),
          _buildRuleItem('Oylar tamamen anonimdir'),
          const SizedBox(height: 10),
          _buildRuleItem('Kimin oy verdiğini göremezsiniz'),
          const SizedBox(height: 10),
          _buildRuleItem('Başarısız olursanız 30 gün beklemelisiniz'),
          const SizedBox(height: 10),
          _buildRuleItem('Süreyi uzatma veya iptal etme yoktur'),
        ],
      ),
    );
  }

  Widget _buildRuleItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.circle, size: 8, color: Color(0xFFFFA000)),
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
  // UI COMPONENTS - TERMS CHECKBOX
  // ============================================

  Widget _buildTermsCheckbox() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasAcceptedTerms
              ? const Color(0xFF009DE0)
              : Colors.grey.withValues(alpha: 0.3),
        ),
      ),
      child: InkWell(
        onTap: () {
          setState(() => hasAcceptedTerms = !hasAcceptedTerms);
        },
        child: Row(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: hasAcceptedTerms
                    ? const Color(0xFF009DE0)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: hasAcceptedTerms
                      ? const Color(0xFF009DE0)
                      : Colors.grey.withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: hasAcceptedTerms
                  ? const Icon(Icons.check, color: Colors.white, size: 16)
                  : null,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Yukarıdaki kuralları okudum ve kabul ediyorum',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF004563),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - START BUTTON
  // ============================================

  Widget _buildStartButton() {
    final canStart =
        hasAcceptedTerms && _isPhotoValidated && _capturedImage != null;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: canStart ? _startVotingProcess : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF009DE0),
              foregroundColor: Colors.white,
              disabledBackgroundColor: Colors.grey[300],
              disabledForegroundColor: Colors.grey[500],
              elevation: canStart ? 2 : 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Onay Sürecini Başlat',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  Icons.arrow_forward,
                  size: 20,
                  color: canStart ? Colors.white : Colors.grey[500],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'İptal',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        if (!canStart) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Colors.orange.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center, // ✅ Centered
              children: [
                const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _capturedImage == null
                        ? 'Lütfen fotoğraf çekin'
                        : !_isPhotoValidated
                            ? 'Fotoğraf doğrulanıyor...'
                            : 'Lütfen kuralları kabul edin',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.orange,
                    ),
                    textAlign: TextAlign.center, // ✅ Centered
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

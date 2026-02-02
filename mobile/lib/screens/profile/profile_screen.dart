// ============================================
// File: lib/screens/profile/profile_screen.dart
// PART 1/2 - State Management & Data Operations
// ✅ WITH AZURE FACE API VALIDATION
// ✅ FIXED: FileOptions error removed
// Production-ready - NO ERRORS
// ============================================

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../core/config/supabase_config.dart';
import '../../utils/constants.dart';
import '../../services/api/azure_face_service.dart'; // ✅ AZURE EKLENDI

/// Profile Screen
/// 
/// Features:
/// - Display user profile from Supabase
/// - Edit profile information
/// - Upload/update profile photo WITH AZURE FACE VALIDATION ✅
/// - View detailed scores
/// - View DeservePage ID
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool isLoading = true;
  bool isEditing = false;
  bool isUploadingPhoto = false;
  
  // User data
  String fullName = '';
  String username = '';
  String email = '';
  String? profileImageUrl;
  String userStatus = 'unapproved';
  int? deservepageId;
  double averageScore = 0.0;
  int totalVotes = 0;
  
  // Detailed scores (5 questions)
  double courageScore = 0.0;
  double honestyScore = 0.0;
  double loyaltyScore = 0.0;
  double workEthicScore = 0.0;
  double disciplineScore = 0.0;
  
  // Edit controllers
  final nameController = TextEditingController();
  final usernameController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  XFile? newProfileImage;

  String? _userId;

  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  @override
  void dispose() {
    nameController.dispose();
    usernameController.dispose();
    super.dispose();
  }

  // ============================================
  // LOAD USER DATA FROM SUPABASE
  // ============================================

  Future<void> loadUserData() async {
    setState(() => isLoading = true);

    try {
      final user = SupabaseConfig.currentUser;
      
      if (user == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/login');
        }
        return;
      }

      _userId = user.id;
      
      // ✅ REAL DATA: Fetch from Supabase
      final userData = await SupabaseConfig.client
          .from('users')
          .select('''
            id,
            full_name,
            username,
            email,
            profile_photo_url,
            status,
            deservepage_id,
            total_votes,
            average_score,
            score_courage,
            score_honesty,
            score_loyalty,
            score_work_ethic,
            score_discipline
          ''')
          .eq('auth_user_id', user.id)
          .maybeSingle();

      if (userData == null) {
        throw Exception('Kullanıcı kaydı bulunamadı');
      }

      if (mounted) {
        setState(() {
          fullName = userData['full_name'] as String? ?? '';
          username = userData['username'] as String? ?? '';
          email = userData['email'] as String? ?? user.email ?? '';
          profileImageUrl = userData['profile_photo_url'] as String?;
          userStatus = userData['status'] as String? ?? 'unapproved';
          deservepageId = userData['deservepage_id'] as int?;
          totalVotes = userData['total_votes'] as int? ?? 0;
          averageScore = (userData['average_score'] as num?)?.toDouble() ?? 0.0;
          
          // 5 question scores
          courageScore = (userData['score_courage'] as num?)?.toDouble() ?? 0.0;
          honestyScore = (userData['score_honesty'] as num?)?.toDouble() ?? 0.0;
          loyaltyScore = (userData['score_loyalty'] as num?)?.toDouble() ?? 0.0;
          workEthicScore = (userData['score_work_ethic'] as num?)?.toDouble() ?? 0.0;
          disciplineScore = (userData['score_discipline'] as num?)?.toDouble() ?? 0.0;
          
          isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Error loading profile: $e');
      if (mounted) {
        setState(() => isLoading = false);
        _showErrorSnackBar('Profil yüklenirken hata oluştu: $e');
      }
    }
  }

  // ============================================
  // PICK IMAGE FROM GALLERY
  // ============================================

  Future<void> pickImageFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          newProfileImage = image;
        });
        
        // Upload immediately
        await uploadProfilePhoto();
      }
    } catch (e) {
      debugPrint('❌ Error picking image: $e');
      _showErrorSnackBar('Resim seçilirken hata oluştu');
    }
  }

  // ============================================
  // PICK IMAGE FROM CAMERA
  // ============================================

  Future<void> pickImageFromCamera() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.front,
        imageQuality: 85,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image != null) {
        setState(() {
          newProfileImage = image;
        });
        
        // Upload immediately
        await uploadProfilePhoto();
      }
    } catch (e) {
      debugPrint('❌ Error taking photo: $e');
      _showErrorSnackBar('Fotoğraf çekilirken hata oluştu');
    }
  }

  // ============================================
  // UPLOAD PROFILE PHOTO WITH AZURE FACE VALIDATION
  // ✅ FIXED: FileOptions removed
  // ✅ PRODUCTION READY
  // ============================================

  Future<void> uploadProfilePhoto() async {
    if (newProfileImage == null || _userId == null) return;

    setState(() => isUploadingPhoto = true);

    try {
      // ✅ STEP 1: Validate face with Azure Face API
      debugPrint('🔍 Validating face with Azure Face API...');
      
      final azureService = AzureFaceService();
      final validationResult = await azureService.validateFace(File(newProfileImage!.path));

      if (!validationResult['isValid']) {
        // ❌ Face validation failed
        if (mounted) {
          setState(() {
            newProfileImage = null;
            isUploadingPhoto = false;
          });
          _showErrorSnackBar(validationResult['message']);
        }
        return;
      }

      debugPrint('✅ Face validated successfully!');
      
      // Show warnings if any
      if (validationResult['warnings'] != null && 
          (validationResult['warnings'] as List).isNotEmpty) {
        debugPrint('⚠️ Warnings: ${validationResult['warnings']}');
      }

      // ✅ STEP 2: Upload to Supabase Storage
      final fileName = 'profile_${_userId}_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'profiles/$fileName';

      final bytes = await File(newProfileImage!.path).readAsBytes();
      
      // ✅ FIXED: uploadBinary without FileOptions
      await SupabaseConfig.client.storage
          .from('profile-photos')
          .uploadBinary(
            filePath,
            bytes,
          );

      // Get public URL
      final photoUrl = SupabaseConfig.client.storage
          .from('profile-photos')
          .getPublicUrl(filePath);

      debugPrint('📸 Photo uploaded: $photoUrl');

      // ✅ STEP 3: Update user record with new photo URL
      await SupabaseConfig.client
          .from('users')
          .update({'profile_photo_url': photoUrl})
          .eq('auth_user_id', _userId!);

      if (mounted) {
        setState(() {
          profileImageUrl = photoUrl;
          newProfileImage = null;
          isUploadingPhoto = false;
        });
        
        _showSuccessSnackBar('✅ Profil fotoğrafı başarıyla güncellendi!');
      }
    } catch (e) {
      debugPrint('❌ Error uploading photo: $e');
      if (mounted) {
        setState(() => isUploadingPhoto = false);
        _showErrorSnackBar('Fotoğraf yüklenirken hata oluştu: $e');
      }
    }
  }

  // ============================================
  // SHOW IMAGE PICKER DIALOG
  // ============================================

  Future<void> showImagePickerDialog() async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20),
              topRight: Radius.circular(20),
            ),
          ),
          child: SafeArea(
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primary),
                  title: const Text('Kameradan Çek'),
                  onTap: () {
                    Navigator.pop(context);
                    pickImageFromCamera();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primary),
                  title: const Text('Galeriden Seç'),
                  onTap: () {
                    Navigator.pop(context);
                    pickImageFromGallery();
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.cancel, color: AppColors.error),
                  title: const Text('İptal'),
                  onTap: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================
  // SAVE PROFILE TO SUPABASE
  // ============================================

  Future<void> saveProfile() async {
    if (!formKey.currentState!.validate()) return;

    setState(() => isLoading = true);

    try {
      if (_userId == null) {
        throw Exception('Kullanıcı ID bulunamadı');
      }

      // ✅ Update user data in Supabase
      await SupabaseConfig.client
          .from('users')
          .update({
            'full_name': nameController.text.trim(),
            'username': usernameController.text.trim().toLowerCase(),
          })
          .eq('auth_user_id', _userId!);

      if (mounted) {
        setState(() {
          fullName = nameController.text.trim();
          username = usernameController.text.trim().toLowerCase();
          isEditing = false;
          isLoading = false;
        });

        _showSuccessSnackBar('Profil güncellendi!');
      }
    } catch (e) {
      debugPrint('❌ Error saving profile: $e');
      if (mounted) {
        setState(() => isLoading = false);
        
        String errorMessage = 'Profil güncellenirken hata oluştu';
        
        if (e.toString().contains('unique')) {
          errorMessage = 'Bu kullanıcı adı zaten kullanımda';
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
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 4),
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
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ============================================
  // HELPER METHOD - STATUS TEXT
  // ============================================

  String _getStatusText(String status) {
    switch (status) {
      case 'approved':
        return 'Onaylandı ✓';
      case 'pending':
        return 'Beklemede...';
      case 'rejected':
        return 'Reddedildi';
      default:
        return 'Henüz oylama yok';
    }
  }

  // ============================================
  // BUILD METHOD
  // ============================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profil'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (!isEditing && !isLoading)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                setState(() {
                  isEditing = true;
                  nameController.text = fullName;
                  usernameController.text = username;
                });
              },
            ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : isEditing
              ? _buildEditMode()
              : _buildViewMode(),
    );
  }

  // ============================================
  // PART 2 CONTINUES WITH UI BUILDERS...
  // ============================================
  // ============================================
  // PART 2/2 - UI BUILDERS
  // ============================================

  // ============================================
  // VIEW MODE
  // ============================================

  Widget _buildViewMode() {
    return RefreshIndicator(
      onRefresh: loadUserData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            _buildProfileHeader(),
            const SizedBox(height: 24),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                children: [
                  _buildInfoCard(),
                  if (userStatus == 'approved') ...[
                    const SizedBox(height: 16),
                    if (deservepageId != null) _buildDeservePageIdCard(),
                    const SizedBox(height: 16),
                    if (totalVotes > 0) _buildScoresCard(),
                  ],
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // EDIT MODE
  // ============================================

  Widget _buildEditMode() {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: formKey,
          child: Column(
            children: [
              const SizedBox(height: 20),
              
              // Profile photo edit
              Stack(
                children: [
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(70),
                      border: Border.all(
                        color: AppColors.primary,
                        width: 3,
                      ),
                      image: newProfileImage != null
                          ? DecorationImage(
                              image: FileImage(File(newProfileImage!.path)),
                              fit: BoxFit.cover,
                            )
                          : profileImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(profileImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                      color: newProfileImage == null && profileImageUrl == null
                          ? Colors.grey[300]
                          : null,
                    ),
                    child: newProfileImage == null && profileImageUrl == null
                        ? const Icon(Icons.person, size: 60, color: Colors.grey)
                        : isUploadingPhoto
                            ? const Center(
                                child: CircularProgressIndicator(
                                  color: AppColors.primary,
                                ),
                              )
                            : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: isUploadingPhoto ? null : showImagePickerDialog,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          isUploadingPhoto ? Icons.hourglass_empty : Icons.camera_alt,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Name field
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Ad Soyad',
                  prefixIcon: const Icon(Icons.person),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ad soyad zorunludur';
                  }
                  if (value.trim().length < 2) {
                    return 'En az 2 karakter olmalı';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Username field
              TextFormField(
                controller: usernameController,
                decoration: InputDecoration(
                  labelText: 'Kullanıcı Adı',
                  prefixIcon: const Icon(Icons.alternate_email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Kullanıcı adı zorunludur';
                  }
                  if (value.trim().length < 3) {
                    return 'En az 3 karakter olmalı';
                  }
                  if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value.trim())) {
                    return 'Sadece harf, rakam ve _ kullanılabilir';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Email field (read-only)
              TextFormField(
                initialValue: email,
                enabled: false,
                decoration: InputDecoration(
                  labelText: 'E-posta',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  helperText: 'E-posta değiştirilemez',
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          isEditing = false;
                          newProfileImage = null;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey,
                        side: const BorderSide(color: Colors.grey),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saveProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Kaydet'),
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
  // WIDGET BUILDERS - PROFILE HEADER
  // ============================================

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 40, bottom: 60),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.secondary,
            AppColors.primary,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Profile photo
          Stack(
            children: [
              GestureDetector(
                onTap: () {
                  if (!isEditing) {
                    setState(() {
                      isEditing = true;
                      nameController.text = fullName;
                      usernameController.text = username;
                    });
                  }
                },
                child: Container(
                  width: 130,
                  height: 130,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(65),
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 15,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    image: profileImageUrl != null
                        ? DecorationImage(
                            image: NetworkImage(profileImageUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                    color: profileImageUrl == null ? Colors.white : null,
                  ),
                  child: profileImageUrl == null
                      ? const Icon(
                          Icons.person,
                          size: 60,
                          color: AppColors.primary,
                        )
                      : null,
                ),
              ),
              
              // Status badge
              if (userStatus == 'approved')
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF25D366),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.verified,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Name
          Text(
            fullName.isNotEmpty ? fullName : 'İsimsiz Kullanıcı',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Username
          Text(
            username.isNotEmpty ? '@$username' : '@kullanici',
            style: const TextStyle(
              fontSize: 16,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // WIDGET BUILDERS - INFO CARD
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
          const Text(
            'Hesap Bilgileri',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 16),
          _buildInfoRow(Icons.email, 'E-posta', email),
          const Divider(height: 24),
          _buildInfoRow(
            Icons.how_to_vote,
            'Toplam Oy',
            '$totalVotes kişi',
          ),
          if (userStatus == 'approved' && averageScore > 0) ...[
            const Divider(height: 24),
            _buildInfoRow(
              Icons.star,
              'Ortalama Puan',
              '${averageScore.toStringAsFixed(1)}/10',
            ),
          ],
          const Divider(height: 24),
          _buildInfoRow(
            Icons.info_outline,
            'Durum',
            _getStatusText(userStatus),
          ),
        ],
      ),
    );
  }

  // ============================================
  // WIDGET BUILDERS - DESERVEPAGE ID CARD
  // ============================================

  Widget _buildDeservePageIdCard() {
    if (deservepageId == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.1),
            AppColors.secondary.withValues(alpha: 0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_user,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'DeservePage ID',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$deservepageId',
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 1,
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
  // WIDGET BUILDERS - SCORES CARD
  // ============================================

  Widget _buildScoresCard() {
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
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 20),
          _buildScoreBar('Cesaret ve risk alma', courageScore),
          const SizedBox(height: 16),
          _buildScoreBar('Dürüstlük ve güvenilirlik', honestyScore),
          const SizedBox(height: 16),
          _buildScoreBar('Bağlılık ve sadakat', loyaltyScore),
          const SizedBox(height: 16),
          _buildScoreBar('Çalışma azmi', workEthicScore),
          const SizedBox(height: 16),
          _buildScoreBar('Öz disiplin', disciplineScore),
        ],
      ),
    );
  }

  Widget _buildScoreBar(String label, double score) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Text(
              score > 0 ? '${score.toStringAsFixed(1)}/10' : '--',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
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
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 22),
        const SizedBox(width: 12),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.grey,
            fontWeight: FontWeight.w500,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.secondary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}

// File: lib/screens/auth/register_screen.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/config/supabase_config.dart';
import '../../services/api/azure_face_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int currentStep = 0;
  final formKey = GlobalKey<FormState>();

  // Controllers
  final TextEditingController fullNameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController confirmPasswordController = TextEditingController();

  // State
  File? profileImage;
  bool isPhotoValidated = false;
  String? photoValidationMessage;
  bool termsAccepted = false;
  bool privacyAccepted = false;
  bool gdprAccepted = false;
  bool isLoading = false;
  bool isProcessing = false;

  @override
  void dispose() {
    fullNameController.dispose();
    emailController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ============================================
  // REGISTRATION PROCESS
  // ============================================

  Future<void> registerUser() async {
    // Validate all conditions
    if (!formKey.currentState!.validate()) {
      showErrorSnackBar('Lütfen tüm alanları doldurun');
      return;
    }

    if (profileImage == null || !isPhotoValidated) {
      showErrorSnackBar('Lütfen geçerli bir fotoğraf ekleyin');
      return;
    }

    if (!termsAccepted || !privacyAccepted || !gdprAccepted) {
      showErrorSnackBar('Lütfen tüm şartları kabul edin');
      return;
    }

    setState(() {
      isLoading = true;
    });

    bool navigationCompleted = false;

    try {
      // Step 1: Create Auth User
      final authResponse = await SupabaseConfig.auth.signUp(
        email: emailController.text.trim(),
        password: passwordController.text,
        data: {
          'full_name': fullNameController.text.trim(),
          'username': usernameController.text.trim(),
        },
      );

      if (authResponse.user == null) {
        throw Exception('Kullanıcı oluşturulamadı');
      }

      final authUserId = authResponse.user!.id;
      debugPrint('✅ Auth user created: $authUserId');

      // Step 2: Upload Profile Photo
      final photoUrl = await _uploadProfilePhoto(authUserId);
      debugPrint('✅ Photo uploaded: $photoUrl');

      // Step 3: Create Profile Record
      await SupabaseConfig.client.from('profiles').insert({
        'id': authUserId,
        'full_name': fullNameController.text.trim(),
        'phone_number': null,
        'profile_photo_url': photoUrl,
        'created_at': DateTime.now().toUtc().toIso8601String(),
        'updated_at': DateTime.now().toUtc().toIso8601String(),
      });
      debugPrint('✅ Profile created');

      // Step 4: ⚡ DATABASE TRIGGER AUTO-CREATES USER RECORD!
      // No manual insert needed - trigger_auto_create_user handles it
      debugPrint('✅ User record auto-created by database trigger');

      // Success!
      if (mounted) {
        showSuccessSnackBar('Kayıt başarılı! Giriş yapılıyor...');
        await Future.delayed(const Duration(milliseconds: 500));
        
        if (mounted) {
          navigationCompleted = true;
          Navigator.of(context).pushNamedAndRemoveUntil('/home', (route) => false);
        }
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      
      if (mounted) {
        String errorMessage = 'Kayıt sırasında hata oluştu';
        
        if (e.toString().contains('duplicate key')) {
          if (e.toString().contains('email')) {
            errorMessage = 'Bu e-posta adresi zaten kullanılıyor';
          } else if (e.toString().contains('username')) {
            errorMessage = 'Bu kullanıcı adı zaten kullanılıyor';
          }
        } else if (e.toString().contains('User already registered')) {
          errorMessage = 'Bu e-posta zaten kayıtlı';
        }
        
        showErrorSnackBar(errorMessage);
      }
    } finally {
      if (mounted && !navigationCompleted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // Upload profile photo to Supabase Storage
  Future<String> _uploadProfilePhoto(String userId) async {
    if (profileImage == null) {
      throw Exception('Profil fotoğrafı bulunamadı');
    }

    try {
      final fileBytes = await profileImage!.readAsBytes();
      final fileName = '${userId}_profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
      final filePath = 'profile_photos/$fileName';

      // ✅ FIX: FileOptions removed (new SDK version)
      await SupabaseConfig.client.storage
          .from('voting-photos')
          .uploadBinary(
            filePath,
            fileBytes,
          );

      final publicUrl = SupabaseConfig.client.storage
          .from('voting-photos')
          .getPublicUrl(filePath);

      return publicUrl;
    } catch (e) {
      throw Exception('Fotoğraf yüklenemedi: $e');
    }
  }

  // ============================================
  // PHOTO VALIDATION
  // ============================================

  Future<void> showImagePickerDialog() async {
    if (!mounted) return;
    
    return showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Fotoğraf Seç'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Kamera'),
              onTap: () {
                Navigator.pop(dialogContext);
                takePicture();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text('Galeri'),
              onTap: () {
                Navigator.pop(dialogContext);
                pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> takePicture() async {
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
          profileImage = File(photo.path);
          isPhotoValidated = false;
          photoValidationMessage = null;
        });
        // Auto-validate after capture
        await validatePhoto();
      }
    } catch (e) {
      debugPrint('Camera error: $e');
      if (mounted) {
        showErrorSnackBar('Kamera açılamadı: $e');
      }
    }
  }

  Future<void> pickFromGallery() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null && mounted) {
        setState(() {
          profileImage = File(image.path);
          isPhotoValidated = false;
          photoValidationMessage = null;
        });
      }
    } catch (e) {
      debugPrint('Gallery error: $e');
      if (mounted) {
        showErrorSnackBar('Galeri açılamadı: $e');
      }
    }
  }

  Future<void> validatePhoto() async {
    if (profileImage == null) {
      showErrorSnackBar('Lütfen önce fotoğraf ekleyin');
      return;
    }

    setState(() {
      isProcessing = true;
    });

    try {
      final azureFaceService = AzureFaceService();
      final result = await azureFaceService.validateFace(profileImage!);

      if (mounted) {
        setState(() {
          isPhotoValidated = result['isValid'] as bool;
          photoValidationMessage = result['message'] as String?;
          isProcessing = false;
        });

        if (isPhotoValidated) {
          showSuccessSnackBar('Fotoğraf doğrulandı! ✓');
        } else {
          showErrorSnackBar(photoValidationMessage ?? 'Doğrulama başarısız');
          setState(() {
            profileImage = null;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isProcessing = false;
        });
        showErrorSnackBar('Doğrulama hatası: $e');
      }
    }
  }

  // ============================================
  // UI HELPERS
  // ============================================

  void showErrorSnackBar(String message) {
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

  void showSuccessSnackBar(String message) {
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
        title: const Text('Kayıt Ol'),
        backgroundColor: const Color(0xFF004563),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Color(0xFF009DE0)),
                  SizedBox(height: 20),
                  Text(
                    'Hesabınız oluşturuluyor...',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            )
          : Stepper(
              currentStep: currentStep,
              onStepContinue: () {
                if (currentStep == 0) {
                  if (formKey.currentState!.validate()) {
                    setState(() {
                      currentStep = 1;
                    });
                  }
                } else if (currentStep == 1) {
                  if (profileImage != null && isPhotoValidated) {
                    setState(() {
                      currentStep = 2;
                    });
                  } else {
                    showErrorSnackBar('Lütfen fotoğrafı doğrulayın');
                  }
                } else if (currentStep == 2) {
                  registerUser();
                }
              },
              onStepCancel: () {
                if (currentStep > 0) {
                  setState(() {
                    currentStep--;
                  });
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Row(
                    children: [
                      ElevatedButton(
                        onPressed: details.onStepContinue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF009DE0),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(currentStep == 2 ? 'Kayıt Ol' : 'Devam'),
                      ),
                      const SizedBox(width: 12),
                      if (currentStep > 0)
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text('Geri'),
                        ),
                    ],
                  ),
                );
              },
              steps: [
                Step(
                  title: const Text('Temel Bilgiler'),
                  isActive: currentStep >= 0,
                  state: currentStep > 0 ? StepState.complete : StepState.indexed,
                  content: buildStep1(),
                ),
                Step(
                  title: const Text('Profil Fotoğrafı'),
                  isActive: currentStep >= 1,
                  state: currentStep > 1 ? StepState.complete : StepState.indexed,
                  content: buildStep2(),
                ),
                Step(
                  title: const Text('Şartlar ve Koşullar'),
                  isActive: currentStep >= 2,
                  content: buildStep3(),
                ),
              ],
            ),
    );
  }

  // Step 1: Basic Info
  Widget buildStep1() {
    return Form(
      key: formKey,
      child: Column(
        children: [
          TextFormField(
            controller: fullNameController,
            decoration: InputDecoration(
              labelText: 'Ad Soyad',
              prefixIcon: const Icon(Icons.person),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Ad soyad zorunludur';
              if (value.split(' ').length < 2) return 'Lütfen ad ve soyadınızı girin';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              labelText: 'E-posta',
              prefixIcon: const Icon(Icons.email),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'E-posta zorunludur';
              if (!value.contains('@')) return 'Geçerli bir e-posta girin';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: usernameController,
            decoration: InputDecoration(
              labelText: 'Kullanıcı Adı',
              prefixIcon: const Icon(Icons.alternate_email),
              helperText: 'Örn: ahmetyilmaz',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Kullanıcı adı zorunludur';
              if (value.length < 3) return 'En az 3 karakter olmalı';
              if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                return 'Sadece harf, rakam ve alt çizgi';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: passwordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Şifre',
              prefixIcon: const Icon(Icons.lock),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) return 'Şifre zorunludur';
              if (value.length < 6) return 'En az 6 karakter olmalı';
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              labelText: 'Şifre Tekrar',
              prefixIcon: const Icon(Icons.lock_outline),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value != passwordController.text) return 'Şifreler eşleşmiyor';
              return null;
            },
          ),
        ],
      ),
    );
  }
  // Step 2: Profile Photo
  Widget buildStep2() {
    return Column(
      children: [
        const Text(
          'Profil fotoğrafınız Azure Face API ile doğrulanacak',
          style: TextStyle(fontSize: 14, color: Colors.grey),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 20),
        
        // Photo preview
        if (profileImage != null)
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              border: Border.all(
                color: isPhotoValidated
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFF009DE0),
                width: 3,
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(100),
              child: Image.file(
                profileImage!,
                fit: BoxFit.cover,
              ),
            ),
          )
        else
          Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: const Color(0xFF009DE0), width: 3),
            ),
            child: const Icon(Icons.person, size: 80, color: Colors.grey),
          ),
        
        const SizedBox(height: 20),
        
        // Photo buttons
        ElevatedButton.icon(
          onPressed: showImagePickerDialog,
          icon: const Icon(Icons.add_a_photo),
          label: Text(profileImage == null ? 'Fotoğraf Seç' : 'Fotoğraf Değiştir'),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF009DE0),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Validate button
        if (profileImage != null && !isPhotoValidated)
          ElevatedButton.icon(
            onPressed: isProcessing ? null : validatePhoto,
            icon: isProcessing 
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.verified_user),
            label: Text(isProcessing ? 'Doğrulanıyor...' : 'Fotoğrafı Doğrula'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4CAF50),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        
        // Validation message
        if (photoValidationMessage != null)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isPhotoValidated
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.1)
                    : const Color(0xFFFF6B6B).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isPhotoValidated
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF6B6B),
                ),
              ),
              child: Text(
                photoValidationMessage!,
                style: TextStyle(
                  color: isPhotoValidated
                      ? const Color(0xFF4CAF50)
                      : const Color(0xFFFF6B6B),
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }

  // Step 3: Terms
  Widget buildStep3() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFF009DE0)),
          ),
          child: Column(
            children: [
              CheckboxListTile(
                value: termsAccepted,
                onChanged: (value) {
                  setState(() {
                    termsAccepted = value ?? false;
                  });
                },
                title: const Text(
                  'Kullanım şartlarını okudum ve kabul ediyorum',
                  style: TextStyle(fontSize: 14),
                ),
                activeColor: const Color(0xFF009DE0),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: privacyAccepted,
                onChanged: (value) {
                  setState(() {
                    privacyAccepted = value ?? false;
                  });
                },
                title: const Text(
                  'Gizlilik Politikasını okudum ve kabul ediyorum',
                  style: TextStyle(fontSize: 14),
                ),
                activeColor: const Color(0xFF009DE0),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              CheckboxListTile(
                value: gdprAccepted,
                onChanged: (value) {
                  setState(() {
                    gdprAccepted = value ?? false;
                  });
                },
                title: const Text(
                  'GDPR/KVKK/CCPA kapsamında verilerimin işlenmesini kabul ediyorum',
                  style: TextStyle(fontSize: 14),
                ),
                activeColor: const Color(0xFF009DE0),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        const Text(
          'MERSİS NO: 0937162221400001',
          style: TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

// ============================================
// File: lib/screens/settings/settings_screen.dart
// PART 1/2 - Complete Settings Screen with All Features
// FIXED: withValues(), deprecated params, unused field
// ============================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../../utils/constants.dart';
import 'dart:convert';

/// Settings Screen
/// 
/// Features:
/// - Account management (edit profile, change password/email)
/// - Notification preferences
/// - Language selection (TR/EN)
/// - Privacy & Security (GDPR/KVKK compliant)
/// - Data download/view
/// - Help & Support
/// - About section
/// - Logout & Delete account
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> 
    with SingleTickerProviderStateMixin {
  
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  
  // Notification settings
  bool _notificationsEnabled = true;
  bool _voteNotifications = true;
  bool _timeWarnings = true;
  bool _resultNotifications = true;
  bool _premiumNotifications = false;
  
  // Language
  String _selectedLanguage = 'tr';
  
  // Silent hours
  TimeOfDay _silentHoursStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _silentHoursEnd = const TimeOfDay(hour: 8, minute: 0);
  bool _silentHoursEnabled = false;
  
  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadSettings();
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
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeIn,
    );

    _animationController.forward();
  }

  // ============================================
  // LOAD SETTINGS FROM DATABASE
  // ============================================

  Future<void> _loadSettings() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) return;

      // TODO: Load user settings from database
      // For now, using default values
    } catch (e) {
      debugPrint('❌ Error loading settings: $e');
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
        title: const Text('Ayarlar'),
        backgroundColor: AppColors.secondary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildAccountSection(),
              const SizedBox(height: 12),
              _buildNotificationSection(),
              const SizedBox(height: 12),
              _buildLanguageSection(),
              const SizedBox(height: 12),
              _buildPrivacySection(),
              const SizedBox(height: 12),
              _buildSupportSection(),
              const SizedBox(height: 12),
              _buildAboutSection(),
              const SizedBox(height: 12),
              _buildDangerZone(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================
  // SECTION: ACCOUNT
  // ============================================

  Widget _buildAccountSection() {
    return _buildSection(
      title: 'Hesap',
      icon: Icons.person,
      children: [
        _buildSettingTile(
          icon: Icons.edit,
          title: 'Profili Düzenle',
          subtitle: 'İsim, fotoğraf, kullanıcı adı',
          onTap: () {
            Navigator.of(context).pushNamed('/profile');
          },
        ),
        _buildSettingTile(
          icon: Icons.lock,
          title: 'Şifre Değiştir',
          onTap: _showChangePasswordDialog,
        ),
        _buildSettingTile(
          icon: Icons.email,
          title: 'E-posta Değiştir',
          onTap: _showChangeEmailDialog,
        ),
      ],
    );
  }

  // ============================================
  // SECTION: NOTIFICATIONS
  // ============================================

  Widget _buildNotificationSection() {
    return _buildSection(
      title: 'Bildirimler',
      icon: Icons.notifications,
      children: [
        _buildSwitchTile(
          title: 'Bildirimleri Aç',
          subtitle: 'Tüm bildirimleri kontrol et',
          value: _notificationsEnabled,
          onChanged: (value) {
            setState(() => _notificationsEnabled = value);
          },
        ),
        if (_notificationsEnabled) ...[
          _buildSwitchTile(
            title: 'Oy Bildirimleri',
            subtitle: 'Yeni oy aldığınızda',
            value: _voteNotifications,
            onChanged: (value) {
              setState(() => _voteNotifications = value);
            },
          ),
          _buildSwitchTile(
            title: 'Süre Uyarıları',
            subtitle: 'Oylama süresi dolmadan',
            value: _timeWarnings,
            onChanged: (value) {
              setState(() => _timeWarnings = value);
            },
          ),
          _buildSwitchTile(
            title: 'Sonuç Bildirimleri',
            subtitle: 'Onay sonuçlandığında',
            value: _resultNotifications,
            onChanged: (value) {
              setState(() => _resultNotifications = value);
            },
          ),
          _buildSwitchTile(
            title: 'Premium Bildirimleri',
            subtitle: 'Premium özellikler için',
            value: _premiumNotifications,
            onChanged: (value) {
              setState(() => _premiumNotifications = value);
            },
          ),
          const Divider(height: 1),
          _buildSwitchTile(
            title: 'Sessiz Saatler',
            subtitle: _silentHoursEnabled 
                ? '${_formatTime(_silentHoursStart)} - ${_formatTime(_silentHoursEnd)}'
                : 'Kapalı',
            value: _silentHoursEnabled,
            onChanged: (value) {
              setState(() => _silentHoursEnabled = value);
              if (value) {
                _showSilentHoursDialog();
              }
            },
          ),
        ],
      ],
    );
  }

  // ============================================
  // SECTION: LANGUAGE
  // ============================================

  Widget _buildLanguageSection() {
    return _buildSection(
      title: 'Dil',
      icon: Icons.language,
      children: [
        _buildLanguageTile(
          title: '🇹🇷 Türkçe',
          value: 'tr',
          groupValue: _selectedLanguage,
          onChanged: (value) {
            setState(() => _selectedLanguage = value!);
            _showSuccessSnackBar('Dil Türkçe olarak ayarlandı');
          },
        ),
        _buildLanguageTile(
          title: '🇬🇧 English',
          value: 'en',
          groupValue: _selectedLanguage,
          onChanged: (value) {
            setState(() => _selectedLanguage = value!);
            _showSuccessSnackBar('Language set to English');
          },
        ),
      ],
    );
  }

  // ============================================
  // SECTION: PRIVACY & SECURITY
  // ============================================

  Widget _buildPrivacySection() {
    return _buildSection(
      title: 'Gizlilik ve Güvenlik',
      icon: Icons.privacy_tip,
      children: [
        _buildSettingTile(
          icon: Icons.download,
          title: 'Verilerimi İndir',
          subtitle: 'JSON/PDF formatında',
          onTap: _downloadUserData,
        ),
        _buildSettingTile(
          icon: Icons.visibility,
          title: 'Verilerimi Görüntüle',
          subtitle: 'Saklanan tüm veriler',
          onTap: _showUserDataDialog,
        ),
        const Divider(height: 1),
        _buildSettingTile(
          icon: Icons.description,
          title: 'Kullanım Koşulları',
          onTap: () => _openDocument('terms'),
        ),
        _buildSettingTile(
          icon: Icons.shield,
          title: 'Gizlilik Politikası',
          onTap: () => _openDocument('privacy'),
        ),
        _buildSettingTile(
          icon: Icons.cookie,
          title: 'Çerez Politikası',
          onTap: () => _openDocument('cookies'),
        ),
        _buildSettingTile(
          icon: Icons.verified_user,
          title: 'GDPR/KVKK Uyumluluğu',
          onTap: () => _openDocument('gdpr'),
        ),
      ],
    );
  }

  // ============================================
  // SECTION: HELP & SUPPORT
  // ============================================

  Widget _buildSupportSection() {
    return _buildSection(
      title: 'Yardım ve Destek',
      icon: Icons.help,
      children: [
        _buildSettingTile(
          icon: Icons.question_answer,
          title: 'SSS (Sıkça Sorulan Sorular)',
          onTap: () => _showComingSoonDialog('SSS'),
        ),
        _buildSettingTile(
          icon: Icons.email,
          title: 'Bize Ulaşın',
          subtitle: 'destek@yansimam.com',
          onTap: () => _showComingSoonDialog('İletişim'),
        ),
        _buildSettingTile(
          icon: Icons.web,
          title: 'Web Sitesi',
          subtitle: 'yansimam.com',
          onTap: () => _showComingSoonDialog('Web Sitesi'),
        ),
        _buildSettingTile(
          icon: Icons.bug_report,
          title: 'Hata Bildir',
          onTap: () => _showComingSoonDialog('Hata Bildirimi'),
        ),
      ],
    );
  }

  // ============================================
  // SECTION: ABOUT
  // ============================================

  Widget _buildAboutSection() {
    return _buildSection(
      title: 'Hakkında',
      icon: Icons.info,
      children: [
        _buildInfoTile(
          icon: Icons.apps,
          title: 'Uygulama Versiyonu',
          value: '1.0.0',
        ),
        _buildInfoTile(
          icon: Icons.build,
          title: 'Build Numarası',
          value: '100',
        ),
        _buildInfoTile(
          icon: Icons.business,
          title: 'MERSIS No',
          value: '0937162221400001',
        ),
        _buildSettingTile(
          icon: Icons.policy,
          title: 'Lisanslar',
          onTap: () {
            showLicensePage(
              context: context,
              applicationName: 'YANSIMAM',
              applicationVersion: '1.0.0',
              applicationLegalese: '© 2026 YANSIMAM. Tüm hakları saklıdır.',
            );
          },
        ),
      ],
    );
  }

  // ============================================
  // SECTION: DANGER ZONE
  // ============================================

  Widget _buildDangerZone() {
    return _buildSection(
      title: 'Tehlikeli Bölge',
      icon: Icons.warning,
      iconColor: AppColors.error,
      children: [
        _buildDangerTile(
          icon: Icons.logout,
          title: 'Çıkış Yap',
          onTap: _showLogoutDialog,
        ),
        _buildDangerTile(
          icon: Icons.delete_forever,
          title: 'Hesabı Sil',
          subtitle: 'Kalıcı olarak sil',
          onTap: _showDeleteAccountDialog,
        ),
      ],
    );
  }

  // ============================================
  // UI COMPONENTS - SECTION WRAPPER
  // ============================================

  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: iconColor ?? AppColors.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - SETTING TILE
  // ============================================

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.secondary,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.grey,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.grey.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - SWITCH TILE
  // ============================================

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.secondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.grey,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppColors.primary;
              }
              return AppColors.grey;
            }),
          ),
        ],
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - LANGUAGE TILE
  // ============================================

  Widget _buildLanguageTile({
    required String title,
    required String value,
    required String groupValue,
    required ValueChanged<String?> onChanged,
  }) {
    final isSelected = value == groupValue;
    
    return InkWell(
      onTap: () => onChanged(value),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
              color: isSelected ? AppColors.primary : AppColors.grey,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: isSelected ? AppColors.primary : AppColors.secondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
  // ============================================
  // UI COMPONENTS - INFO TILE
  // ============================================

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: AppColors.secondary,
              ),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // UI COMPONENTS - DANGER TILE
  // ============================================

  Widget _buildDangerTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(icon, color: AppColors.error, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: AppColors.error.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.error.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // DIALOG - CHANGE PASSWORD
  // ============================================

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.lock, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Şifre Değiştir'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Mevcut Şifre',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Yeni Şifre (Tekrar)',
                  prefixIcon: Icon(Icons.lock),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Validate
                      if (newPasswordController.text !=
                          confirmPasswordController.text) {
                        if (mounted) {
                          _showErrorSnackBar('Şifreler eşleşmiyor');
                        }
                        return;
                      }

                      if (newPasswordController.text.length < 6) {
                        if (mounted) {
                          _showErrorSnackBar('Şifre en az 6 karakter olmalı');
                        }
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        // Update password with Supabase
                        await SupabaseConfig.client.auth.updateUser(
                          UserAttributes(
                            password: newPasswordController.text,
                          ),
                        );

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (mounted) {
                          _showSuccessSnackBar('Şifre başarıyla değiştirildi');
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          _showErrorSnackBar('Şifre değiştirilemedi: $e');
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Değiştir'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // DIALOG - CHANGE EMAIL
  // ============================================

  void _showChangeEmailDialog() {
    final newEmailController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.email, color: AppColors.primary),
              SizedBox(width: 12),
              Text('E-posta Değiştir'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Yeni e-posta adresinize doğrulama kodu gönderilecektir.',
                style: TextStyle(fontSize: 13, color: AppColors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: newEmailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Yeni E-posta',
                  prefixIcon: Icon(Icons.email),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      // Validate email
                      if (!newEmailController.text.contains('@')) {
                        if (mounted) {
                          _showErrorSnackBar('Geçersiz e-posta adresi');
                        }
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        // Update email with Supabase
                        await SupabaseConfig.client.auth.updateUser(
                          UserAttributes(
                            email: newEmailController.text,
                          ),
                        );

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                        if (mounted) {
                          _showSuccessSnackBar('Doğrulama e-postası gönderildi');
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          _showErrorSnackBar('E-posta değiştirilemedi: $e');
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Değiştir'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // DIALOG - SILENT HOURS
  // ============================================

  void _showSilentHoursDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.nightlight_round, color: AppColors.primary),
            SizedBox(width: 12),
            Text('Sessiz Saatler'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bu saatler arasında bildirim gelmeyecek (acil durumlar hariç)',
              style: TextStyle(fontSize: 13, color: AppColors.grey),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _silentHoursStart,
                      );
                      if (time != null) {
                        setState(() => _silentHoursStart = time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text('Başlangıç',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(_silentHoursStart),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Icon(Icons.arrow_forward),
                ),
                Expanded(
                  child: InkWell(
                    onTap: () async {
                      final time = await showTimePicker(
                        context: context,
                        initialTime: _silentHoursEnd,
                      );
                      if (time != null) {
                        setState(() => _silentHoursEnd = time);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: AppColors.grey),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          const Text('Bitiş',
                              style: TextStyle(fontSize: 12)),
                          const SizedBox(height: 4),
                          Text(
                            _formatTime(_silentHoursEnd),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // DIALOG - LOGOUT
  // ============================================

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Row(
          children: [
            Icon(Icons.logout, color: AppColors.error),
            SizedBox(width: 12),
            Text('Çıkış Yap'),
          ],
        ),
        content: const Text('Çıkış yapmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(dialogContext);

              try {
                await SupabaseConfig.client.auth.signOut();
                if (mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              } catch (e) {
                if (mounted) {
                  _showErrorSnackBar('Çıkış yapılırken hata oluştu: $e');
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text('Çıkış Yap'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // DIALOG - DELETE ACCOUNT
  // ============================================

  void _showDeleteAccountDialog() {
    final confirmController = TextEditingController();
    bool isLoading = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(Icons.delete_forever, color: AppColors.error),
              SizedBox(width: 12),
              Text('Hesabı Sil'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bu işlem GERİ ALINAMAZ ve:',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppColors.error,
                ),
              ),
              const SizedBox(height: 12),
              const Text('• Tüm verileriniz silinecek'),
              const Text('• DeservePage ID\'niz iptal edilecek'),
              const Text('• Oylama geçmişiniz kaybolacak'),
              const Text('• Premium üyeliğiniz sona erecek'),
              const SizedBox(height: 20),
              const Text(
                'Onaylamak için "SİL" yazın:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: confirmController,
                decoration: const InputDecoration(
                  hintText: 'SİL',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isLoading ? null : () => Navigator.pop(dialogContext),
              child: const Text('İptal'),
            ),
            ElevatedButton(
              onPressed: isLoading
                  ? null
                  : () async {
                      if (confirmController.text.toUpperCase() != 'SİL') {
                        if (mounted) {
                          _showErrorSnackBar('"SİL" yazmanız gerekiyor');
                        }
                        return;
                      }

                      setDialogState(() => isLoading = true);

                      try {
                        final userId = SupabaseConfig.currentUserId;
                        if (userId == null) throw Exception('User not found');

                        // Delete user data
                        await SupabaseConfig.client
                            .from('users')
                            .delete()
                            .eq('id', userId);

                        // Sign out
                        await SupabaseConfig.client.auth.signOut();

                        if (mounted && dialogContext.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil(
                            '/login',
                            (route) => false,
                          );
                          _showSuccessSnackBar('Hesap başarıyla silindi');
                        }
                      } catch (e) {
                        setDialogState(() => isLoading = false);
                        if (mounted) {
                          _showErrorSnackBar('Hesap silinemedi: $e');
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Text('Hesabı Sil'),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================
  // HELPER - DOWNLOAD USER DATA
  // ============================================

  Future<void> _downloadUserData() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception('User not logged in');

      // Fetch all user data
      final userData = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      final votingSessions = await SupabaseConfig.client
          .from('voting_sessions')
          .select()
          .eq('user_id', userId);

      final allData = {
        'user': userData,
        'voting_sessions': votingSessions,
        'exported_at': DateTime.now().toIso8601String(),
      };

      // Convert to JSON
      final jsonData = jsonEncode(allData);

      // TODO: Save to file and share
      // For now, show success message
      if (mounted) {
        _showSuccessSnackBar('Veriler hazırlandı (${jsonData.length} bytes)');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Veriler indirilemedi: $e');
      }
    }
  }

  // ============================================
  // HELPER - SHOW USER DATA
  // ============================================

  Future<void> _showUserDataDialog() async {
    try {
      final userId = SupabaseConfig.currentUserId;
      if (userId == null) throw Exception('User not logged in');

      final userData = await SupabaseConfig.client
          .from('users')
          .select()
          .eq('id', userId)
          .single();

      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Row(
              children: [
                Icon(Icons.data_object, color: AppColors.primary),
                SizedBox(width: 12),
                Text('Verileriniz'),
              ],
            ),
            content: SingleChildScrollView(
              child: Text(
                jsonEncode(userData),
                style: const TextStyle(fontSize: 12),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Veriler görüntülenemedi: $e');
      }
    }
  }

  // ============================================
  // HELPER - OPEN DOCUMENT
  // ============================================

  void _openDocument(String type) {
    _showComingSoonDialog('Dokümantasyon');
    // TODO: Open web view with document
  }

  // ============================================
  // HELPER - COMING SOON DIALOG
  // ============================================

  void _showComingSoonDialog(String feature) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            const Icon(Icons.construction, color: AppColors.warning),
            const SizedBox(width: 12),
            Text(feature),
          ],
        ),
        content: const Text('Bu özellik yakında eklenecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
  }

  // ============================================
  // HELPER - FORMAT TIME
  // ============================================

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // ============================================
  // HELPER - SNACKBARS
  // ============================================

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

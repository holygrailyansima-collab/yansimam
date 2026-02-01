import 'package:flutter/material.dart';

/// Application Constants
/// Global constants used throughout the app
class AppConstants {
  // Prevent instantiation
  AppConstants._();

  // ==================== APP INFO ====================
  
  static const String appName = 'YANSIMAM';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Dijital Kimlik Doğrulama';
  
  // ==================== LEGAL INFO ====================
  
  static const String mersisNo = '0937-1622-2140-0001';
  static const String companyEmail = 'destek@yansimam.com';
  static const String websiteUrl = 'https://yansimam.com';
  
  // ==================== API ENDPOINTS ====================
  
  static const String webVotingBaseUrl = 'https://yansimam.vercel.app';
  
  // ==================== VOTING RULES ====================
  
  /// Voting session duration (72 hours)
  static const Duration votingDuration = Duration(hours: 72);
  
  /// Minimum votes required to complete voting
  static const int minimumVotesRequired = 10;
  
  /// Approval threshold (50.01%)
  static const double approvalThreshold = 50.01;
  
  /// Retry cooldown period after failure (30 days)
  static const Duration retryCooldown = Duration(days: 30);
  
  /// Score dimensions count
  static const int scoreDimensionsCount = 5;
  
  /// Maximum score value
  static const double maxScore = 10.0;
  
  /// Minimum score value
  static const double minScore = 0.0;
  
  // ==================== LEADERBOARD RULES ====================
  
  /// Minimum votes for leaderboard entry
  static const int leaderboardMinVotes = 50;
  
  /// Minimum average score for leaderboard entry
  static const double leaderboardMinScore = 7.5;
  
  /// Leaderboard page size
  static const int leaderboardPageSize = 50;
  
  /// Leaderboard score weight for average score
  static const double leaderboardScoreWeight = 0.7;
  
  /// Leaderboard score weight for vote count
  static const double leaderboardVotesWeight = 0.3;
  
  // ==================== PREMIUM ====================
  
  /// Premium price (USD)
  static const String premiumPrice = '2.49';
  static const String premiumCurrency = 'USD';
  
  // ==================== IMAGE UPLOAD ====================
  
  /// Maximum image size (1024x1024)
  static const int maxImageWidth = 1024;
  static const int maxImageHeight = 1024;
  
  /// Image quality (0-100)
  static const int imageQuality = 85;
  
  /// Profile photo bucket name
  static const String profilePhotosBucket = 'profile-photos';
  
  // ==================== VALIDATION ====================
  
  /// Minimum password length
  static const int minPasswordLength = 6;
  
  /// Minimum username length
  static const int minUsernameLength = 3;
  
  /// Maximum username length
  static const int maxUsernameLength = 20;
  
  /// Minimum full name words
  static const int minFullNameWords = 2;
  
  // ==================== UI CONSTANTS ====================
  
  /// Default padding
  static const double defaultPadding = 16.0;
  
  /// Default border radius
  static const double defaultBorderRadius = 12.0;
  
  /// Card elevation
  static const double cardElevation = 2.0;
  
  /// Animation duration
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  
  /// Snackbar duration
  static const Duration snackbarDuration = Duration(seconds: 3);
  
  // ==================== SCORE DIMENSIONS ====================
  
  static const List<String> scoreDimensions = [
    'Dürüstlük',
    'Güvenilirlik',
    'Sosyallik',
    'Çalışma Azmi',
    'Öz Disiplin',
  ];
  
  static const List<String> scoreDimensionsEnglish = [
    'honesty',
    'dependability',
    'sociability',
    'work_ethic',
    'discipline',
  ];
  
  static const Map<String, String> scoreDimensionEmojis = {
    'Dürüstlük': '🤝',
    'Güvenilirlik': '🛡️',
    'Sosyallik': '🎭',
    'Çalışma Azmi': '💪',
    'Öz Disiplin': '🎯',
  };
  
  // ==================== SOCIAL MEDIA ====================
  
  static const List<String> socialPlatforms = [
    'Instagram',
    'Facebook',
    'WhatsApp',
    'X (Twitter)',
    'TikTok',
    'LinkedIn',
    'Pinterest',
    'Snapchat',
  ];
  
  // ==================== OAUTH PROVIDERS ====================
  
  static const List<String> oauthProviders = [
    'Google',
    'Apple',
    'Facebook',
    'Instagram',
    'WhatsApp',
    'LinkedIn',
    'X (Twitter)',
    'TikTok',
    'Pinterest',
    'Snapchat',
  ];
  
  // ==================== ERROR MESSAGES ====================
  
  static const String errorGeneric = 'Bir hata oluştu. Lütfen tekrar deneyin.';
  static const String errorNetwork = 'İnternet bağlantısı yok.';
  static const String errorTimeout = 'İstek zaman aşımına uğradı.';
  static const String errorUnauthorized = 'Yetkilendirme hatası. Lütfen giriş yapın.';
  static const String errorNotFound = 'İstenen kaynak bulunamadı.';
  static const String errorServerError = 'Sunucu hatası. Lütfen daha sonra tekrar deneyin.';
  
  // ==================== SUCCESS MESSAGES ====================
  
  static const String successLogin = 'Giriş başarılı!';
  static const String successRegister = 'Kayıt başarılı! Giriş yapabilirsiniz.';
  static const String successUpdate = 'Güncelleme başarılı!';
  static const String successDelete = 'Silme işlemi başarılı!';
  static const String successPhotoValidated = 'Fotoğraf doğrulandı!';
  
  // ==================== VALIDATION MESSAGES ====================
  
  static const String validationEmailRequired = 'E-posta zorunludur';
  static const String validationEmailInvalid = 'Geçerli bir e-posta girin';
  static const String validationPasswordRequired = 'Şifre zorunludur';
  static const String validationPasswordTooShort = 'Şifre en az 6 karakter olmalı';
  static const String validationPasswordMismatch = 'Şifreler eşleşmiyor';
  static const String validationUsernameRequired = 'Kullanıcı adı zorunludur';
  static const String validationUsernameTooShort = 'En az 3 karakter olmalı';
  static const String validationUsernameInvalid = 'Sadece harf, rakam ve alt çizgi';
  static const String validationFullNameRequired = 'Ad soyad zorunludur';
  static const String validationFullNameInvalid = 'Lütfen ad ve soyadınızı girin';
  
  // ==================== STORAGE KEYS ====================
  
  static const String storageKeyTheme = 'theme_mode';
  static const String storageKeyLanguage = 'language';
  static const String storageKeyNotifications = 'notifications_enabled';
  static const String storageKeyFirstLaunch = 'first_launch';
  
  // ==================== AZURE FACE API ====================
  
  /// Face quality thresholds (RELAXED MODE)
  static const double faceQualityBlurThreshold = 0.3; // 0-1 (lower is better)
  static const double faceQualityExposureMin = -1.0; // -1 to 1
  static const double faceQualityExposureMax = 1.0;
  static const double faceQualityNoiseThreshold = 0.5; // 0-1 (lower is better)
  
  // ==================== SHARE MESSAGES ====================
  
  static const String defaultShareMessage = '''
Değerli Arkadaşım,

YANSIMAM uygulaması aracılığıyla sizlerden beni oylamanızı rica ediyorum.

Kimlerin oylamaya katıldığını ve ne oy verdiğini görmeyeceğim.

Size ulaşan bu oylama daveti hakkında bilgi almak isterseniz bana ulaşabilirsiniz.

MERSIS NO: $mersisNo

Oylama Linki:
''';
  
  // ==================== HELPER FUNCTIONS ====================
  
  /// Get color by score value
  static Color getScoreColor(double score) {
    if (score >= 9.0) return const Color(0xFFFFD700); // Gold
    if (score >= 8.5) return const Color(0xFFC0C0C0); // Silver
    if (score >= 8.0) return const Color(0xFFCD7F32); // Bronze
    if (score >= 7.5) return AppColors.success; // Green
    return AppColors.grey;
  }
  
  /// Get status emoji
  static String getStatusEmoji(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return '✅';
      case 'pending':
        return '⏳';
      case 'rejected':
        return '❌';
      case 'unapproved':
        return '⚪';
      default:
        return '❓';
    }
  }
  
  /// Format duration to HH:MM:SS
  static String formatDuration(Duration duration) {
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }
}

// ==================== APP ROUTES CLASS (NEW!) ====================

/// Application Routes
/// Centralized route management for type-safe navigation
class AppRoutes {
  // Prevent instantiation
  AppRoutes._();

  // ==================== ROUTE PATHS ====================
  
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String leaderboard = '/leaderboard';
  static const String premium = '/premium';
  static const String votingStart = '/voting/start';
  static const String votingShare = '/voting/share';
  static const String votingProgress = '/voting/progress';
  static const String votingResult = '/voting/result';
  
  // ==================== NAVIGATION HELPERS ====================
  
  /// Navigate to voting share screen with parameters
  /// Usage: AppRoutes.toVotingShare(context, sessionId: '123', votingLink: 'https://...')
  static Future<T?> toVotingShare<T>(
    BuildContext context, {
    required String sessionId,
    required String votingLink,
  }) {
    return Navigator.pushNamed<T>(
      context,
      votingShare,
      arguments: {
        'sessionId': sessionId,
        'votingLink': votingLink,
      },
    );
  }
  
  /// Navigate to voting progress screen with sessionId
  /// Usage: AppRoutes.toVotingProgress(context, '123')
  static Future<T?> toVotingProgress<T>(
    BuildContext context,
    String sessionId,
  ) {
    return Navigator.pushNamed<T>(
      context,
      votingProgress,
      arguments: sessionId,
    );
  }
  
  /// Navigate to voting result screen with sessionId
  /// Usage: AppRoutes.toVotingResult(context, '123')
  static Future<T?> toVotingResult<T>(
    BuildContext context,
    String sessionId,
  ) {
    return Navigator.pushNamed<T>(
      context,
      votingResult,
      arguments: sessionId,
    );
  }
  
  /// Navigate and remove all previous routes
  /// Usage: AppRoutes.toHomeAndClear(context)
  static Future<T?> toHomeAndClear<T>(BuildContext context) {
    return Navigator.pushNamedAndRemoveUntil<T>(
      context,
      home,
      (route) => false,
    );
  }
}

// ==================== APP COLORS CLASS ====================

/// Application Color Palette
/// Updated with main.dart compatibility (February 2026)
/// 
/// Brand Colors:
/// - Primary: #009DE0 (Yansimam Blue)
/// - Secondary: #004563 (Dark Trust)
/// - Background: #F4F9FC (Light Background)
class AppColors {
  // Prevent instantiation
  AppColors._();

  // ==================== PRIMARY BRAND COLORS (UPDATED) ====================
  
  /// Primary brand color - Yansimam Blue (#009DE0)
  static const Color primary = Color(0xFF009DE0);
  
  /// Secondary brand color - Dark Trust (#004563)
  static const Color secondary = Color(0xFF004563);
  
  /// Main background color (#F4F9FC)
  static const Color background = Color(0xFFF4F9FC);
  
  /// Surface color (for cards, sheets) - White
  static const Color surface = Color(0xFFFFFFFF);
  
  // ==================== SEMANTIC COLORS ====================
  
  /// Success color (Green)
  static const Color success = Color(0xFF4CAF50);
  
  /// Error/Danger color (Red)
  static const Color error = Color(0xFFFF6B6B);
  
  /// Warning color (Orange)
  static const Color warning = Color(0xFFFFA726);
  
  /// Info color (Blue)
  static const Color info = Color(0xFF2196F3);
  
  // ==================== NEUTRAL COLORS ====================
  
  /// Pure white
  static const Color white = Color(0xFFFFFFFF);
  
  /// White with 90% opacity (for text on dark backgrounds)
  static const Color whiteText = Color(0xE6FFFFFF); // 90% opacity
  
  /// Pure black
  static const Color black = Color(0xFF000000);
  
  /// Grey (medium)
  static const Color grey = Color(0xFF9E9E9E);
  
  /// Grey (light)
  static const Color greyLight = Color(0xFFE0E0E0);
  
  /// Grey (dark)
  static const Color greyDark = Color(0xFF616161);
  
  /// Card background (white)
  static const Color cardBackground = Color(0xFFFFFFFF);
  
  /// Divider color
  static const Color divider = Color(0xFFE0E0E0);
  
  // ==================== GRADIENT COLORS ====================
  
  /// Primary gradient (Secondary → Primary)
  /// Used for: App bar, headers, premium sections
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, primary],
  );
  
  /// Secondary gradient (Primary with lighter variant)
  /// Used for: Buttons, cards, highlights
  static const LinearGradient secondaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, Color(0xFF5FD1E6)],
  );
  
  /// Premium gradient (Gold shimmer)
  /// Used for: Premium badges, features
  static const LinearGradient premiumGradient = LinearGradient(
    colors: [
      Color(0xFFFFD700), // Gold
      Color(0xFFFFA500), // Orange
    ],
  );
  
  /// Network glow gradient (Primary with glow effect)
  /// Used for: Network lines, connections
  static LinearGradient networkGradient = LinearGradient(
    colors: [
      primary,
      primary.withValues(alpha: 0.5),
    ],
  );
  
  // ==================== SCORE COLORS ====================
  
  /// Gold medal color (9.0+)
  static const Color scoreGold = Color(0xFFFFD700);
  
  /// Silver medal color (8.5-8.9)
  static const Color scoreSilver = Color(0xFFC0C0C0);
  
  /// Bronze medal color (8.0-8.4)
  static const Color scoreBronze = Color(0xFFCD7F32);
  
  // ==================== DIMENSION COLORS ====================
  
  /// Dürüstlük (Honesty) - Blue
  static const Color dimensionHonesty = Color(0xFF2196F3);
  
  /// Güvenilirlik (Dependability) - Green
  static const Color dimensionDependability = Color(0xFF4CAF50);
  
  /// Sosyallik (Sociability) - Orange
  static const Color dimensionSociability = Color(0xFFFFA726);
  
  /// Çalışma Azmi (Work Ethic) - Purple
  static const Color dimensionWorkEthic = Color(0xFF9C27B0);
  
  /// Öz Disiplin (Discipline) - Red
  static const Color dimensionDiscipline = Color(0xFFFF5722);
  
  // ==================== OVERLAY COLORS ====================
  
  /// Modal barrier color (semi-transparent black)
  static Color get modalBarrier => black.withValues(alpha: 0.5);
  
  /// Shadow color (black with low opacity)
  static Color get shadow => black.withValues(alpha: 0.1);
  
  /// Shimmer base color (grey with low opacity)
  static Color get shimmerBase => grey.withValues(alpha: 0.3);
  
  /// Shimmer highlight color (white with low opacity)
  static Color get shimmerHighlight => white.withValues(alpha: 0.5);
  
  // ==================== HELPER METHODS ====================
  
  /// Get opacity variant of a color
  /// Usage: AppColors.withOpacity(AppColors.primary, 0.5)
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }
  
  /// Get lighter variant of a color
  static Color lighten(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }
  
  /// Get darker variant of a color
  static Color darken(Color color, [double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(color);
    final hslDark = hsl.withLightness(
      (hsl.lightness - amount).clamp(0.0, 1.0),
    );
    return hslDark.toColor();
  }
}

// ==================== TEXT STYLES (UPDATED) ====================

/// Application Text Styles
/// Uses AppColors for consistent theming
class AppTextStyles {
  AppTextStyles._();

  // ==================== HEADINGS ====================
  
  static const TextStyle headingLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    color: AppColors.secondary,
  );
  
  static const TextStyle headingMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.secondary,
  );
  
  static const TextStyle headingSmall = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    color: AppColors.secondary,
  );
  
  // ==================== BODY TEXT ====================
  
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    color: AppColors.black,
  );
  
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    color: AppColors.greyDark,
  );
  
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    color: AppColors.grey,
  );
  
  // ==================== SPECIAL ====================
  
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );
  
  static const TextStyle caption = TextStyle(
    fontSize: 12,
    color: AppColors.grey,
  );
  
  static const TextStyle overline = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w500,
    letterSpacing: 1.5,
    color: AppColors.grey,
  );
}

/// Form Validators
/// Helper functions for form field validation
class Validators {
  // Prevent instantiation
  Validators._();

  // ==================== EMAIL VALIDATION ====================

  /// Validate email format
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'E-posta zorunludur';
    }

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value)) {
      return 'Geçerli bir e-posta adresi girin';
    }

    return null;
  }

  /// Check if email format is valid (returns bool)
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    return emailRegex.hasMatch(email);
  }

  // ==================== PASSWORD VALIDATION ====================

  /// Validate password
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre zorunludur';
    }

    if (value.length < 6) {
      return 'Şifre en az 6 karakter olmalı';
    }

    return null;
  }

  /// Validate strong password (8+ chars, uppercase, lowercase, number)
  static String? validateStrongPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre zorunludur';
    }

    if (value.length < 8) {
      return 'Şifre en az 8 karakter olmalı';
    }

    if (!value.contains(RegExp(r'[A-Z]'))) {
      return 'En az bir büyük harf içermelidir';
    }

    if (!value.contains(RegExp(r'[a-z]'))) {
      return 'En az bir küçük harf içermelidir';
    }

    if (!value.contains(RegExp(r'[0-9]'))) {
      return 'En az bir rakam içermelidir';
    }

    return null;
  }

  /// Validate password confirmation
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı zorunludur';
    }

    if (value != password) {
      return 'Şifreler eşleşmiyor';
    }

    return null;
  }

  /// Check password strength (returns 0-3)
  /// 0: Weak, 1: Medium, 2: Strong, 3: Very Strong
  static int getPasswordStrength(String password) {
    int strength = 0;

    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[a-z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    // Map 0-5 to 0-3
    if (strength <= 1) return 0; // Weak
    if (strength == 2) return 1; // Medium
    if (strength == 3 || strength == 4) return 2; // Strong
    return 3; // Very Strong
  }

  // ==================== USERNAME VALIDATION ====================

  /// Validate username
  static String? validateUsername(String? value) {
    if (value == null || value.isEmpty) {
      return 'Kullanıcı adı zorunludur';
    }

    if (value.length < 3) {
      return 'En az 3 karakter olmalı';
    }

    if (value.length > 20) {
      return 'En fazla 20 karakter olabilir';
    }

    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    if (!usernameRegex.hasMatch(value)) {
      return 'Sadece harf, rakam ve alt çizgi kullanılabilir';
    }

    return null;
  }

  /// Check if username format is valid (returns bool)
  static bool isValidUsername(String username) {
    if (username.length < 3 || username.length > 20) return false;
    final usernameRegex = RegExp(r'^[a-zA-Z0-9_]+$');
    return usernameRegex.hasMatch(username);
  }

  // ==================== FULL NAME VALIDATION ====================

  /// Validate full name
  static String? validateFullName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Ad soyad zorunludur';
    }

    final words = value.trim().split(RegExp(r'\s+'));
    if (words.length < 2) {
      return 'Lütfen ad ve soyadınızı girin';
    }

    // Check if each word has at least 2 characters
    for (final word in words) {
      if (word.length < 2) {
        return 'Ad ve soyad en az 2 karakter olmalı';
      }
    }

    return null;
  }

  // ==================== PHONE VALIDATION ====================

  /// Validate Turkish phone number (05XX XXX XX XX)
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Telefon numarası zorunludur';
    }

    // Remove spaces and special characters
    final cleanedValue = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Turkish phone format: 05XXXXXXXXX (11 digits)
    final phoneRegex = RegExp(r'^(05)[0-9]{9}$');
    if (!phoneRegex.hasMatch(cleanedValue)) {
      return 'Geçerli bir telefon numarası girin (05XX XXX XX XX)';
    }

    return null;
  }

  /// Format phone number (05321234567 -> 0532 123 45 67)
  static String formatPhone(String phone) {
    final cleaned = phone.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (cleaned.length == 11) {
      return '${cleaned.substring(0, 4)} ${cleaned.substring(4, 7)} ${cleaned.substring(7, 9)} ${cleaned.substring(9)}';
    }
    return phone;
  }

  // ==================== NUMBER VALIDATION ====================

  /// Validate number (integer)
  static String? validateNumber(String? value, {int? min, int? max}) {
    if (value == null || value.isEmpty) {
      return 'Bu alan zorunludur';
    }

    final number = int.tryParse(value);
    if (number == null) {
      return 'Geçerli bir sayı girin';
    }

    if (min != null && number < min) {
      return 'En az $min olmalı';
    }

    if (max != null && number > max) {
      return 'En fazla $max olabilir';
    }

    return null;
  }

  /// Validate decimal number
  static String? validateDecimal(String? value, {double? min, double? max}) {
    if (value == null || value.isEmpty) {
      return 'Bu alan zorunludur';
    }

    final number = double.tryParse(value);
    if (number == null) {
      return 'Geçerli bir sayı girin';
    }

    if (min != null && number < min) {
      return 'En az $min olmalı';
    }

    if (max != null && number > max) {
      return 'En fazla $max olabilir';
    }

    return null;
  }

  // ==================== REQUIRED FIELD VALIDATION ====================

  /// Validate required field
  static String? validateRequired(String? value, [String fieldName = 'Bu alan']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName zorunludur';
    }
    return null;
  }

  // ==================== LENGTH VALIDATION ====================

  /// Validate minimum length
  static String? validateMinLength(String? value, int minLength, [String fieldName = 'Bu alan']) {
    if (value == null || value.isEmpty) {
      return '$fieldName zorunludur';
    }

    if (value.length < minLength) {
      return '$fieldName en az $minLength karakter olmalı';
    }

    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(String? value, int maxLength, [String fieldName = 'Bu alan']) {
    if (value == null || value.isEmpty) {
      return null; // Allow empty if not required
    }

    if (value.length > maxLength) {
      return '$fieldName en fazla $maxLength karakter olabilir';
    }

    return null;
  }

  /// Validate length range
  static String? validateLengthRange(
    String? value,
    int minLength,
    int maxLength, [
    String fieldName = 'Bu alan',
  ]) {
    if (value == null || value.isEmpty) {
      return '$fieldName zorunludur';
    }

    if (value.length < minLength) {
      return '$fieldName en az $minLength karakter olmalı';
    }

    if (value.length > maxLength) {
      return '$fieldName en fazla $maxLength karakter olabilir';
    }

    return null;
  }

  // ==================== URL VALIDATION ====================

  /// Validate URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'URL zorunludur';
    }

    final urlRegex = RegExp(
      r'^(https?:\/\/)?([\da-z\.-]+)\.([a-z\.]{2,6})([\/\w \.-]*)*\/?$',
    );

    if (!urlRegex.hasMatch(value)) {
      return 'Geçerli bir URL girin';
    }

    return null;
  }

  // ==================== DATE VALIDATION ====================

  /// Validate date (must be in the past)
  static String? validatePastDate(DateTime? value) {
    if (value == null) {
      return 'Tarih seçiniz';
    }

    if (value.isAfter(DateTime.now())) {
      return 'Tarih gelecekte olamaz';
    }

    return null;
  }

  /// Validate date (must be in the future)
  static String? validateFutureDate(DateTime? value) {
    if (value == null) {
      return 'Tarih seçiniz';
    }

    if (value.isBefore(DateTime.now())) {
      return 'Tarih geçmişte olamaz';
    }

    return null;
  }

  /// Validate age (18+)
  static String? validateAge(DateTime? birthDate, {int minAge = 18}) {
    if (birthDate == null) {
      return 'Doğum tarihi seçiniz';
    }

    final age = DateTime.now().year - birthDate.year;
    if (age < minAge) {
      return 'En az $minAge yaşında olmalısınız';
    }

    return null;
  }

  // ==================== CUSTOM VALIDATORS ====================

  /// Combine multiple validators
  static String? combineValidators(
    String? value,
    List<String? Function(String?)> validators,
  ) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) return error;
    }
    return null;
  }

  /// Validate against regex pattern
  static String? validatePattern(
    String? value,
    RegExp pattern,
    String errorMessage,
  ) {
    if (value == null || value.isEmpty) {
      return 'Bu alan zorunludur';
    }

    if (!pattern.hasMatch(value)) {
      return errorMessage;
    }

    return null;
  }
}

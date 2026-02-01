// ============================================
// File: lib/models/user.dart
// User Model - Kullanıcı Veri Modeli
// ============================================

class User {
  final String id;
  final String email;
  final String? username;
  final String? fullName;
  final String? avatarUrl;
  final String? deservepageId;
  final UserStatus status;
  final bool isPremium;
  final double? averageScore;
  final int? totalVotes;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? nextVotingDate;

  User({
    required this.id,
    required this.email,
    this.username,
    this.fullName,
    this.avatarUrl,
    this.deservepageId,
    required this.status,
    this.isPremium = false,
    this.averageScore,
    this.totalVotes,
    required this.createdAt,
    this.updatedAt,
    this.nextVotingDate,
  });

  // JSON'dan User objesi oluştur
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as String,
      email: json['email'] as String,
      username: json['username'] as String?,
      fullName: json['full_name'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      deservepageId: json['deservepage_id'] as String?,
      status: _parseUserStatus(json['status'] as String? ?? 'unapproved'),
      isPremium: json['is_premium'] as bool? ?? false,
      averageScore: (json['average_score'] as num?)?.toDouble(),
      totalVotes: json['total_votes'] as int?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
      nextVotingDate: json['next_voting_date'] != null
          ? DateTime.parse(json['next_voting_date'] as String)
          : null,
    );
  }

  // Helper method to parse status
  static UserStatus _parseUserStatus(String status) {
    switch (status.toLowerCase()) {
      case 'unapproved':
        return UserStatus.unapproved;
      case 'pending':
        return UserStatus.pending;
      case 'approved':
        return UserStatus.approved;
      case 'rejected':
        return UserStatus.rejected;
      default:
        return UserStatus.unapproved;
    }
  }

  // User objesini JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'deservepage_id': deservepageId,
      'status': status.name,
      'is_premium': isPremium,
      'average_score': averageScore,
      'total_votes': totalVotes,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
      'next_voting_date': nextVotingDate?.toIso8601String(),
    };
  }

  // Copy with method (değişiklik yapmak için)
  User copyWith({
    String? id,
    String? email,
    String? username,
    String? fullName,
    String? avatarUrl,
    String? deservepageId,
    UserStatus? status,
    bool? isPremium,
    double? averageScore,
    int? totalVotes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? nextVotingDate,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      deservepageId: deservepageId ?? this.deservepageId,
      status: status ?? this.status,
      isPremium: isPremium ?? this.isPremium,
      averageScore: averageScore ?? this.averageScore,
      totalVotes: totalVotes ?? this.totalVotes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      nextVotingDate: nextVotingDate ?? this.nextVotingDate,
    );
  }

  // Onaylı mı kontrolü
  bool get isApproved => status == UserStatus.approved;

  // Beklemede mi kontrolü
  bool get isPending => status == UserStatus.pending;

  // Tekrar deneyebilir mi kontrolü
  bool get canRetryVoting {
    if (nextVotingDate == null) return true;
    return DateTime.now().isAfter(nextVotingDate!);
  }

  // Yeterli oy var mı (Leaderboard için)
  bool get hasEnoughVotes => (totalVotes ?? 0) >= 50;

  // Yeterli puan var mı (Leaderboard için)
  bool get hasEnoughScore => (averageScore ?? 0) >= 7.5;

  // Leaderboard'a girebilir mi
  bool get canJoinLeaderboard =>
      isApproved && isPremium && hasEnoughVotes && hasEnoughScore;
}

// ============================================
// User Status Enum
// ============================================
enum UserStatus {
  unapproved,   // ❌ Onaysız
  pending,      // 🟡 Beklemede
  approved,     // ✅ Onaylı
  rejected,     // ⏳ Reddedildi (30 gün bekleyecek)
}

extension UserStatusExtension on UserStatus {
  String get displayName {
    switch (this) {
      case UserStatus.unapproved:
        return 'Onaysız';
      case UserStatus.pending:
        return 'Beklemede';
      case UserStatus.approved:
        return 'Onaylı';
      case UserStatus.rejected:
        return 'Reddedildi';
    }
  }

  String get emoji {
    switch (this) {
      case UserStatus.unapproved:
        return '❌';
      case UserStatus.pending:
        return '🟡';
      case UserStatus.approved:
        return '✅';
      case UserStatus.rejected:
        return '⏳';
    }
  }
}

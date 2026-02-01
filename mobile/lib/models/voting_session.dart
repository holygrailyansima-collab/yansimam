// ============================================
// File: lib/models/voting_session.dart
// Voting Session Model - Oylama Oturumu Veri Modeli
// ============================================

class VotingSession {
  final String id;
  final String userId;
  final String votingLink;
  final String qrCodeUrl;
  final DateTime startTime;
  final DateTime endTime;
  final VotingStatus status;
  final int totalVotes;
  final double? approvalRate;
  final double? averageScore;
  final Map<String, double>? detailedScores;
  final DateTime createdAt;
  final DateTime? updatedAt;

  VotingSession({
    required this.id,
    required this.userId,
    required this.votingLink,
    required this.qrCodeUrl,
    required this.startTime,
    required this.endTime,
    required this.status,
    this.totalVotes = 0,
    this.approvalRate,
    this.averageScore,
    this.detailedScores,
    required this.createdAt,
    this.updatedAt,
  });

  // JSON'dan VotingSession objesi oluştur
  factory VotingSession.fromJson(Map<String, dynamic> json) {
    return VotingSession(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      votingLink: json['voting_link'] as String,
      qrCodeUrl: json['qr_code_url'] as String,
      startTime: DateTime.parse(json['start_time'] as String),
      endTime: DateTime.parse(json['end_time'] as String),
      status: _parseVotingStatus(json['status'] as String? ?? 'pending'),
      totalVotes: json['total_votes'] as int? ?? 0,
      approvalRate: (json['approval_rate'] as num?)?.toDouble(),
      averageScore: (json['average_score'] as num?)?.toDouble(),
      detailedScores: json['detailed_scores'] != null
          ? Map<String, double>.from(json['detailed_scores'] as Map)
          : null,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  // Helper method to parse voting status
  static VotingStatus _parseVotingStatus(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return VotingStatus.pending;
      case 'active':
        return VotingStatus.active;
      case 'completed':
        return VotingStatus.completed;
      case 'expired':
        return VotingStatus.expired;
      default:
        return VotingStatus.pending;
    }
  }

  // VotingSession objesini JSON'a çevir
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'voting_link': votingLink,
      'qr_code_url': qrCodeUrl,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'status': status.name,
      'total_votes': totalVotes,
      'approval_rate': approvalRate,
      'average_score': averageScore,
      'detailed_scores': detailedScores,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Copy with method
  VotingSession copyWith({
    String? id,
    String? userId,
    String? votingLink,
    String? qrCodeUrl,
    DateTime? startTime,
    DateTime? endTime,
    VotingStatus? status,
    int? totalVotes,
    double? approvalRate,
    double? averageScore,
    Map<String, double>? detailedScores,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VotingSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      votingLink: votingLink ?? this.votingLink,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      totalVotes: totalVotes ?? this.totalVotes,
      approvalRate: approvalRate ?? this.approvalRate,
      averageScore: averageScore ?? this.averageScore,
      detailedScores: detailedScores ?? this.detailedScores,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // Kalan süre (saniye)
  int get remainingSeconds {
    final now = DateTime.now();
    if (now.isAfter(endTime)) return 0;
    return endTime.difference(now).inSeconds;
  }

  // Kalan süre (saat)
  double get remainingHours {
    return remainingSeconds / 3600;
  }

  // Süre doldu mu?
  bool get isExpired => DateTime.now().isAfter(endTime);

  // Aktif mi?
  bool get isActive => status == VotingStatus.active && !isExpired;

  // Onay aldı mı? (%50.01+)
  bool get isApproved => (approvalRate ?? 0) >= 50.01;

  // Minimum oy sayısına ulaştı mı?
  bool get hasMinimumVotes => totalVotes >= 10;

  // Formatlanmış kalan süre (HH:MM:SS)
  String get formattedRemainingTime {
    final duration = Duration(seconds: remainingSeconds);
    final hours = duration.inHours.toString().padLeft(2, '0');
    final minutes = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$hours:$minutes:$seconds';
  }

  @override
  String toString() {
    return 'VotingSession(id: $id, userId: $userId, status: $status, totalVotes: $totalVotes, approvalRate: $approvalRate)';
  }
}

// ============================================
// Voting Status Enum
// ============================================
enum VotingStatus {
  pending,    // 🟡 Beklemede (henüz başlamadı)
  active,     // 🟢 Aktif (süre devam ediyor)
  completed,  // ✅ Tamamlandı (başarılı)
  expired,    // ⏳ Süresi doldu (başarısız)
}

extension VotingStatusExtension on VotingStatus {
  String get displayName {
    switch (this) {
      case VotingStatus.pending:
        return 'Beklemede';
      case VotingStatus.active:
        return 'Aktif';
      case VotingStatus.completed:
        return 'Tamamlandı';
      case VotingStatus.expired:
        return 'Süresi Doldu';
    }
  }

  String get emoji {
    switch (this) {
      case VotingStatus.pending:
        return '🟡';
      case VotingStatus.active:
        return '🟢';
      case VotingStatus.completed:
        return '✅';
      case VotingStatus.expired:
        return '⏳';
    }
  }
}

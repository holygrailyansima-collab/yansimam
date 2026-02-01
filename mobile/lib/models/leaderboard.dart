import 'package:equatable/equatable.dart';

/// Leaderboard Entry Model
/// Represents a single user's leaderboard entry with score and ranking
class LeaderboardEntry extends Equatable {
  final String userId;
  final String fullName;
  final String username;
  final String? avatarUrl;
  final String deservepageId;
  final double averageScore;
  final int totalVotes;
  final double leaderboardScore;
  final int rank;
  final DateTime lastUpdated;
  
  // Detailed scores (5 dimensions)
  final double? honesty;
  final double? dependability;
  final double? sociability;
  final double? workEthic;
  final double? discipline;

  const LeaderboardEntry({
    required this.userId,
    required this.fullName,
    required this.username,
    this.avatarUrl,
    required this.deservepageId,
    required this.averageScore,
    required this.totalVotes,
    required this.leaderboardScore,
    required this.rank,
    required this.lastUpdated,
    this.honesty,
    this.dependability,
    this.sociability,
    this.workEthic,
    this.discipline,
  });

  /// Calculate leaderboard score
  /// Formula: (averageScore × 0.7) + (totalVotes / 1000 × 0.3)
  static double calculateScore(double averageScore, int totalVotes) {
    final scoreWeight = averageScore * 0.7;
    final votesWeight = (totalVotes / 1000.0) * 0.3;
    return scoreWeight + votesWeight;
  }

  /// Check if user meets leaderboard requirements
  static bool meetsRequirements({
    required bool isApproved,
    required bool isPremium,
    required int totalVotes,
    required double averageScore,
  }) {
    return isApproved && 
           isPremium && 
           totalVotes >= 50 && 
           averageScore >= 7.5;
  }

  /// Create LeaderboardEntry from Supabase JSON
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      userId: json['user_id'] as String,
      fullName: json['full_name'] as String,
      username: json['username'] as String,
      avatarUrl: json['avatar_url'] as String?,
      deservepageId: json['deservepage_id'] as String,
      averageScore: (json['average_score'] as num).toDouble(),
      totalVotes: json['total_votes'] as int,
      leaderboardScore: (json['leaderboard_score'] as num).toDouble(),
      rank: json['rank'] as int,
      lastUpdated: DateTime.parse(json['last_updated'] as String),
      honesty: (json['honesty'] as num?)?.toDouble(),
      dependability: (json['dependability'] as num?)?.toDouble(),
      sociability: (json['sociability'] as num?)?.toDouble(),
      workEthic: (json['work_ethic'] as num?)?.toDouble(),
      discipline: (json['discipline'] as num?)?.toDouble(),
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'full_name': fullName,
      'username': username,
      'avatar_url': avatarUrl,
      'deservepage_id': deservepageId,
      'average_score': averageScore,
      'total_votes': totalVotes,
      'leaderboard_score': leaderboardScore,
      'rank': rank,
      'last_updated': lastUpdated.toIso8601String(),
      'honesty': honesty,
      'dependability': dependability,
      'sociability': sociability,
      'work_ethic': workEthic,
      'discipline': discipline,
    };
  }

  /// Copy with modified fields
  LeaderboardEntry copyWith({
    String? userId,
    String? fullName,
    String? username,
    String? avatarUrl,
    String? deservepageId,
    double? averageScore,
    int? totalVotes,
    double? leaderboardScore,
    int? rank,
    DateTime? lastUpdated,
    double? honesty,
    double? dependability,
    double? sociability,
    double? workEthic,
    double? discipline,
  }) {
    return LeaderboardEntry(
      userId: userId ?? this.userId,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      deservepageId: deservepageId ?? this.deservepageId,
      averageScore: averageScore ?? this.averageScore,
      totalVotes: totalVotes ?? this.totalVotes,
      leaderboardScore: leaderboardScore ?? this.leaderboardScore,
      rank: rank ?? this.rank,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      honesty: honesty ?? this.honesty,
      dependability: dependability ?? this.dependability,
      sociability: sociability ?? this.sociability,
      workEthic: workEthic ?? this.workEthic,
      discipline: discipline ?? this.discipline,
    );
  }

  /// Get medal emoji for top 3
  String get medalEmoji {
    switch (rank) {
      case 1:
        return '🥇';
      case 2:
        return '🥈';
      case 3:
        return '🥉';
      default:
        return '';
    }
  }

  /// Check if user is in top 3
  bool get isTopThree => rank <= 3;

  /// Check if user is in top 10
  bool get isTopTen => rank <= 10;

  /// Check if user is in top 100
  bool get isTopHundred => rank <= 100;

  /// Get formatted average score
  String get formattedScore => averageScore.toStringAsFixed(1);

  /// Get score badge color
  String get scoreBadgeColor {
    if (averageScore >= 9.0) return '#FFD700'; // Gold
    if (averageScore >= 8.5) return '#C0C0C0'; // Silver
    if (averageScore >= 8.0) return '#CD7F32'; // Bronze
    if (averageScore >= 7.5) return '#4CAF50'; // Green
    return '#9E9E9E'; // Grey
  }

  /// Get detailed scores map
  Map<String, double?> get detailedScores {
    return {
      'Dürüstlük': honesty,
      'Güvenilirlik': dependability,
      'Sosyallik': sociability,
      'Çalışma Azmi': workEthic,
      'Öz Disiplin': discipline,
    };
  }

  @override
  List<Object?> get props => [
        userId,
        fullName,
        username,
        avatarUrl,
        deservepageId,
        averageScore,
        totalVotes,
        leaderboardScore,
        rank,
        lastUpdated,
        honesty,
        dependability,
        sociability,
        workEthic,
        discipline,
      ];

  @override
  String toString() {
    return 'LeaderboardEntry(rank: #$rank, user: $username, score: $formattedScore/10)';
  }
}

/// Leaderboard Period Enum
enum LeaderboardPeriod {
  weekly,
  monthly,
  allTime,
}

extension LeaderboardPeriodExtension on LeaderboardPeriod {
  /// Get Turkish name
  String get displayName {
    switch (this) {
      case LeaderboardPeriod.weekly:
        return 'Bu Hafta';
      case LeaderboardPeriod.monthly:
        return 'Bu Ay';
      case LeaderboardPeriod.allTime:
        return 'Tüm Zamanlar';
    }
  }

  /// Get emoji
  String get emoji {
    switch (this) {
      case LeaderboardPeriod.weekly:
        return '📅';
      case LeaderboardPeriod.monthly:
        return '📆';
      case LeaderboardPeriod.allTime:
        return '🏆';
    }
  }
}

/// Leaderboard Filters
class LeaderboardFilters {
  final LeaderboardPeriod period;
  final int page;
  final int pageSize;
  final String? searchQuery;

  const LeaderboardFilters({
    this.period = LeaderboardPeriod.allTime,
    this.page = 1,
    this.pageSize = 50,
    this.searchQuery,
  });

  /// Copy with modified fields
  LeaderboardFilters copyWith({
    LeaderboardPeriod? period,
    int? page,
    int? pageSize,
    String? searchQuery,
  }) {
    return LeaderboardFilters(
      period: period ?? this.period,
      page: page ?? this.page,
      pageSize: pageSize ?? this.pageSize,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }

  /// Get offset for pagination
  int get offset => (page - 1) * pageSize;

  /// Convert to query parameters
  Map<String, dynamic> toQueryParams() {
    return {
      'period': period.name,
      'limit': pageSize,
      'offset': offset,
      if (searchQuery != null && searchQuery!.isNotEmpty) 'search': searchQuery,
    };
  }
}

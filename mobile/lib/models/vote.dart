import 'package:equatable/equatable.dart';

/// Vote data model
/// Represents a single vote cast for a user
class Vote extends Equatable {
  final String id;
  final String votingSessionId;
  final String voterId; // Device fingerprint or IP hash
  final DateTime createdAt;
  
  // Vote scores (0-10 scale)
  final double honesty; // Dürüstlük
  final double dependability; // Güvenilirlik
  final double sociability; // Sosyallik
  final double workEthic; // Çalışma Azmi
  final double discipline; // Öz Disiplin
  
  // Metadata
  final String? ipAddress;
  final String? deviceFingerprint;
  final String? userAgent;

  const Vote({
    required this.id,
    required this.votingSessionId,
    required this.voterId,
    required this.createdAt,
    required this.honesty,
    required this.dependability,
    required this.sociability,
    required this.workEthic,
    required this.discipline,
    this.ipAddress,
    this.deviceFingerprint,
    this.userAgent,
  });

  /// Calculate average score from all 5 dimensions
  double get averageScore {
    return (honesty + dependability + sociability + workEthic + discipline) / 5.0;
  }

  /// Check if all scores are valid (0-10 range)
  bool get isValid {
    return honesty >= 0 && honesty <= 10 &&
        dependability >= 0 && dependability <= 10 &&
        sociability >= 0 && sociability <= 10 &&
        workEthic >= 0 && workEthic <= 10 &&
        discipline >= 0 && discipline <= 10;
  }

  /// Create Vote from Supabase JSON
  factory Vote.fromJson(Map<String, dynamic> json) {
    return Vote(
      id: json['id'] as String,
      votingSessionId: json['voting_session_id'] as String,
      voterId: json['voter_id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      honesty: (json['honesty'] as num).toDouble(),
      dependability: (json['dependability'] as num).toDouble(),
      sociability: (json['sociability'] as num).toDouble(),
      workEthic: (json['work_ethic'] as num).toDouble(),
      discipline: (json['discipline'] as num).toDouble(),
      ipAddress: json['ip_address'] as String?,
      deviceFingerprint: json['device_fingerprint'] as String?,
      userAgent: json['user_agent'] as String?,
    );
  }

  /// Convert Vote to Supabase JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'voting_session_id': votingSessionId,
      'voter_id': voterId,
      'created_at': createdAt.toIso8601String(),
      'honesty': honesty,
      'dependability': dependability,
      'sociability': sociability,
      'work_ethic': workEthic,
      'discipline': discipline,
      'ip_address': ipAddress,
      'device_fingerprint': deviceFingerprint,
      'user_agent': userAgent,
    };
  }

  /// Create Vote without metadata (for insert)
  Map<String, dynamic> toInsertJson() {
    return {
      'voting_session_id': votingSessionId,
      'voter_id': voterId,
      'honesty': honesty,
      'dependability': dependability,
      'sociability': sociability,
      'work_ethic': workEthic,
      'discipline': discipline,
      'ip_address': ipAddress,
      'device_fingerprint': deviceFingerprint,
      'user_agent': userAgent,
    };
  }

  /// Create copy with modified fields
  Vote copyWith({
    String? id,
    String? votingSessionId,
    String? voterId,
    DateTime? createdAt,
    double? honesty,
    double? dependability,
    double? sociability,
    double? workEthic,
    double? discipline,
    String? ipAddress,
    String? deviceFingerprint,
    String? userAgent,
  }) {
    return Vote(
      id: id ?? this.id,
      votingSessionId: votingSessionId ?? this.votingSessionId,
      voterId: voterId ?? this.voterId,
      createdAt: createdAt ?? this.createdAt,
      honesty: honesty ?? this.honesty,
      dependability: dependability ?? this.dependability,
      sociability: sociability ?? this.sociability,
      workEthic: workEthic ?? this.workEthic,
      discipline: discipline ?? this.discipline,
      ipAddress: ipAddress ?? this.ipAddress,
      deviceFingerprint: deviceFingerprint ?? this.deviceFingerprint,
      userAgent: userAgent ?? this.userAgent,
    );
  }

  /// Get score breakdown as formatted string
  String getScoreBreakdown() {
    return '''
Dürüstlük: ${honesty.toStringAsFixed(1)}
Güvenilirlik: ${dependability.toStringAsFixed(1)}
Sosyallik: ${sociability.toStringAsFixed(1)}
Çalışma Azmi: ${workEthic.toStringAsFixed(1)}
Öz Disiplin: ${discipline.toStringAsFixed(1)}
Ortalama: ${averageScore.toStringAsFixed(2)}
''';
  }

  /// Get score for specific dimension
  double getScore(ScoreDimension dimension) {
    switch (dimension) {
      case ScoreDimension.honesty:
        return honesty;
      case ScoreDimension.dependability:
        return dependability;
      case ScoreDimension.sociability:
        return sociability;
      case ScoreDimension.workEthic:
        return workEthic;
      case ScoreDimension.discipline:
        return discipline;
    }
  }

  @override
  List<Object?> get props => [
        id,
        votingSessionId,
        voterId,
        createdAt,
        honesty,
        dependability,
        sociability,
        workEthic,
        discipline,
        ipAddress,
        deviceFingerprint,
        userAgent,
      ];

  @override
  String toString() {
    return 'Vote(id: $id, session: $votingSessionId, avg: ${averageScore.toStringAsFixed(2)})';
  }
}

/// Score dimensions enum
enum ScoreDimension {
  honesty,
  dependability,
  sociability,
  workEthic,
  discipline,
}

/// Extension for ScoreDimension
extension ScoreDimensionExtension on ScoreDimension {
  /// Get Turkish name
  String get displayName {
    switch (this) {
      case ScoreDimension.honesty:
        return 'Dürüstlük';
      case ScoreDimension.dependability:
        return 'Güvenilirlik';
      case ScoreDimension.sociability:
        return 'Sosyallik';
      case ScoreDimension.workEthic:
        return 'Çalışma Azmi';
      case ScoreDimension.discipline:
        return 'Öz Disiplin';
    }
  }

  /// Get emoji icon
  String get emoji {
    switch (this) {
      case ScoreDimension.honesty:
        return '🤝';
      case ScoreDimension.dependability:
        return '🛡️';
      case ScoreDimension.sociability:
        return '🎭';
      case ScoreDimension.workEthic:
        return '💪';
      case ScoreDimension.discipline:
        return '🎯';
    }
  }

  /// Get description
  String get description {
    switch (this) {
      case ScoreDimension.honesty:
        return 'Açıklık, saydamlık ve dürüstlük seviyesi';
      case ScoreDimension.dependability:
        return 'Güvenilirlik, verilen sözü tutma';
      case ScoreDimension.sociability:
        return 'İletişim, sosyalleşme ve uyum';
      case ScoreDimension.workEthic:
        return 'Çalışma azmi, üretkenlik ve gayret';
      case ScoreDimension.discipline:
        return 'Öz disiplin, düzen ve sistemlilik';
    }
  }
}

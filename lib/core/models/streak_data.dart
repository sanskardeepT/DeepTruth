class StreakData {
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final int totalChecks;
  final int fakesCaught;
  final int freezesUsedThisMonth;
  final DateTime? lastFreezeDate;

  const StreakData({
    this.currentStreak        = 0,
    this.longestStreak        = 0,
    this.lastActiveDate,
    this.totalChecks          = 0,
    this.fakesCaught          = 0,
    this.freezesUsedThisMonth = 0,
    this.lastFreezeDate,
  });

  String get rank {
    if (currentStreak >= 365) return 'Truth Sentinel';
    if (currentStreak >= 180) return 'Fact Guardian';
    if (currentStreak >= 90)  return 'Analyst';
    if (currentStreak >= 30)  return 'Reporter';
    if (currentStreak >= 7)   return 'Observer';
    return 'Newcomer';
  }

  String get rankEmoji {
    if (currentStreak >= 365) return '🌟';
    if (currentStreak >= 180) return '🛡️';
    if (currentStreak >= 90)  return '⚖️';
    if (currentStreak >= 30)  return '📰';
    if (currentStreak >= 7)   return '🔍';
    return '🌱';
  }

  int get nextRankThreshold {
    if (currentStreak < 7)   return 7;
    if (currentStreak < 30)  return 30;
    if (currentStreak < 90)  return 90;
    if (currentStreak < 180) return 180;
    if (currentStreak < 365) return 365;
    return currentStreak;
  }

  bool get canFreeze => freezesUsedThisMonth < 1;

  bool get isStreakAtRisk {
    if (lastActiveDate == null) return false;
    final diff = DateTime.now().difference(lastActiveDate!);
    return diff.inHours >= 20;
  }

  Map<String, dynamic> toJson() => {
    'currentStreak':        currentStreak,
    'longestStreak':        longestStreak,
    'lastActiveDate':       lastActiveDate?.toIso8601String(),
    'totalChecks':          totalChecks,
    'fakesCaught':          fakesCaught,
    'freezesUsedThisMonth': freezesUsedThisMonth,
    'lastFreezeDate':       lastFreezeDate?.toIso8601String(),
  };

  factory StreakData.fromJson(Map<String, dynamic> json) {
    return StreakData(
      currentStreak:        (json['currentStreak']        as num?)?.toInt() ?? 0,
      longestStreak:        (json['longestStreak']        as num?)?.toInt() ?? 0,
      lastActiveDate:       DateTime.tryParse(json['lastActiveDate']?.toString() ?? ''),
      totalChecks:          (json['totalChecks']          as num?)?.toInt() ?? 0,
      fakesCaught:          (json['fakesCaught']          as num?)?.toInt() ?? 0,
      freezesUsedThisMonth: (json['freezesUsedThisMonth'] as num?)?.toInt() ?? 0,
      lastFreezeDate:       DateTime.tryParse(json['lastFreezeDate']?.toString() ?? ''),
    );
  }

  StreakData copyWith({
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    int? totalChecks,
    int? fakesCaught,
    int? freezesUsedThisMonth,
    DateTime? lastFreezeDate,
  }) {
    return StreakData(
      currentStreak:        currentStreak        ?? this.currentStreak,
      longestStreak:        longestStreak        ?? this.longestStreak,
      lastActiveDate:       lastActiveDate       ?? this.lastActiveDate,
      totalChecks:          totalChecks          ?? this.totalChecks,
      fakesCaught:          fakesCaught          ?? this.fakesCaught,
      freezesUsedThisMonth: freezesUsedThisMonth ?? this.freezesUsedThisMonth,
      lastFreezeDate:       lastFreezeDate       ?? this.lastFreezeDate,
    );
  }
}

class UserProfile {
  final String anonymousId;
  final String country;
  final String language;
  final String? ageGroup; // inferred from usage patterns
  final List<String> topInterests;
  final double avgSessionMinutes;
  final List<int> usageHours; // hours of day when app is used
  final Map<String, int> categoryCheckCounts;

  const UserProfile({
    required this.anonymousId,
    this.country            = 'Global',
    this.language           = 'en',
    this.ageGroup,
    this.topInterests       = const [],
    this.avgSessionMinutes  = 0.0,
    this.usageHours         = const [],
    this.categoryCheckCounts= const {},
  });

  Map<String, dynamic> toJson() => {
    'anonymousId':         anonymousId,
    'country':             country,
    'language':            language,
    'ageGroup':            ageGroup,
    'topInterests':        topInterests,
    'avgSessionMinutes':   avgSessionMinutes,
    'usageHours':          usageHours,
    'categoryCheckCounts': categoryCheckCounts,
  };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final counts = json['categoryCheckCounts'] as Map<String, dynamic>? ?? {};
    return UserProfile(
      anonymousId:         json['anonymousId']        as String? ?? '',
      country:             json['country']            as String? ?? 'Global',
      language:            json['language']           as String? ?? 'en',
      ageGroup:            json['ageGroup']           as String?,
      topInterests:        List<String>.from(json['topInterests'] ?? []),
      avgSessionMinutes:   (json['avgSessionMinutes'] as num?)?.toDouble() ?? 0.0,
      usageHours:          List<int>.from(json['usageHours'] ?? []),
      categoryCheckCounts: counts.map((k, v) => MapEntry(k, (v as num).toInt())),
    );
  }

  UserProfile copyWith({
    String? country,
    String? language,
    String? ageGroup,
    List<String>? topInterests,
    double? avgSessionMinutes,
    List<int>? usageHours,
    Map<String, int>? categoryCheckCounts,
  }) {
    return UserProfile(
      anonymousId:         anonymousId,
      country:             country             ?? this.country,
      language:            language            ?? this.language,
      ageGroup:            ageGroup            ?? this.ageGroup,
      topInterests:        topInterests        ?? this.topInterests,
      avgSessionMinutes:   avgSessionMinutes   ?? this.avgSessionMinutes,
      usageHours:          usageHours          ?? this.usageHours,
      categoryCheckCounts: categoryCheckCounts ?? this.categoryCheckCounts,
    );
  }
}

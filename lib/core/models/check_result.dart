class CheckResult {
  final String originalContent;
  final int truthScore;
  final String verdict;
  final String explanation;
  final String? missingContext;
  final List<String> sources;
  final List<String> manipulationTactics;
  final int manipulationScore;
  final String contentType;
  final DateTime analyzedAt;
  final String reportId;

  const CheckResult({
    required this.originalContent,
    required this.truthScore,
    required this.verdict,
    required this.explanation,
    this.missingContext,
    this.sources = const [],
    this.manipulationTactics = const [],
    required this.manipulationScore,
    required this.contentType,
    required this.analyzedAt,
    required this.reportId,
  });

  factory CheckResult.fromJson(Map<String, dynamic> json) {
    return CheckResult(
      originalContent:     json['originalContent']    as String? ?? '',
      truthScore:          (json['truthScore']        as num?)?.toInt() ?? 50,
      verdict:             json['verdict']            as String? ?? 'UNVERIFIED',
      explanation:         json['explanation']        as String? ?? 'Analysis unavailable.',
      missingContext:      json['missingContext']     as String?,
      sources:             (json['sources'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? const [],
      manipulationTactics: (json['manipulationTactics'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? const [],
      manipulationScore:   (json['manipulationScore'] as num?)?.toInt() ?? 0,
      contentType:         json['contentType']        as String? ?? 'unknown',
      analyzedAt:          DateTime.tryParse(json['analyzedAt']?.toString() ?? '') ?? DateTime.now(),
      reportId:            json['reportId']           as String? ?? 'LIQ-UNKNOWN',
    );
  }

  Map<String, dynamic> toJson() => {
    'originalContent':    originalContent,
    'truthScore':         truthScore,
    'verdict':            verdict,
    'explanation':        explanation,
    'missingContext':     missingContext,
    'sources':            sources,
    'manipulationTactics':manipulationTactics,
    'manipulationScore':  manipulationScore,
    'contentType':        contentType,
    'analyzedAt':         analyzedAt.toIso8601String(),
    'reportId':           reportId,
  };

  String get verdictEmoji {
    switch (verdict) {
      case 'TRUE':       return '✅';
      case 'FALSE':      return '❌';
      case 'MISLEADING': return '⚠️';
      default:           return '❓';
    }
  }
}

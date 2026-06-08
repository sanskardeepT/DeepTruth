class CheckResult {
  final String originalContent;
  final int truthScore;
  final String verdict;
  final String explanation;
  final String? missingContext;
  final List<String> sources;
  final List<String> manipulationTactics;
  final List<String> logicalFallacies;
  final int manipulationScore;
  final String contentType;
  final DateTime analyzedAt;
  final String reportId;
  final String? imagePath;

  const CheckResult({
    required this.originalContent,
    required this.truthScore,
    required this.verdict,
    required this.explanation,
    this.missingContext,
    this.sources = const [],
    this.manipulationTactics = const [],
    this.logicalFallacies = const [],
    required this.manipulationScore,
    required this.contentType,
    required this.analyzedAt,
    required this.reportId,
    this.imagePath,
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
      logicalFallacies:    (json['logicalFallacies'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? const [],
      manipulationScore:   (json['manipulationScore'] as num?)?.toInt() ?? 0,
      contentType:         json['contentType']        as String? ?? 'unknown',
      analyzedAt:          DateTime.tryParse(json['analyzedAt']?.toString() ?? '') ?? DateTime.now(),
      reportId:            json['reportId']           as String? ?? 'DT-UNKNOWN',
      imagePath:           json['imagePath']          as String?,
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
    'logicalFallacies':   logicalFallacies,
    'manipulationScore':  manipulationScore,
    'contentType':        contentType,
    'analyzedAt':         analyzedAt.toIso8601String(),
    'reportId':           reportId,
    'imagePath':          imagePath,
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

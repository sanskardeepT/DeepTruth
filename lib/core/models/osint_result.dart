enum OsintQueryType { email, phone, username, ip, website, image }

class OsintFinding {
  final String label;
  final String value;
  final String? sourceUrl;

  const OsintFinding({
    required this.label,
    required this.value,
    this.sourceUrl,
  });
}

class OsintResult {
  final OsintQueryType queryType;
  final String query;
  final List<OsintFinding> findings;
  final List<String> sources;
  final String riskLevel; // 'low' | 'medium' | 'high' | 'unknown'
  final String? error;
  final DateTime analyzedAt;

  const OsintResult({
    required this.queryType,
    required this.query,
    required this.findings,
    this.sources = const [],
    required this.riskLevel,
    this.error,
    required this.analyzedAt,
  });

  bool get hasError => error != null;

  factory OsintResult.error(OsintQueryType type, String query, String message) {
    return OsintResult(
      queryType:  type,
      query:      query,
      findings:   [],
      riskLevel:  'unknown',
      error:      message,
      analyzedAt: DateTime.now(),
    );
  }
}

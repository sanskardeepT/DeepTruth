import 'trust_verification_models.dart';

class CheckResult {
  final String originalContent;
  final int truthScore;
  final String verdict;
  final String explanation;
  final String? summary;
  final String? missingContext;
  final List<String> sources;
  final List<String> manipulationTactics;
  final List<String> logicalFallacies;
  final int manipulationScore;
  final String contentType;
  final DateTime analyzedAt;
  final String reportId;
  final String? imagePath;
  final String? sha256Hash;
  final DateTime? firstSeen;
  final DateTime? lastSeen;
  final int? scanCount;

  // New Trust OS Modules
  final C2PAResult? c2pa;
  final ProvenanceResult? provenance;
  final DeepfakeResult? deepfake;
  final ReputationResult? reputation;
  final ConsensusScores? consensus;
  final TrustGraph? trustGraph;

  const CheckResult({
    required this.originalContent,
    required this.truthScore,
    required this.verdict,
    required this.explanation,
    this.summary,
    this.missingContext,
    this.sources = const [],
    this.manipulationTactics = const [],
    this.logicalFallacies = const [],
    required this.manipulationScore,
    required this.contentType,
    required this.analyzedAt,
    required this.reportId,
    this.imagePath,
    this.sha256Hash,
    this.firstSeen,
    this.lastSeen,
    this.scanCount,
    this.c2pa,
    this.provenance,
    this.deepfake,
    this.reputation,
    this.consensus,
    this.trustGraph,
  });

  factory CheckResult.fromJson(Map<String, dynamic> json) {
    // Parse nested models
    final c2paObj = json['c2pa'] != null ? C2PAResult.fromJson(Map<String, dynamic>.from(json['c2pa'] as Map)) : null;
    final provObj = json['provenance'] != null ? ProvenanceResult.fromJson(Map<String, dynamic>.from(json['provenance'] as Map)) : null;
    final dfObj   = json['deepfake'] != null ? DeepfakeResult.fromJson(Map<String, dynamic>.from(json['deepfake'] as Map)) : null;
    final repObj  = json['reputation'] != null ? ReputationResult.fromJson(Map<String, dynamic>.from(json['reputation'] as Map)) : null;
    var conObj  = json['consensus'] != null ? ConsensusScores.fromJson(Map<String, dynamic>.from(json['consensus'] as Map)) : null;
    final tgObj   = json['trustGraph'] != null ? TrustGraph.fromJson(Map<String, dynamic>.from(json['trustGraph'] as Map)) : null;
    final finalTruthScore = conObj?.trustScore ?? (json['truthScore'] as num?)?.toInt() ?? 50;
    final finalVerdict    = conObj?.verdict ?? json['verdict'] as String? ?? 'UNVERIFIED';
    final finalExplanation= conObj?.justification ?? json['explanation'] as String? ?? 'Analysis unavailable.';
    final finalManipScore = conObj?.manipulationScore ?? (json['manipulationScore'] as num?)?.toInt() ?? 0;

    if (conObj == null) {
      final isText = json['contentType'] == 'text' || json['contentType'] == 'unknown';
      conObj = ConsensusScores(
        authenticityScore: isText ? 0 : 50,
        trustScore: finalTruthScore,
        manipulationScore: finalManipScore,
        riskScore: (100 - finalTruthScore),
        confidenceScore: 90,
        verdict: finalVerdict,
        justification: finalExplanation,
        adjustments: isText
            ? [
                {
                  'category': 'factcheck',
                  'impact': finalTruthScore,
                  'factor': 'Fact-checking citation verification index: $finalTruthScore/100',
                }
              ]
            : [
                {
                  'category': 'reputation',
                  'impact': (finalTruthScore * 0.5).toInt(),
                  'factor': 'Source domain reputation matching: ${(finalTruthScore * 0.5).toInt()}/50',
                },
                {
                  'category': 'forensics',
                  'impact': (finalTruthScore * 0.5).toInt(),
                  'factor': 'Media forensics structural assessment: ${(finalTruthScore * 0.5).toInt()}/50',
                }
              ],
      );
    }

    return CheckResult(
      originalContent:     json['originalContent']    as String? ?? '',
      truthScore:          finalTruthScore,
      verdict:             finalVerdict,
      explanation:         finalExplanation,
      summary:             json['summary']            as String?,
      missingContext:      json['missingContext']     as String?,
      sources:             (json['sources'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? const [],
      manipulationTactics: (json['manipulationTactics'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? const [],
      logicalFallacies:    (json['logicalFallacies'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? const [],
      manipulationScore:   finalManipScore,
      contentType:         json['contentType']        as String? ?? 'unknown',
      analyzedAt:          DateTime.tryParse(json['analyzedAt']?.toString() ?? '') ?? DateTime.now(),
      reportId:            json['reportId']           as String? ?? 'DT-UNKNOWN',
      imagePath:           json['imagePath']          as String?,
      sha256Hash:          json['sha256Hash']         as String?,
      firstSeen:           json['firstSeen'] != null ? DateTime.tryParse(json['firstSeen'].toString()) : null,
      lastSeen:            json['lastSeen'] != null ? DateTime.tryParse(json['lastSeen'].toString()) : null,
      scanCount:           json['scanCount'] != null ? (json['scanCount'] as num).toInt() : (json['reuseCount'] != null ? (json['reuseCount'] as num).toInt() : null),
      c2pa:                c2paObj,
      provenance:          provObj,
      deepfake:            dfObj,
      reputation:          repObj,
      consensus:           conObj,
      trustGraph:          tgObj,
    );
  }

  Map<String, dynamic> toJson() => {
    'originalContent':    originalContent,
    'truthScore':         truthScore,
    'verdict':            verdict,
    'explanation':        explanation,
    'summary':            summary,
    'missingContext':     missingContext,
    'sources':            sources,
    'manipulationTactics':manipulationTactics,
    'logicalFallacies':   logicalFallacies,
    'manipulationScore':  manipulationScore,
    'contentType':        contentType,
    'analyzedAt':         analyzedAt.toIso8601String(),
    'reportId':           reportId,
    'imagePath':          imagePath,
    'sha256Hash':         sha256Hash,
    'firstSeen':          firstSeen?.toIso8601String(),
    'lastSeen':           lastSeen?.toIso8601String(),
    'scanCount':          scanCount,
    'c2pa':                c2pa?.toJson(),
    'provenance':          provenance?.toJson(),
    'deepfake':            deepfake?.toJson(),
    'reputation':          reputation?.toJson(),
    'consensus':           consensus?.toJson(),
    'trustGraph':          trustGraph?.toJson(),
  };

  CheckResult copyWith({
    String? originalContent,
    int? truthScore,
    String? verdict,
    String? explanation,
    String? summary,
    String? missingContext,
    List<String>? sources,
    List<String>? manipulationTactics,
    List<String>? logicalFallacies,
    int? manipulationScore,
    String? contentType,
    DateTime? analyzedAt,
    String? reportId,
    String? imagePath,
    String? sha256Hash,
    DateTime? firstSeen,
    DateTime? lastSeen,
    int? scanCount,
    C2PAResult? c2pa,
    ProvenanceResult? provenance,
    DeepfakeResult? deepfake,
    ReputationResult? reputation,
    ConsensusScores? consensus,
    TrustGraph? trustGraph,
  }) {
    return CheckResult(
      originalContent: originalContent ?? this.originalContent,
      truthScore: truthScore ?? this.truthScore,
      verdict: verdict ?? this.verdict,
      explanation: explanation ?? this.explanation,
      summary: summary ?? this.summary,
      missingContext: missingContext ?? this.missingContext,
      sources: sources ?? this.sources,
      manipulationTactics: manipulationTactics ?? this.manipulationTactics,
      logicalFallacies: logicalFallacies ?? this.logicalFallacies,
      manipulationScore: manipulationScore ?? this.manipulationScore,
      contentType: contentType ?? this.contentType,
      analyzedAt: analyzedAt ?? this.analyzedAt,
      reportId: reportId ?? this.reportId,
      imagePath: imagePath ?? this.imagePath,
      sha256Hash: sha256Hash ?? this.sha256Hash,
      firstSeen: firstSeen ?? this.firstSeen,
      lastSeen: lastSeen ?? this.lastSeen,
      scanCount: scanCount ?? this.scanCount,
      c2pa: c2pa ?? this.c2pa,
      provenance: provenance ?? this.provenance,
      deepfake: deepfake ?? this.deepfake,
      reputation: reputation ?? this.reputation,
      consensus: consensus ?? this.consensus,
      trustGraph: trustGraph ?? this.trustGraph,
    );
  }

  String get verdictEmoji {
    switch (verdict) {
      case 'TRUE':       return '✅';
      case 'FALSE':      return '❌';
      case 'MISLEADING': return '⚠️';
      default:           return '❓';
    }
  }
}

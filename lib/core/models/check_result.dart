import 'trust_verification_models.dart';

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
    this.missingContext,
    this.sources = const [],
    this.manipulationTactics = const [],
    this.logicalFallacies = const [],
    required this.manipulationScore,
    required this.contentType,
    required this.analyzedAt,
    required this.reportId,
    this.imagePath,
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
    final conObj  = json['consensus'] != null ? ConsensusScores.fromJson(Map<String, dynamic>.from(json['consensus'] as Map)) : null;
    final tgObj   = json['trustGraph'] != null ? TrustGraph.fromJson(Map<String, dynamic>.from(json['trustGraph'] as Map)) : null;

    // Backward-compatibility fallbacks
    final finalTruthScore = conObj?.trustScore ?? (json['truthScore'] as num?)?.toInt() ?? 50;
    final finalVerdict    = conObj?.verdict ?? json['verdict'] as String? ?? 'UNVERIFIED';
    final finalExplanation= conObj?.justification ?? json['explanation'] as String? ?? 'Analysis unavailable.';
    final finalManipScore = conObj?.manipulationScore ?? (json['manipulationScore'] as num?)?.toInt() ?? 0;

    return CheckResult(
      originalContent:     json['originalContent']    as String? ?? '',
      truthScore:          finalTruthScore,
      verdict:             finalVerdict,
      explanation:         finalExplanation,
      missingContext:      json['missingContext']     as String?,
      sources:             (json['sources'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? const [],
      manipulationTactics: (json['manipulationTactics'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? const [],
      logicalFallacies:    (json['logicalFallacies'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? const [],
      manipulationScore:   finalManipScore,
      contentType:         json['contentType']        as String? ?? 'unknown',
      analyzedAt:          DateTime.tryParse(json['analyzedAt']?.toString() ?? '') ?? DateTime.now(),
      reportId:            json['reportId']           as String? ?? 'DT-UNKNOWN',
      imagePath:           json['imagePath']          as String?,
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
    'missingContext':     missingContext,
    'sources':            sources,
    'manipulationTactics':manipulationTactics,
    'logicalFallacies':   logicalFallacies,
    'manipulationScore':  manipulationScore,
    'contentType':        contentType,
    'analyzedAt':         analyzedAt.toIso8601String(),
    'reportId':           reportId,
    'imagePath':          imagePath,
    'c2pa':                c2pa?.toJson(),
    'provenance':          provenance?.toJson(),
    'deepfake':            deepfake?.toJson(),
    'reputation':          reputation?.toJson(),
    'consensus':           consensus?.toJson(),
    'trustGraph':          trustGraph?.toJson(),
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

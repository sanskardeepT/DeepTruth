class C2PAResult {
  final bool hasC2PA;
  final String? creator;
  final String? publisher;
  final String? createdAt;
  final List<String> editedBy;
  final int trustScore;
  final String verificationStatus;

  const C2PAResult({
    required this.hasC2PA,
    this.creator,
    this.publisher,
    this.createdAt,
    this.editedBy = const [],
    required this.trustScore,
    required this.verificationStatus,
  });

  factory C2PAResult.fromJson(Map<String, dynamic> json) {
    return C2PAResult(
      hasC2PA:            json['hasC2PA'] as bool? ?? false,
      creator:            json['creator'] as String?,
      publisher:          json['publisher'] as String?,
      createdAt:          json['createdAt'] as String?,
      editedBy:           (json['editedBy'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? const [],
      trustScore:          (json['trustScore'] as num?)?.toInt() ?? 0,
      verificationStatus: json['verificationStatus'] as String? ?? 'NOT_VERIFIED',
    );
  }

  Map<String, dynamic> toJson() => {
    'hasC2PA':            hasC2PA,
    'creator':            creator,
    'publisher':          publisher,
    'createdAt':          createdAt,
    'editedBy':           editedBy,
    'trustScore':         trustScore,
    'verificationStatus': verificationStatus,
  };
}

class ProvenanceResult {
  final String? firstAppearance;
  final String? sourceDomain;
  final String? creator;
  final int reusedCount;
  final String? earliestDate;
  final Map<String, String> exif;
  final String? gps;
  final String? camera;
  final String? software;

  const ProvenanceResult({
    this.firstAppearance,
    this.sourceDomain,
    this.creator,
    required this.reusedCount,
    this.earliestDate,
    this.exif = const {},
    this.gps,
    this.camera,
    this.software,
  });

  factory ProvenanceResult.fromJson(Map<String, dynamic> json) {
    final exifMap = <String, String>{};
    if (json['exif'] is Map) {
      (json['exif'] as Map).forEach((k, v) {
        exifMap[k.toString()] = v.toString();
      });
    }
    return ProvenanceResult(
      firstAppearance: json['firstAppearance'] as String?,
      sourceDomain:    json['sourceDomain'] as String?,
      creator:         json['creator'] as String?,
      reusedCount:     (json['reusedCount'] as num?)?.toInt() ?? 0,
      earliestDate:    json['earliestDate'] as String?,
      exif:            exifMap,
      gps:             json['gps'] as String?,
      camera:          json['camera'] as String?,
      software:        json['software'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'firstAppearance': firstAppearance,
    'sourceDomain':    sourceDomain,
    'creator':         creator,
    'reusedCount':     reusedCount,
    'earliestDate':    earliestDate,
    'exif':            exif,
    'gps':             gps,
    'camera':          camera,
    'software':        software,
  };
}

class DeepfakeResult {
  final double deepfakeProbability;
  final double confidence;
  final String riskLevel;
  final double imageRisk;
  final double videoRisk;
  final double audioRisk;
  final double multimodalRisk;
  final String analysisNote;

  const DeepfakeResult({
    required this.deepfakeProbability,
    required this.confidence,
    required this.riskLevel,
    this.imageRisk = 0.0,
    this.videoRisk = 0.0,
    this.audioRisk = 0.0,
    this.multimodalRisk = 0.0,
    this.analysisNote = '',
  });

  factory DeepfakeResult.fromJson(Map<String, dynamic> json) {
    return DeepfakeResult(
      deepfakeProbability: (json['deepfakeProbability'] as num?)?.toDouble() ?? 0.0,
      confidence:          (json['confidence'] as num?)?.toDouble() ?? 0.0,
      riskLevel:           json['riskLevel'] as String? ?? 'low',
      imageRisk:           (json['imageRisk'] as num?)?.toDouble() ?? 0.0,
      videoRisk:           (json['videoRisk'] as num?)?.toDouble() ?? 0.0,
      audioRisk:           (json['audioRisk'] as num?)?.toDouble() ?? 0.0,
      multimodalRisk:      (json['multimodalRisk'] as num?)?.toDouble() ?? 0.0,
      analysisNote:        json['analysisNote'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'deepfakeProbability': deepfakeProbability,
    'confidence':          confidence,
    'riskLevel':           riskLevel,
    'imageRisk':           imageRisk,
    'videoRisk':           videoRisk,
    'audioRisk':           audioRisk,
    'multimodalRisk':      multimodalRisk,
    'analysisNote':        analysisNote,
  };
}

class ReputationResult {
  final String domain;
  final int reputationScore;
  final int sourceReputationScore;
  final double historicalAccuracy;
  final int manipulationIncidents;
  final int verificationSuccess;
  final String transparency;

  const ReputationResult({
    required this.domain,
    required this.reputationScore,
    required this.sourceReputationScore,
    required this.historicalAccuracy,
    required this.manipulationIncidents,
    required this.verificationSuccess,
    required this.transparency,
  });

  factory ReputationResult.fromJson(Map<String, dynamic> json) {
    return ReputationResult(
      domain:                  json['domain'] as String? ?? 'unknown',
      reputationScore:         (json['reputationScore'] as num?)?.toInt() ?? 50,
      sourceReputationScore:   (json['sourceReputationScore'] as num?)?.toInt() ?? 50,
      historicalAccuracy:      (json['historicalAccuracy'] as num?)?.toDouble() ?? 50.0,
      manipulationIncidents:   (json['manipulationIncidents'] as num?)?.toInt() ?? 0,
      verificationSuccess:     (json['verificationSuccess'] as num?)?.toInt() ?? 0,
      transparency:            json['transparency'] as String? ?? 'unknown',
    );
  }

  Map<String, dynamic> toJson() => {
    'domain':                  domain,
    'reputationScore':         reputationScore,
    'sourceReputationScore':   sourceReputationScore,
    'historicalAccuracy':      historicalAccuracy,
    'manipulationIncidents':   manipulationIncidents,
    'verificationSuccess':     verificationSuccess,
    'transparency':            transparency,
  };
}

class ConsensusScores {
  final int authenticityScore;
  final int trustScore;
  final int manipulationScore;
  final int riskScore;
  final int confidenceScore;
  final String verdict;
  final String justification;
  final List<Map<String, dynamic>> adjustments;

  const ConsensusScores({
    required this.authenticityScore,
    required this.trustScore,
    required this.manipulationScore,
    required this.riskScore,
    required this.confidenceScore,
    required this.verdict,
    required this.justification,
    this.adjustments = const [],
  });

  factory ConsensusScores.fromJson(Map<String, dynamic> json) {
    return ConsensusScores(
      authenticityScore: (json['authenticityScore'] as num?)?.toInt() ?? 50,
      trustScore:        (json['trustScore'] as num?)?.toInt() ?? 50,
      manipulationScore: (json['manipulationScore'] as num?)?.toInt() ?? 0,
      riskScore:         (json['riskScore'] as num?)?.toInt() ?? 0,
      confidenceScore:   (json['confidenceScore'] as num?)?.toInt() ?? 50,
      verdict:           json['verdict'] as String? ?? 'UNVERIFIED',
      justification:     json['justification'] as String? ?? '',
      adjustments:       (json['adjustments'] as List?)
              ?.map((e) => Map<String, dynamic>.from(e as Map))
              .toList() ??
          const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'authenticityScore': authenticityScore,
    'trustScore':        trustScore,
    'manipulationScore': manipulationScore,
    'riskScore':         riskScore,
    'confidenceScore':   confidenceScore,
    'verdict':           verdict,
    'justification':     justification,
    'adjustments':       adjustments,
  };

  int get confidence => confidenceScore;
  List<String> get evidenceBreakdown => adjustments.map((e) => "${e['category'].toString().toUpperCase()}: ${e['factor']}").toList();
}

class TrustGraphNode {
  final String id;
  final String label;
  final String type; // Person, Domain, Media, Campaign, BotNetwork, etc.
  final Map<String, dynamic> properties;

  const TrustGraphNode({
    required this.id,
    required this.label,
    required this.type,
    this.properties = const {},
  });

  factory TrustGraphNode.fromJson(Map<String, dynamic> json) {
    return TrustGraphNode(
      id:         json['id'] as String? ?? '',
      label:      json['label'] as String? ?? '',
      type:       json['type'] as String? ?? 'unknown',
      properties: json['properties'] is Map ? Map<String, dynamic>.from(json['properties'] as Map) : const {},
    );
  }

  Map<String, dynamic> toJson() => {
    'id':         id,
    'label':      label,
    'type':       type,
    'properties': properties,
  };
}

class TrustGraphEdge {
  final String from;
  final String to;
  final String relation; // CREATED_BY, HOSTED_BY, GENERATED_BY, etc.

  const TrustGraphEdge({
    required this.from,
    required this.to,
    required this.relation,
  });

  factory TrustGraphEdge.fromJson(Map<String, dynamic> json) {
    return TrustGraphEdge(
      from:     json['from'] as String? ?? '',
      to:       json['to'] as String? ?? '',
      relation: json['relation'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'from':     from,
    'to':       to,
    'relation': relation,
  };
}

class TrustGraph {
  final List<TrustGraphNode> nodes;
  final List<TrustGraphEdge> edges;

  const TrustGraph({
    this.nodes = const [],
    this.edges = const [],
  });

  factory TrustGraph.fromJson(Map<String, dynamic> json) {
    return TrustGraph(
      nodes: (json['nodes'] as List?)?.map((e) => TrustGraphNode.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? const [],
      edges: (json['edges'] as List?)?.map((e) => TrustGraphEdge.fromJson(Map<String, dynamic>.from(e as Map))).toList() ?? const [],
    );
  }

  Map<String, dynamic> toJson() => {
    'nodes': nodes.map((e) => e.toJson()).toList(),
    'edges': edges.map((e) => e.toJson()).toList(),
  };
}

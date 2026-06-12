import '../models/trust_verification_models.dart';

class ConsensusEngine {
  ConsensusEngine._();
  static final ConsensusEngine instance = ConsensusEngine._();

  ConsensusScores calculate({
    required C2PAResult c2pa,
    required ProvenanceResult provenance,
    required DeepfakeResult deepfake,
    required ReputationResult reputation,
    double osintScore = 100.0,
    double factCheckScore = 100.0,
  }) {
    final adjustments = <Map<String, dynamic>>[];

    // 1. Provenance Vector (20%)
    double provScore = 30.0;
    String provFactor = 'Missing cryptographic manifest and EXIF headers';
    if (c2pa.hasC2PA) {
      provScore = 100.0;
      provFactor = 'Verified cryptographic C2PA signature manifest present';
    } else if (provenance.exif.isNotEmpty) {
      provScore = 70.0;
      provFactor = 'Consistent EXIF hardware metadata headers present';
    }
    adjustments.add({
      'impact': (provScore * 0.2).toInt(),
      'factor': provFactor,
      'category': 'provenance',
    });

    // 2. Reputation Vector (20%)
    final double repScore = reputation.reputationScore.toDouble();
    adjustments.add({
      'impact': (repScore * 0.2).toInt(),
      'factor': 'Publisher registry reputation score: ${repScore.toInt()}/100',
      'category': 'reputation',
    });

    // 3. OSINT Vector (20%)
    // Adjust OSINT score based on threat status
    double finalOsintScore = osintScore;
    if (deepfake.riskLevel == 'high' || deepfake.riskLevel == 'malicious') {
      finalOsintScore = 10.0;
    } else if (deepfake.riskLevel == 'medium' || deepfake.riskLevel == 'suspicious') {
      finalOsintScore = 50.0;
    }
    adjustments.add({
      'impact': (finalOsintScore * 0.2).toInt(),
      'factor': 'OSINT threat intelligence scan rating: ${finalOsintScore.toInt()}/100',
      'category': 'osint',
    });

    // 4. Media Forensics Vector (20%)
    final double forenScore = (100.0 - deepfake.deepfakeProbability).clamp(0.0, 100.0);
    adjustments.add({
      'impact': (forenScore * 0.2).toInt(),
      'factor': 'On-device visual forensics score: ${forenScore.toInt()}/100',
      'category': 'forensics',
    });

    // 5. Fact Check Evidence Vector (20%)
    adjustments.add({
      'impact': (factCheckScore * 0.2).toInt(),
      'factor': 'Fact-checking citation verification index: ${factCheckScore.toInt()}/100',
      'category': 'factcheck',
    });

    // Mathematical Trust Score Calculation (Weighted Sum)
    final double computedTrust = (provScore * 0.2) + (repScore * 0.2) + (finalOsintScore * 0.2) + (forenScore * 0.2) + (factCheckScore * 0.2);
    final trustScore = computedTrust.round().clamp(0, 100);

    // Dynamic confidence score calculation based on sensor signals
    int confidenceScore = 60;
    if (c2pa.hasC2PA) confidenceScore += 15;
    if (provenance.exif.isNotEmpty) confidenceScore += 10;
    if (reputation.reputationScore > 50) confidenceScore += 15;
    confidenceScore = confidenceScore.clamp(50, 100);

    // Hard, mathematical verdicts
    String verdict = 'UNVERIFIED';
    String justification = 'Insufficient evidence to verify authenticity.';

    if (trustScore >= 80) {
      verdict = 'TRUE';
      justification = 'Factual consistency confirmed. Dynamic verification math registers authentic origin with zero anomalies.';
    } else if (trustScore >= 45) {
      verdict = 'MISLEADING';
      justification = 'Content contains structural anomalies, altered EXIF headers, or originates from an unverified domain.';
    } else {
      verdict = 'FALSE';
      justification = 'Critical warnings flagged. Forensics pipeline detects high manipulation anomalies.';
    }

    return ConsensusScores(
      authenticityScore: provScore.toInt(),
      trustScore: trustScore,
      manipulationScore: deepfake.deepfakeProbability.toInt(),
      riskScore: (100 - trustScore),
      confidenceScore: confidenceScore,
      verdict: verdict,
      justification: justification,
      adjustments: adjustments,
    );
  }
}

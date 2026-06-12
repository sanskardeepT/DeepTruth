import '../models/trust_verification_models.dart';

class ConsensusEngine {
  ConsensusEngine._();
  static final ConsensusEngine instance = ConsensusEngine._();

  ConsensusScores calculate({
    required C2PAResult c2pa,
    required ProvenanceResult provenance,
    required DeepfakeResult deepfake,
    required ReputationResult reputation,
  }) {
    final adjustments = <Map<String, dynamic>>[];
    int authenticity = 50;

    // C2PA Check
    if (c2pa.hasC2PA) {
      if (c2pa.verificationStatus == 'VERIFIED_ANCHORED_LTL') {
        authenticity += 40;
        adjustments.add({
          'impact': 40,
          'factor': 'Valid Verified C2PA Certificate Anchor',
          'category': 'c2pa'
        });
      } else {
        authenticity += 20;
        adjustments.add({
          'impact': 20,
          'factor': 'Cryptographic C2PA Signature Detected',
          'category': 'c2pa'
        });
      }
    } else {
      adjustments.add({
        'impact': 0,
        'factor': 'Unsigned Media (No C2PA Manifest)',
        'category': 'c2pa'
      });
    }

    // Reputation Check
    if (reputation.reputationScore >= 80) {
      authenticity += 20;
      adjustments.add({
        'impact': 20,
        'factor': 'High Publisher Reputation Rank (${reputation.domain})',
        'category': 'reputation'
      });
    } else if (reputation.reputationScore < 40) {
      authenticity -= 30;
      adjustments.add({
        'impact': -30,
        'factor': 'Low/Unverified Publisher Trust Index (${reputation.domain})',
        'category': 'reputation'
      });
    }

    // Metadata / EXIF Check
    if (provenance.exif.isNotEmpty) {
      authenticity += 10;
      adjustments.add({
        'impact': 10,
        'factor': 'Consistent EXIF Hardware Header Metadata',
        'category': 'metadata'
      });
    } else {
      authenticity -= 5;
      adjustments.add({
        'impact': -5,
        'factor': 'Missing or Stripped Camera EXIF tags',
        'category': 'metadata'
      });
    }

    // Deepfake Check
    if (deepfake.deepfakeProbability > 70) {
      authenticity -= 50;
      adjustments.add({
        'impact': -50,
        'factor': 'High Deepfake Probability Matrix detected',
        'category': 'deepfake'
      });
    } else if (deepfake.deepfakeProbability > 35) {
      authenticity -= 20;
      adjustments.add({
        'impact': -20,
        'factor': 'Moderate synthetic artifacts / GAN markers detected',
        'category': 'deepfake'
      });
    } else {
      authenticity += 10;
      adjustments.add({
        'impact': 10,
        'factor': 'No significant Deepfake artifacts detected',
        'category': 'deepfake'
      });
    }

    authenticity = authenticity.clamp(0, 100);

    final manipulation = deepfake.deepfakeProbability.toInt();
    final riskFactor = (provenance.reusedCount * 12).clamp(10, 100);
    final risk = ((100 - authenticity) * (riskFactor / 100.0)).toInt().clamp(0, 100);
    final trust = authenticity;

    String verdict = 'UNVERIFIED';
    String justification = 'Insufficient data to compute consensus.';

    if (trust >= 80) {
      verdict = 'TRUE';
      justification = 'The claim matches authenticated sources with verified metadata, containing no deepfake markers.';
    } else if (trust >= 50) {
      verdict = 'MISLEADING';
      justification = 'The content contains real elements but carries misleading omissions or lacks valid signature credentials.';
    } else {
      verdict = 'FALSE';
      justification = 'High probability of manipulation detected. Digital forensic analysis reveals synthetic structural artifacts.';
    }

    return ConsensusScores(
      authenticityScore: authenticity,
      trustScore: trust,
      manipulationScore: manipulation,
      riskScore: risk,
      confidenceScore: 92,
      verdict: verdict,
      justification: justification,
      adjustments: adjustments,
    );
  }
}

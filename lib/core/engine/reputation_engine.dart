import '../models/trust_verification_models.dart';

class ReputationEngine {
  ReputationEngine._();
  static final ReputationEngine instance = ReputationEngine._();

  Future<ReputationResult> evaluateDomain(String domain) async {
    final clean = domain
        .replaceAll('https://', '')
        .replaceAll('http://', '')
        .split('/')[0]
        .toLowerCase()
        .trim();

    if (clean == 'reuters.com' ||
        clean == 'apnews.com' ||
        clean == 'bbc.co.uk' ||
        clean == 'nytimes.com') {
      return ReputationResult(
        domain: clean,
        reputationScore: 98,
        sourceReputationScore: 98,
        historicalAccuracy: 99.4,
        manipulationIncidents: 0,
        verificationSuccess: 480,
        transparency: 'EXCELLENT',
      );
    }

    if (clean.contains('leak') ||
        clean.contains('rumor') ||
        clean.contains('buzz') ||
        clean.contains('free') ||
        clean.isEmpty) {
      return ReputationResult(
        domain: clean.isEmpty ? 'unknown' : clean,
        reputationScore: 28,
        sourceReputationScore: 28,
        historicalAccuracy: 32.1,
        manipulationIncidents: 14,
        verificationSuccess: 3,
        transparency: 'POOR_OPAQUE',
      );
    }

    return ReputationResult(
      domain: clean,
      reputationScore: 70,
      sourceReputationScore: 70,
      historicalAccuracy: 80.5,
      manipulationIncidents: 1,
      verificationSuccess: 32,
      transparency: 'MEDIUM_TRANSPARENT',
    );
  }
}

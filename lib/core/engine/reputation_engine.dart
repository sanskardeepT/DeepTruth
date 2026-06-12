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

    // 1. Indian Trust Index Registry
    if (clean == 'pib.gov.in' || clean == 'pressrelease.pib.gov.in') {
      return const ReputationResult(
        domain: 'pib.gov.in',
        reputationScore: 96,
        sourceReputationScore: 96,
        historicalAccuracy: 98.2,
        manipulationIncidents: 0,
        verificationSuccess: 520,
        transparency: 'EXCELLENT',
        category: 'State-controlled',
        biasLabel: 'Neutral',
        historicalReliability: 'High',
        positiveVerifications: 490,
        negativeVerifications: 2,
        communityReports: 5,
        dynamicTrustEvolution: 'STABLE',
      );
    }

    if (clean == 'altnews.in' || clean == 'boomlive.in' || clean == 'factcrescendo.com') {
      return ReputationResult(
        domain: clean,
        reputationScore: 98,
        sourceReputationScore: 98,
        historicalAccuracy: 99.1,
        manipulationIncidents: 0,
        verificationSuccess: 640,
        transparency: 'EXCELLENT',
        category: 'Fact-checker',
        biasLabel: 'Neutral',
        historicalReliability: 'High',
        positiveVerifications: 620,
        negativeVerifications: 1,
        communityReports: 2,
        dynamicTrustEvolution: 'IMPROVING',
      );
    }

    if (clean == 'timesofindia.indiatimes.com' || clean == 'timesofindia.com') {
      return const ReputationResult(
        domain: 'timesofindia.indiatimes.com',
        reputationScore: 88,
        sourceReputationScore: 88,
        historicalAccuracy: 92.4,
        manipulationIncidents: 3,
        verificationSuccess: 1420,
        transparency: 'GOOD',
        category: 'Mainstream Media',
        biasLabel: 'Center-Right',
        historicalReliability: 'High',
        positiveVerifications: 1350,
        negativeVerifications: 35,
        communityReports: 45,
        dynamicTrustEvolution: 'STABLE',
      );
    }

    if (clean == 'thehindu.com' || clean == 'indianexpress.com') {
      return ReputationResult(
        domain: clean,
        reputationScore: 92,
        sourceReputationScore: 92,
        historicalAccuracy: 95.8,
        manipulationIncidents: 1,
        verificationSuccess: 1120,
        transparency: 'EXCELLENT',
        category: 'Mainstream Media',
        biasLabel: 'Center-Left',
        historicalReliability: 'High',
        positiveVerifications: 1090,
        negativeVerifications: 12,
        communityReports: 18,
        dynamicTrustEvolution: 'STABLE',
      );
    }

    if (clean == 'ndtv.com') {
      return const ReputationResult(
        domain: 'ndtv.com',
        reputationScore: 90,
        sourceReputationScore: 90,
        historicalAccuracy: 94.1,
        manipulationIncidents: 2,
        verificationSuccess: 980,
        transparency: 'GOOD',
        category: 'Mainstream Media',
        biasLabel: 'Center-Left',
        historicalReliability: 'High',
        positiveVerifications: 940,
        negativeVerifications: 18,
        communityReports: 24,
        dynamicTrustEvolution: 'STABLE',
      );
    }

    // 2. Global News Defaults
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
        category: 'Mainstream Media',
        biasLabel: 'Neutral',
        historicalReliability: 'High',
        positiveVerifications: 475,
        negativeVerifications: 1,
        communityReports: 3,
        dynamicTrustEvolution: 'STABLE',
      );
    }

    // 3. Suspect Rumor / Phishing Domains
    if (clean.contains('leak') ||
        clean.contains('rumor') ||
        clean.contains('buzz') ||
        clean.contains('free') ||
        clean.contains('whatsapp') ||
        clean.isEmpty) {
      return ReputationResult(
        domain: clean.isEmpty ? 'unknown' : clean,
        reputationScore: 28,
        sourceReputationScore: 28,
        historicalAccuracy: 28.0,
        manipulationIncidents: 15,
        verificationSuccess: 0,
        transparency: 'POOR_SUSPICIOUS',
        category: 'Unverified',
        biasLabel: 'Neutral',
        historicalReliability: 'Low',
        positiveVerifications: 2,
        negativeVerifications: 75,
        communityReports: 140,
        dynamicTrustEvolution: 'DEGRADED',
      );
    }

    // 4. Default Fallback (Unverified/Generic)
    return ReputationResult(
      domain: clean,
      reputationScore: 50,
      sourceReputationScore: 50,
      historicalAccuracy: 50.0,
      manipulationIncidents: 0,
      verificationSuccess: 0,
      transparency: 'UNVERIFIED',
      category: 'Unverified',
      biasLabel: 'Neutral',
      historicalReliability: 'Medium',
      positiveVerifications: 10,
      negativeVerifications: 10,
      communityReports: 8,
      dynamicTrustEvolution: 'STABLE',
    );
  }
}

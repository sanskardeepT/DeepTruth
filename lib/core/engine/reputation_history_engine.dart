import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../models/trust_verification_models.dart';

class ReputationHistoryEngine {
  ReputationHistoryEngine._();
  static final ReputationHistoryEngine instance = ReputationHistoryEngine._();

  // Prior parameters for Bayesian confidence weighting
  static const double priorTrust = 0.5; // Prior probability (50% neutral trust)
  static const double priorWeight = 10.0; // Virtual samples weight to prevent extreme scores

  /// Dynamic seed registry of domains
  static const Map<String, Map<String, dynamic>> _seeds = {
    'pib.gov.in': {
      'category': 'State-controlled',
      'biasLabel': 'Neutral',
      'positiveVerifications': 490,
      'negativeVerifications': 2,
      'communityReports': 5,
    },
    'pressrelease.pib.gov.in': {
      'category': 'State-controlled',
      'biasLabel': 'Neutral',
      'positiveVerifications': 490,
      'negativeVerifications': 2,
      'communityReports': 5,
    },
    'altnews.in': {
      'category': 'Fact-checker',
      'biasLabel': 'Neutral',
      'positiveVerifications': 620,
      'negativeVerifications': 1,
      'communityReports': 2,
    },
    'boomlive.in': {
      'category': 'Fact-checker',
      'biasLabel': 'Neutral',
      'positiveVerifications': 620,
      'negativeVerifications': 1,
      'communityReports': 2,
    },
    'factcrescendo.com': {
      'category': 'Fact-checker',
      'biasLabel': 'Neutral',
      'positiveVerifications': 620,
      'negativeVerifications': 1,
      'communityReports': 2,
    },
    'timesofindia.indiatimes.com': {
      'category': 'Mainstream Media',
      'biasLabel': 'Center-Right',
      'positiveVerifications': 1350,
      'negativeVerifications': 35,
      'communityReports': 45,
    },
    'timesofindia.com': {
      'category': 'Mainstream Media',
      'biasLabel': 'Center-Right',
      'positiveVerifications': 1350,
      'negativeVerifications': 35,
      'communityReports': 45,
    },
    'thehindu.com': {
      'category': 'Mainstream Media',
      'biasLabel': 'Center-Left',
      'positiveVerifications': 1090,
      'negativeVerifications': 12,
      'communityReports': 18,
    },
    'indianexpress.com': {
      'category': 'Mainstream Media',
      'biasLabel': 'Center-Left',
      'positiveVerifications': 1090,
      'negativeVerifications': 12,
      'communityReports': 18,
    },
    'ndtv.com': {
      'category': 'Mainstream Media',
      'biasLabel': 'Center-Left',
      'positiveVerifications': 940,
      'negativeVerifications': 18,
      'communityReports': 24,
    },
    'reuters.com': {
      'category': 'Mainstream Media',
      'biasLabel': 'Neutral',
      'positiveVerifications': 475,
      'negativeVerifications': 1,
      'communityReports': 3,
    },
    'apnews.com': {
      'category': 'Mainstream Media',
      'biasLabel': 'Neutral',
      'positiveVerifications': 475,
      'negativeVerifications': 1,
      'communityReports': 3,
    },
    'bbc.co.uk': {
      'category': 'Mainstream Media',
      'biasLabel': 'Neutral',
      'positiveVerifications': 475,
      'negativeVerifications': 1,
      'communityReports': 3,
    },
    'nytimes.com': {
      'category': 'Mainstream Media',
      'biasLabel': 'Neutral',
      'positiveVerifications': 475,
      'negativeVerifications': 1,
      'communityReports': 3,
    },
  };

  // Minimum verification threshold to prevent extreme scores from small sample sizes
  static const int minVerificationThreshold = 5;

  /// Calculates the dynamic Bayesian reputation score with confidence weighting and a minimum threshold
  int _calculateBayesianScore(int pos, int neg, int community) {
    final int totalVerifications = pos + neg;
    final double priorPos = priorTrust * priorWeight;
    final double priorNeg = (1.0 - priorTrust) * priorWeight;
    final double penalty = community * 0.5;
    final double denominator = pos + neg + priorPos + priorNeg + penalty;

    if (denominator == 0.0) return 50;
    double score = ((pos + priorPos) / denominator) * 100;

    // Apply minimum verification threshold weighting:
    // If total verifications is less than the threshold, we weight the score towards the neutral score of 50.
    if (totalVerifications < minVerificationThreshold) {
      final double confidence = totalVerifications / minVerificationThreshold;
      score = (score * confidence) + (50.0 * (1.0 - confidence));
    }

    return score.round().clamp(0, 100);
  }

  /// Calculates dynamic historical reliability rating
  String _determineReliability(int score) {
    if (score >= 80) return 'High';
    if (score >= 50) return 'Medium';
    return 'Low';
  }

  /// Evaluates and retrieves a domain's dynamic reputation record
  Future<ReputationResult> getReputation(String domain) async {
    final clean = domain
        .replaceAll('https://', '')
        .replaceAll('http://', '')
        .split('/')[0]
        .toLowerCase()
        .trim();

    try {
      if (Hive.isBoxOpen(AppConstants.boxReputationHistory)) {
        final box = Hive.box<String>(AppConstants.boxReputationHistory);
        final cachedJson = box.get(clean);

        if (cachedJson != null) {
          final Map<String, dynamic> data = jsonDecode(cachedJson);
          return ReputationResult.fromJson(data);
        }
      }
    } catch (e) {
      debugPrint('Failed to query ReputationHistory box: $e');
    }

    // Seed/Fallback Logic
    Map<String, dynamic> record;
    if (_seeds.containsKey(clean)) {
      record = Map<String, dynamic>.from(_seeds[clean]!);
    } else {
      // Default suspect domain profile
      if (clean.contains('leak') ||
          clean.contains('rumor') ||
          clean.contains('buzz') ||
          clean.contains('free') ||
          clean.contains('whatsapp') ||
          clean.isEmpty) {
        record = {
          'category': 'Unverified',
          'biasLabel': 'Neutral',
          'positiveVerifications': 2,
          'negativeVerifications': 75,
          'communityReports': 140,
        };
      } else {
        record = {
          'category': 'Unverified',
          'biasLabel': 'Neutral',
          'positiveVerifications': 0,
          'negativeVerifications': 0,
          'communityReports': 0,
        };
      }
    }

    final int score = _calculateBayesianScore(
      record['positiveVerifications'] as int,
      record['negativeVerifications'] as int,
      record['communityReports'] as int,
    );

    final result = ReputationResult(
      domain: clean.isEmpty ? 'unknown' : clean,
      reputationScore: score,
      sourceReputationScore: score,
      historicalAccuracy: score.toDouble(),
      manipulationIncidents: record['negativeVerifications'] as int,
      verificationSuccess: record['positiveVerifications'] as int,
      transparency: score >= 85 ? 'EXCELLENT' : (score >= 50 ? 'GOOD' : 'POOR_SUSPICIOUS'),
      category: record['category'] as String,
      biasLabel: record['biasLabel'] as String,
      historicalReliability: _determineReliability(score),
      positiveVerifications: record['positiveVerifications'] as int,
      negativeVerifications: record['negativeVerifications'] as int,
      communityReports: record['communityReports'] as int,
      dynamicTrustEvolution: 'STABLE',
    );

    // Save seeded value
    _saveReputation(clean, result);
    return result;
  }

  /// Records a verification event and updates the domain reputation dynamic metric
  Future<void> recordVerification(String domain, String verdict) async {
    if (domain.trim().isEmpty) return;

    final clean = domain
        .replaceAll('https://', '')
        .replaceAll('http://', '')
        .split('/')[0]
        .toLowerCase()
        .trim();

    final current = await getReputation(clean);

    int pos = current.positiveVerifications;
    int neg = current.negativeVerifications;

    if (verdict == 'TRUE') {
      pos += 1;
    } else if (verdict == 'FALSE' || verdict == 'MISLEADING') {
      neg += 1;
    }

    final newScore = _calculateBayesianScore(pos, neg, current.communityReports);
    final String evolution = newScore > current.reputationScore
        ? 'IMPROVING'
        : (newScore < current.reputationScore ? 'DEGRADED' : 'STABLE');

    final updated = ReputationResult(
      domain: clean,
      reputationScore: newScore,
      sourceReputationScore: newScore,
      historicalAccuracy: newScore.toDouble(),
      manipulationIncidents: neg,
      verificationSuccess: pos,
      transparency: newScore >= 85 ? 'EXCELLENT' : (newScore >= 50 ? 'GOOD' : 'POOR_SUSPICIOUS'),
      category: current.category,
      biasLabel: current.biasLabel,
      historicalReliability: _determineReliability(newScore),
      positiveVerifications: pos,
      negativeVerifications: neg,
      communityReports: current.communityReports,
      dynamicTrustEvolution: evolution,
    );

    await _saveReputation(clean, updated);
    debugPrint('Reputation Evolved for $clean: $newScore ($evolution)');
  }

  Future<void> _saveReputation(String clean, ReputationResult result) async {
    try {
      if (Hive.isBoxOpen(AppConstants.boxReputationHistory)) {
        final box = Hive.box<String>(AppConstants.boxReputationHistory);
        await box.put(clean, jsonEncode(result.toJson()));
      }
    } catch (e) {
      debugPrint('Failed to save evolved reputation: $e');
    }
  }
}

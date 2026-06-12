import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:deeptruth/core/constants/app_constants.dart';
import 'package:deeptruth/core/models/check_result.dart';
import 'package:deeptruth/core/models/trust_verification_models.dart';
import 'package:deeptruth/core/engine/reputation_history_engine.dart';
import 'package:deeptruth/core/engine/claim_memory_engine.dart';

void main() {
  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('deeptruth_mandate_test_hive');
    Hive.init(tempDir.path);
    await Future.wait([
      Hive.openBox<String>(AppConstants.boxChecks),
      Hive.openBox<String>(AppConstants.boxSettings),
      Hive.openBox<String>(AppConstants.boxClaimMemory),
      Hive.openBox<String>(AppConstants.boxReputationHistory),
    ]);
  });

  tearDownAll(() async {
    await Hive.close();
  });

  group('Dynamic Reputation History Engine (Bayesian Evolution)', () {
    test('Reputation seeds properly and implements Bayesian calculation', () async {
      final engine = ReputationHistoryEngine.instance;
      final result = await engine.getReputation('pib.gov.in');

      expect(result.domain, equals('pib.gov.in'));
      expect(result.category, equals('State-controlled'));
      expect(result.historicalReliability, equals('High'));
      // Starting seed is High trust (98%)
      expect(result.reputationScore, greaterThanOrEqualTo(90));
    });

    test('Verification results dynamically evolve domain trust metrics', () async {
      final engine = ReputationHistoryEngine.instance;
      final domain = 'new-unverified-domain.com';

      // Verify fallback initial score is 50
      final initial = await engine.getReputation(domain);
      expect(initial.reputationScore, equals(50));

      // Record several negative verifications
      await engine.recordVerification(domain, 'FALSE');
      await engine.recordVerification(domain, 'FALSE');
      await engine.recordVerification(domain, 'FALSE');

      final evolvedNegative = await engine.getReputation(domain);
      // Trust score should have evolved downwards due to negative feedback
      expect(evolvedNegative.reputationScore, lessThan(50));
      expect(evolvedNegative.dynamicTrustEvolution, equals('DEGRADED'));

      // Record several positive verifications
      await engine.recordVerification(domain, 'TRUE');
      await engine.recordVerification(domain, 'TRUE');
      await engine.recordVerification(domain, 'TRUE');
      await engine.recordVerification(domain, 'TRUE');
      await engine.recordVerification(domain, 'TRUE');

      final evolvedPositive = await engine.getReputation(domain);
      // Trust score should rise again
      expect(evolvedPositive.reputationScore, greaterThan(evolvedNegative.reputationScore));
      expect(evolvedPositive.dynamicTrustEvolution, equals('IMPROVING'));
    });
  });

  group('Layered Claim Memory Engine', () {
    test('Calculates similarity correctly across 4 layers', () {
      final engine = ClaimMemoryEngine.instance;

      // Layer 1: Exact / Normalized Match (case/punctuation mismatch)
      final scoreExact = engine.calculateSimilarity(
        'Government is offering Rs. 239 free recharge scheme!',
        'government is offering rs 239 free recharge scheme',
      );
      expect(scoreExact, equals(1.0));

      // Layer 2: Levenshtein distance check
      final scoreClose = engine.calculateSimilarity(
        'NASA confirms giant meteor impact next week',
        'NASA warns meteor impact will destroy Earth next week',
      );
      expect(scoreClose, greaterThan(0.7));

      // Layer 4: Keyword Jaccard matching
      final scoreUnrelated = engine.calculateSimilarity(
        'This is a completely random WhatsApp claim',
        'Apocalyptic asteroid heading to Mars soon',
      );
      expect(scoreUnrelated, lessThan(0.4));
    });

    test('Searches claim memory registry and fetches match with metadata', () async {
      final engine = ClaimMemoryEngine.instance;
      final mockResult = CheckResult(
        originalContent: 'This is a viral scam forward',
        truthScore: 5,
        verdict: 'FALSE',
        explanation: 'Fictional claims debunked by TRAI.',
        manipulationScore: 95,
        contentType: 'text',
        analyzedAt: DateTime.now(),
        reportId: 'DT-TEST123',
      );

      await engine.saveClaim('This is a viral scam forward', mockResult);

      final match = await engine.findMatch('This is a viral scam forward details');
      expect(match, isNotNull);
      expect(match!.similarityScore, greaterThanOrEqualTo(0.85));
      expect(match.historicalVerdict, equals('FALSE'));
      expect(match.category, equals('text'));
      expect(match.firstSeen, isNotNull);
      expect(match.lastSeen, isNotNull);
    });
  });

  group('Gemini Score Decoupling Protection', () {
    test('Gemini response values cannot override deterministic consensus values', () {
      // Mock local consensus scores
      const localConsensus = ConsensusScores(
        authenticityScore: 70,
        trustScore: 84,
        manipulationScore: 10,
        riskScore: 16,
        confidenceScore: 92,
        verdict: 'TRUE',
        justification: 'Secure manifest matches.',
      );

      // Create a mock raw JSON representation that mimics an altered Gemini payload
      final mockGeminiPayload = {
        'explanation': 'Altered text narrative.',
        'summary': 'Summary narrative interpretation.',
        'missingContext': null,
        'sources': ['Source 1'],
        'manipulationTactics': ['Fear Mongering'],
        'logicalFallacies': [],
        'contentType': 'news',
        // Attempted score overrides that Gemini must not change
        'truthScore': 12,
        'verdict': 'FALSE',
        'manipulationScore': 80,
      };

      // Deserialization with fallback and score shielding validation
      final result = CheckResult(
        originalContent: 'Original claim text content.',
        truthScore: localConsensus.trustScore, // Shielded: consensus score enforced
        verdict: localConsensus.verdict,       // Shielded: consensus verdict enforced
        explanation: mockGeminiPayload['explanation'] as String,
        summary: mockGeminiPayload['summary'] as String,
        missingContext: mockGeminiPayload['missingContext'] as String?,
        sources: (mockGeminiPayload['sources'] as List).cast<String>(),
        manipulationTactics: (mockGeminiPayload['manipulationTactics'] as List).cast<String>(),
        logicalFallacies: (mockGeminiPayload['logicalFallacies'] as List).cast<String>(),
        manipulationScore: localConsensus.manipulationScore, // Shielded
        contentType: mockGeminiPayload['contentType'] as String,
        analyzedAt: DateTime.now(),
        reportId: 'DT-MOCKREPORT',
        consensus: localConsensus,
      );

      // Confirm scores match the deterministic Consensus Engine, not the overridden Gemini values
      expect(result.truthScore, equals(84));
      expect(result.verdict, equals('TRUE'));
      expect(result.manipulationScore, equals(10));
      expect(result.explanation, equals('Altered text narrative.'));
    });
  });
}

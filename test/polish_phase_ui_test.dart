import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:deeptruth/features/legal/legal_center_screen.dart';
import 'package:deeptruth/features/truth_lens/widgets/evidence_timeline.dart';
import 'package:deeptruth/features/truth_lens/widgets/explainability_tree.dart';
import 'package:deeptruth/core/models/check_result.dart';
import 'package:deeptruth/core/models/trust_verification_models.dart';
import 'package:deeptruth/core/engine/reputation_engine.dart';
import 'package:deeptruth/core/engine/claim_memory_engine.dart';

void main() {
  testWidgets('LegalCenterScreen builds and shows policies', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LegalCenterScreen(),
      ),
    );

    // Verify Title
    expect(find.text('LEGAL & COMPLIANCE CENTER'), findsOneWidget);

    // Verify some Policy Titles
    expect(find.text('1. Terms of Service (ToS)'), findsOneWidget);
    expect(find.text('2. Privacy Policy'), findsOneWidget);
    expect(find.text('7. Contact & Grievance Registry'), findsOneWidget);
  });

  testWidgets('EvidenceTimeline and ExplainabilityTree render correctly', (WidgetTester tester) async {
    final mockResult = CheckResult(
      originalContent: 'https://test.com/fake.png',
      truthScore: 85,
      verdict: 'TRUE',
      explanation: 'Consensus verified authentic source.',
      manipulationScore: 15,
      contentType: 'image',
      analyzedAt: DateTime(2026, 6, 12, 12, 0),
      reportId: 'DT-TEST-1234',
      c2pa: const C2PAResult(
        hasC2PA: true,
        creator: 'Camera Signature',
        publisher: 'Test Agency',
        createdAt: '2026-06-12 10:00:00 UTC',
        trustScore: 90,
        verificationStatus: 'VERIFIED',
      ),
      provenance: const ProvenanceResult(
        reusedCount: 0,
        earliestDate: '2026-06-12 09:30:00 UTC',
        sourceDomain: 'test.com',
      ),
      consensus: const ConsensusScores(
        authenticityScore: 100,
        trustScore: 85,
        manipulationScore: 15,
        riskScore: 15,
        confidenceScore: 90,
        verdict: 'TRUE',
        justification: 'Consensus calculation matches.',
        adjustments: [
          {'category': 'provenance', 'factor': 'Verified cryptographic signature present', 'impact': 20},
          {'category': 'reputation', 'factor': 'Publisher reputation: 80/100', 'impact': 16},
        ],
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: Column(
              children: [
                EvidenceTimeline(result: mockResult),
                TrustScoreExplainabilityTree(consensus: mockResult.consensus!),
              ],
            ),
          ),
        ),
      ),
    );

    // Verify timeline elements
    expect(find.text('MEDIA INTEGRITY TIMELINE'), findsOneWidget);
    expect(find.text('Original Asset Capture / Creation'), findsOneWidget);
    expect(find.text('First Public Web Fingerprint'), findsOneWidget);
    expect(find.text('DeepTruth Verification Scan'), findsOneWidget);

    // Verify tree elements
    expect(find.text('TRUST SCORE EXPLAINABILITY TREE'), findsOneWidget);
    expect(find.text('85/100'), findsOneWidget);
    expect(find.text('VERDICT: TRUE'), findsOneWidget);
    expect(find.text('Verified cryptographic signature present'), findsOneWidget);
  });

  test('ReputationEngine returns expanded Indian Trust Index fields', () async {
    final clean = await ReputationEngine.instance.evaluateDomain('pib.gov.in');
    expect(clean.category, equals('State-controlled'));
    expect(clean.biasLabel, equals('Neutral'));
    expect(clean.historicalReliability, equals('High'));
    expect(clean.positiveVerifications, greaterThan(0));
    expect(clean.dynamicTrustEvolution, equals('STABLE'));
  });

  test('ClaimMemoryEngine similarity matching calculations', () {
    final engine = ClaimMemoryEngine.instance;
    final s1 = "This is a viral WhatsApp forward claim";
    final s2 = "This is a viral WhatsApp forward claim";
    final similarityExact = engine.calculateSimilarity(s1, s2);
    expect(similarityExact, equals(1.0));

    final similarityClose = engine.calculateSimilarity(s1, "This is a viral WhatsApp forward claim details");
    expect(similarityClose, greaterThan(0.8));

    final similarityFar = engine.calculateSimilarity(s1, "Apocalyptic meteor alert NASA");
    expect(similarityFar, lessThan(0.4));
  });
}

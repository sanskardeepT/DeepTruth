import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:deeptruth/core/engine/c2pa_engine.dart';
import 'package:deeptruth/core/engine/provenance_engine.dart';
import 'package:deeptruth/core/engine/deepfake_engine.dart';
import 'package:deeptruth/core/engine/reputation_engine.dart';
import 'package:deeptruth/core/engine/consensus_engine.dart';
import 'package:deeptruth/core/engine/trust_graph_service.dart';

void main() {
  group('DeepTruth X Core Engines Test', () {
    test('C2PA Engine Magic Bytes Verification', () async {
      // Test 1: Empty bytes should return NO_ASSET_DATA
      final res1 = await C2paEngine.instance.verifyAsset(null, Uint8List(0));
      expect(res1.hasC2PA, isFalse);
      expect(res1.verificationStatus, 'NO_ASSET_DATA');

      // Test 2: Bytes with 'c2pa' magic string should return verified
      final testBytes = Uint8List.fromList('some random header c2pa signature content'.codeUnits);
      final res2 = await C2paEngine.instance.verifyAsset(null, testBytes);
      expect(res2.hasC2PA, isTrue);
      expect(res2.creator, 'Reuters Editorial Desk');
      expect(res2.trustScore, 95);
    });

    test('Deepfake Engine Multimodal Risk Calculations', () async {
      // Test 1: Scan general file bytes (should simulate general image risk)
      final dummyBytes = Uint8List.fromList('generic image bytes'.codeUnits);
      final res = await DeepfakeEngine.instance.scanAsset('test.png', dummyBytes);
      expect(res.imageRisk, 12.4);
      expect(res.videoRisk, 0.0);
      expect(res.audioRisk, 0.0);
      expect(res.riskLevel, 'low');

      // Test 2: AI metadata strings should increase image risk
      final aiBytes = Uint8List.fromList('Creator: Midjourney generated content'.codeUnits);
      final resAI = await DeepfakeEngine.instance.scanAsset('test.png', aiBytes);
      expect(resAI.imageRisk, 88.0);
      expect(resAI.riskLevel, 'high');
    });

    test('Publisher Reputation Engine Scoring', () async {
      // Test 1: Trusted domain
      final repReuters = await ReputationEngine.instance.evaluateDomain('https://reuters.com/news/1');
      expect(repReuters.reputationScore, 98);
      expect(repReuters.transparency, 'EXCELLENT');

      // Test 2: Suspicious domain
      final repRumors = await ReputationEngine.instance.evaluateDomain('http://viralrumors.blogspot.com');
      expect(repRumors.reputationScore, 28);
      expect(repRumors.transparency, 'POOR_OPAQUE');
    });

    test('Consensus Engine Math Scoring Calculations', () {
      final c2pa = C2paEngine.instance.verifyAsset(null, Uint8List.fromList('c2pa'.codeUnits));
      final prov = ProvenanceEngine.instance.analyzeAsset(null);
      final df = DeepfakeEngine.instance.scanAsset(null, Uint8List.fromList('DALL-E'.codeUnits));
      final rep = ReputationEngine.instance.evaluateDomain('reuters.com');

      Future.wait([c2pa, prov, df, rep]).then((results) {
        final con = ConsensusEngine.instance.calculate(
          c2pa: results[0] as dynamic,
          provenance: results[1] as dynamic,
          deepfake: results[2] as dynamic,
          reputation: results[3] as dynamic,
        );

        // Score should accumulate: 50 base + adjustments
        expect(con.trustScore, greaterThan(0));
        expect(con.trustScore, lessThanOrEqualTo(100));
        expect(con.verdict, isNotEmpty);
      });
    });

    test('Trust Graph Generation Lineage Nodes and Edges', () {
      final graph = TrustGraphService.instance.generateLineage(
        creatorName: 'AP Photographer',
        publisherName: 'Associated Press',
        sourceDomain: 'apnews.com',
        deepfakeFamily: 'StableDiffusion-XL',
      );

      expect(graph.nodes.length, 7);
      expect(graph.edges.length, 6);
      expect(graph.nodes.any((n) => n.type == 'Person'), isTrue);
      expect(graph.nodes.any((n) => n.type == 'Campaign'), isTrue);
    });
  });
}

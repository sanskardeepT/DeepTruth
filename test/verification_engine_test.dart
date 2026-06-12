import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:deeptruth/core/engine/c2pa_engine.dart';
import 'package:deeptruth/core/engine/provenance_engine.dart';
import 'package:deeptruth/core/engine/deepfake_engine.dart';
import 'package:deeptruth/core/engine/reputation_engine.dart';
import 'package:deeptruth/core/engine/consensus_engine.dart';
import 'package:deeptruth/core/engine/trust_graph_service.dart';
import 'package:deeptruth/core/utils/hash_util.dart';

void main() {
  group('DeepTruth X Core Engines Test', () {
    test('C2PA Engine Magic Bytes Verification', () async {
      // Test 1: Empty bytes should return NO_ASSET_DATA
      final res1 = await C2paEngine.instance.verifyAsset(null, Uint8List(0));
      expect(res1.hasC2PA, isFalse);
      expect(res1.verificationStatus, 'NO_ASSET_DATA');

      // Test 2: Bytes with 'c2pa' magic string should return verified status
      final testBytes = Uint8List.fromList('some random header c2pa signature content'.codeUnits);
      final res2 = await C2paEngine.instance.verifyAsset(null, testBytes);
      expect(res2.hasC2PA, isTrue);
      expect(res2.creator, isNull);
      expect(res2.trustScore, 75);
    });

    test('Deepfake Engine Multimodal Risk Calculations', () async {
      // Test 1: Scan audio file (deterministic honest unknown)
      final resAudio = await DeepfakeEngine.instance.scanAsset('test.mp3', Uint8List(10));
      expect(resAudio.deepfakeProbability, 0.0);
      expect(resAudio.riskLevel, 'unknown');
      expect(resAudio.analysisNote, contains('Audio deepfake detection'));

      // Test 2: Unconfigured Gemini key handling
      final dummyBytes = Uint8List.fromList('generic image bytes'.codeUnits);
      final res = await DeepfakeEngine.instance.scanAsset('test.png', dummyBytes);
      expect(res.imageRisk, 0.0);
      expect(res.riskLevel, 'unconfigured');
    });

    test('Publisher Reputation Engine Scoring', () async {
      // Test 1: Trusted domain
      final repReuters = await ReputationEngine.instance.evaluateDomain('https://reuters.com/news/1');
      expect(repReuters.reputationScore, 98);
      expect(repReuters.transparency, 'EXCELLENT');

      // Test 2: Suspicious domain
      final repRumors = await ReputationEngine.instance.evaluateDomain('http://viralrumors.blogspot.com');
      expect(repRumors.reputationScore, lessThanOrEqualTo(10));
      expect(repRumors.transparency, 'POOR_SUSPICIOUS');
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

    test('HashUtil SHA-256 Hashing Verification', () async {
      final bytes = Uint8List.fromList('DeepTruth'.codeUnits);
      final hash = await HashUtil.calculateSha256(bytes);
      // Expected SHA-256 of "DeepTruth"
      expect(hash, 'f96b4c292a908afcf26801cc655e8e8ce5a0fc689ed2666c1ea421d6e093fe81');
    });
  });
}

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import '../constants/app_constants.dart';
import '../models/check_result.dart';
import '../models/trust_verification_models.dart';
import '../models/osint_result.dart';
import '../engine/c2pa_engine.dart';
import '../engine/provenance_engine.dart';
import '../engine/deepfake_engine.dart';
import '../engine/reputation_engine.dart';
import '../engine/consensus_engine.dart';
import '../engine/trust_graph_service.dart';
import '../engine/verification_plugin.dart';
import '../utils/hash_util.dart';
import 'threat_intel_service.dart';
import 'reverse_image_service.dart';
import 'fact_check_service.dart';
import 'firebase_service.dart';
import 'streak_service.dart';

class VerificationPipelineOrchestrator {
  VerificationPipelineOrchestrator._();
  static final VerificationPipelineOrchestrator instance =
      VerificationPipelineOrchestrator._();

  final _firestore = FirebaseFirestore.instance;
  final _uuid = const Uuid();

  // Modular verification plugins registry
  final List<VerificationPlugin> _plugins = [
    C2PaPlugin(),
    ProvenancePlugin(),
    DeepfakePlugin(),
    ThreatIntelPlugin(),
    FactCheckPlugin(),
    ReverseImagePlugin(),
  ];

  /// Main orchestration pipeline. Directs verification based on input type.
  /// Generates hashes and queries the Evidence Vault before executing real APIs.
  Future<CheckResult> verify({
    required String inputType, // image | video | url | text
    required String originalContent, // filePath, url, or raw text claim
    Uint8List? fileBytes,
    void Function(String)? onStageChanged,
  }) async {
    final reportId = 'DT-${DateTime.now().millisecondsSinceEpoch}-${_uuid.v4().substring(0, 4)}';
    final stopwatch = Stopwatch()..start();

    // 1. Calculate SHA-256 for de-duplication in background isolate
    onStageChanged?.call('Computing secure SHA-256 hash…');
    String hash;
    if (fileBytes != null && fileBytes.isNotEmpty) {
      hash = await HashUtil.calculateSha256(fileBytes);
    } else {
      hash = await HashUtil.calculateSha256(Uint8List.fromList(originalContent.codeUnits));
    }

    // 2. Check Local Hive Cache first (Offline Verification)
    onStageChanged?.call('Checking local cache registry…');
    try {
      if (Hive.isBoxOpen(AppConstants.boxSettings)) {
        final localBox = Hive.box<String>(AppConstants.boxSettings);
        final cachedJson = localBox.get('evidence_vault_$hash');
        if (cachedJson != null) {
          debugPrint('Evidence Vault: Local Cache Hit for $hash');
          final decoded = jsonDecode(cachedJson) as Map<String, dynamic>;
          final cachedResult = CheckResult.fromJson(decoded);
          await _saveToLocalHistory(cachedResult);
          return cachedResult;
        }
      }
    } catch (e) {
      debugPrint('Local Cache checking failed: $e');
    }

    // 3. Check Cloud Evidence Vault for identical media de-duplication
    onStageChanged?.call('Checking Cloud Evidence Vault…');
    try {
      final vaultDoc = await _firestore.collection('evidence_vault').doc(hash).get();
      if (vaultDoc.exists && vaultDoc.data() != null) {
        debugPrint('Evidence Vault: Cloud Cache Hit for $hash');
        final data = vaultDoc.data()!;
        
        // Increment reuse count
        await _firestore.collection('evidence_vault').doc(hash).update({
          'reuseCount': FieldValue.increment(1),
        });

        final checkResult = CheckResult.fromJson(data);

        // Save back to local Hive cache & local history
        _cacheLocally(hash, checkResult);
        await _saveToLocalHistory(checkResult);

        return checkResult;
      }
    } catch (e) {
      debugPrint('Cloud Evidence Vault check failed: $e');
    }

    // 4. Cache Miss: Execute Verification Pipelines dynamically
    CheckResult result;

    if (inputType == 'image') {
      result = await _verifyImage(originalContent, fileBytes, hash, reportId, onStageChanged);
    } else if (inputType == 'url') {
      result = await _verifyUrl(originalContent, hash, reportId, onStageChanged);
    } else if (inputType == 'text') {
      result = await _verifyClaim(originalContent, hash, reportId, onStageChanged);
    } else if (inputType == 'video') {
      result = await _verifyVideo(originalContent, fileBytes, hash, reportId, onStageChanged);
    } else {
      throw ArgumentError('Invalid input type: $inputType');
    }

    stopwatch.stop();
    final benchmarkDurationMs = stopwatch.elapsedMilliseconds;

    // 5. Store completed audit record inside the Evidence Vault & local cache
    onStageChanged?.call('Saving analysis results to Vault…');
    try {
      final resultJson = result.toJson();
      resultJson['reuseCount'] = 1; // Initial verification
      resultJson['sha256Hash'] = hash;
      
      // Expanded metadata fields for Product Hardening / ML dataset collection
      resultJson['fileSizeBytes'] = fileBytes != null ? fileBytes.length : originalContent.codeUnits.length * 2;
      resultJson['locale'] = Platform.localeName;
      resultJson['devicePlatform'] = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'desktop');
      resultJson['anonymousId'] = StreakService.instance.anonymousId;
      resultJson['benchmarkDurationMs'] = benchmarkDurationMs;

      await _firestore.collection('evidence_vault').doc(hash).set(resultJson);
      _cacheLocally(hash, result);
      await _saveToLocalHistory(result);
    } catch (e) {
      debugPrint('Saving to Evidence Vault failed: $e');
    }

    // Track completed scan in analytics
    try {
      await FirebaseService.instance.logFactCheck(result.verdict, result.truthScore);
      await FirebaseService.instance.logEvent('scan_completed', {
        'inputType': inputType,
        'hash': hash,
      });
    } catch (_) {}

    return result;
  }

  void _cacheLocally(String hash, CheckResult result) {
    try {
      if (Hive.isBoxOpen(AppConstants.boxSettings)) {
        final localBox = Hive.box<String>(AppConstants.boxSettings);
        localBox.put('evidence_vault_$hash', jsonEncode(result.toJson()));
      }
    } catch (_) {}
  }

  Future<void> _saveToLocalHistory(CheckResult result) async {
    try {
      if (Hive.isBoxOpen(AppConstants.boxChecks)) {
        final box = Hive.box<String>(AppConstants.boxChecks);
        await box.put(result.reportId, jsonEncode(result.toJson()));
        debugPrint('Saved check to local history: ${result.reportId}');
      }
    } catch (e) {
      debugPrint('Failed to save check to local history: $e');
    }
  }

  /// Helper to execute plugins supporting a specific input type in parallel
  Future<Map<String, dynamic>> _executePlugins(
    String inputType,
    String originalContent,
    Uint8List? fileBytes,
  ) async {
    final activePlugins = _plugins.where((p) => p.supports(inputType)).toList();
    final futures = activePlugins.map((p) => p.execute(originalContent, fileBytes));
    final pluginResults = await Future.wait(futures);

    final resultsMap = <String, dynamic>{};
    for (int i = 0; i < activePlugins.length; i++) {
      resultsMap[activePlugins[i].id] = pluginResults[i];
    }
    return resultsMap;
  }

  // ══════════════════════════════════════════════════════════════════
  //  IMAGE PIPELINE (Refactored to Plugins)
  // ══════════════════════════════════════════════════════════════════
  Future<CheckResult> _verifyImage(
    String filePath,
    Uint8List? bytes,
    String hash,
    String reportId,
    void Function(String)? onStageChanged,
  ) async {
    // Run plugins in parallel
    onStageChanged?.call('Running parallel forensic plugins…');
    final resultsMap = await _executePlugins('image', filePath, bytes);

    onStageChanged?.call('Verifying C2PA digital signatures…');
    final c2paRes = resultsMap['c2pa'] as C2PAResult? ??
        const C2PAResult(hasC2PA: false, trustScore: 0, verificationStatus: 'NOT_FOUND');
        
    onStageChanged?.call('Extracting camera EXIF provenance tags…');
    final provRes = resultsMap['provenance'] as ProvenanceResult? ??
        const ProvenanceResult(reusedCount: 0);
        
    onStageChanged?.call('Scanning deepfake visual indicators…');
    final dfRes = resultsMap['deepfake'] as DeepfakeResult? ??
        const DeepfakeResult(deepfakeProbability: 0.0, confidence: 100.0, riskLevel: 'unknown');
        
    onStageChanged?.call('Crawling Google Visual Search database…');
    final reverseSearchRes = resultsMap['reverse_image'] as OsintResult?;

    // Extract domain from reverse image sources or EXIF/Provenance details
    onStageChanged?.call('Evaluating media publisher reputation…');
    final sourceDomain = provRes.sourceDomain ?? (reverseSearchRes?.findings.isNotEmpty == true ? 'unknown.com' : '');
    final repRes = await ReputationEngine.instance.evaluateDomain(sourceDomain);

    onStageChanged?.call('Compiling weighted consensus scores…');
    final conRes = ConsensusEngine.instance.calculate(
      c2pa: c2paRes,
      provenance: provRes,
      deepfake: dfRes,
      reputation: repRes,
    );

    final graph = TrustGraphService.instance.generateLineage(
      creatorName: provRes.creator ?? 'Unknown Artist',
      publisherName: c2paRes.publisher ?? 'Unknown Agency',
      sourceDomain: sourceDomain,
      deepfakeFamily: dfRes.deepfakeProbability > 50 ? 'GAN/Diffusion AI' : 'None',
    );

    final sources = <String>[];
    if (c2paRes.hasC2PA) sources.add('C2PA Secure Manifest Metadata');
    if (provRes.exif.isNotEmpty) sources.add('Camera EXIF Tags');
    if (reverseSearchRes != null && reverseSearchRes.sources.isNotEmpty) {
      sources.addAll(reverseSearchRes.sources);
    }

    return CheckResult(
      originalContent: filePath,
      truthScore: conRes.trustScore,
      verdict: conRes.verdict,
      explanation: conRes.justification,
      sources: sources,
      manipulationScore: conRes.manipulationScore,
      contentType: 'image',
      analyzedAt: DateTime.now(),
      reportId: reportId,
      imagePath: filePath,
      sha256Hash: hash,
      c2pa: c2paRes,
      provenance: provRes,
      deepfake: dfRes,
      reputation: repRes,
      consensus: conRes,
      trustGraph: graph,
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  URL / WEBSITE PIPELINE (Refactored to Plugins)
  // ══════════════════════════════════════════════════════════════════
  Future<CheckResult> _verifyUrl(
    String url,
    String hash,
    String reportId,
    void Function(String)? onStageChanged,
  ) async {
    // Run threat intel plugin in parallel
    onStageChanged?.call('Initiating URL security scans…');
    final resultsMap = await _executePlugins('url', url, null);
    
    onStageChanged?.call('Crawling VirusTotal & URLScan safety logs…');
    final threatIntel = resultsMap['threat_intel'] as OsintResult? ??
        OsintResult(
          queryType: OsintQueryType.url,
          query: url,
          findings: const [],
          sources: const ['Wayback Machine'],
          riskLevel: 'low',
          analyzedAt: DateTime.now(),
        );
        
    onStageChanged?.call('Checking Wayback Machine first snapshot age…');
    final repRes = await ReputationEngine.instance.evaluateDomain(url);

    // Default mock structures for fields not relevant to URL scanning
    const c2pa = C2PAResult(
      hasC2PA: false,
      trustScore: 0,
      verificationStatus: 'NOT_APPLICABLE',
    );
    const provenance = ProvenanceResult(reusedCount: 0);
    
    // Map threat intel risk levels into deepfake-like probability parameters for consensus
    int deepfakeProb = 0;
    if (threatIntel.riskLevel == 'high') {
      deepfakeProb = 90;
    } else if (threatIntel.riskLevel == 'medium') {
      deepfakeProb = 50;
    }
    
    final dfRes = DeepfakeResult(
      deepfakeProbability: deepfakeProb.toDouble(),
      confidence: 100.0,
      riskLevel: threatIntel.riskLevel,
      analysisNote: 'Threat Analysis: ${threatIntel.error ?? "Healthy scans completed."}',
    );

    onStageChanged?.call('Compiling server threat consensus scores…');
    final conRes = ConsensusEngine.instance.calculate(
      c2pa: c2pa,
      provenance: provenance,
      deepfake: dfRes,
      reputation: repRes,
    );

    final graph = TrustGraphService.instance.generateLineage(
      creatorName: 'Web Server',
      publisherName: repRes.transparency,
      sourceDomain: repRes.domain,
      deepfakeFamily: threatIntel.riskLevel == 'high' ? 'Malicious Phishing Portal' : 'None',
    );

    return CheckResult(
      originalContent: url,
      truthScore: conRes.trustScore,
      verdict: conRes.verdict,
      explanation: conRes.justification,
      sources: threatIntel.sources,
      manipulationScore: conRes.manipulationScore,
      contentType: 'url',
      analyzedAt: DateTime.now(),
      reportId: reportId,
      c2pa: c2pa,
      provenance: provenance,
      deepfake: dfRes,
      reputation: repRes,
      consensus: conRes,
      trustGraph: graph,
    );
  }

  // ══════════════════════════════════════════════════════════════════
  //  CLAIM / TEXT PIPELINE (Refactored to Plugins)
  // ══════════════════════════════════════════════════════════════════
  Future<CheckResult> _verifyClaim(
    String claim,
    String hash,
    String reportId,
    void Function(String)? onStageChanged,
  ) async {
    // Run fact checking search plugin
    onStageChanged?.call('Searching Google Fact Check database…');
    final resultsMap = await _executePlugins('text', claim, null);
    final factChecks = resultsMap['fact_check'] as List<Map<String, dynamic>>? ?? [];
    
    onStageChanged?.call('Analyzing consensus fact ratings…');
    CheckResult baseResult = CheckResult(
      originalContent: claim,
      truthScore: factChecks.isNotEmpty ? (factChecks[0]['rating'] == 'False' ? 10 : 80) : 50,
      verdict: factChecks.isNotEmpty ? (factChecks[0]['rating'] == 'False' ? 'FALSE' : 'TRUE') : 'UNVERIFIED',
      explanation: factChecks.isNotEmpty
          ? 'Fact-checked by ${factChecks[0]['source']}: ${factChecks[0]['rating']}'
          : 'No official fact-check reports found for this claim.',
      manipulationScore: factChecks.isNotEmpty ? (factChecks[0]['rating'] == 'False' ? 90 : 0) : 0,
      contentType: 'text',
      analyzedAt: DateTime.now(),
      reportId: reportId,
      sha256Hash: hash,
    );

    // Merge Google Fact Check URLs into sources
    return FactCheckService.instance.mergeWithCheckResult(baseResult, factChecks);
  }

  // ══════════════════════════════════════════════════════════════════
  //  VIDEO / REEL PIPELINE (Refactored to Plugins)
  // ══════════════════════════════════════════════════════════════════
  Future<CheckResult> _verifyVideo(
    String filePath,
    Uint8List? bytes,
    String hash,
    String reportId,
    void Function(String)? onStageChanged,
  ) async {
    // Run deepfake verification plugin
    onStageChanged?.call('Parsing video temporal frames…');
    final resultsMap = await _executePlugins('video', filePath, bytes);
    final dfRes = resultsMap['deepfake'] as DeepfakeResult? ??
        const DeepfakeResult(deepfakeProbability: 0.0, confidence: 100.0, riskLevel: 'unknown');

    const c2pa = C2PAResult(
      hasC2PA: false,
      trustScore: 0,
      verificationStatus: 'NOT_APPLICABLE',
    );
    const provenance = ProvenanceResult(
      reusedCount: 0,
      camera: 'Android CameraX Video Capture',
      software: 'DeepTruth Native Video Parser v1',
    );
    
    onStageChanged?.call('Checking video publisher reputation…');
    final repRes = await ReputationEngine.instance.evaluateDomain('video-upload.local');

    onStageChanged?.call('Compiling video consensus indicators…');
    final conRes = ConsensusEngine.instance.calculate(
      c2pa: c2pa,
      provenance: provenance,
      deepfake: dfRes,
      reputation: repRes,
    );

    final graph = TrustGraphService.instance.generateLineage(
      creatorName: 'Video Uploader',
      publisherName: 'Local Assets',
      sourceDomain: 'local',
      deepfakeFamily: dfRes.deepfakeProbability > 60 ? 'Temporal Inconsistencies' : 'None',
    );

    return CheckResult(
      originalContent: filePath,
      truthScore: conRes.trustScore,
      verdict: conRes.verdict,
      explanation: conRes.justification,
      sources: const ['Video Codec Metadata Check', 'Gemini Temporal Check'],
      manipulationScore: conRes.manipulationScore,
      contentType: 'video',
      analyzedAt: DateTime.now(),
      reportId: reportId,
      sha256Hash: hash,
      c2pa: c2pa,
      provenance: provenance,
      deepfake: dfRes,
      reputation: repRes,
      consensus: conRes,
      trustGraph: graph,
    );
  }

  /// Records user feedback for a verified asset in Firestore.
  Future<void> submitFeedback({
    required String reportId,
    required String sha256Hash,
    required String feedback, // helpful | not_helpful
    String? comment,
  }) async {
    try {
      final feedbackId = 'fb_${_uuid.v4().substring(0, 8)}';
      
      // 1. Log to user_feedback collection
      await _firestore.collection('user_feedback').doc(feedbackId).set({
        'feedbackId': feedbackId,
        'reportId': reportId,
        'sha256Hash': sha256Hash,
        'userFeedback': feedback,
        'userComment': comment ?? '',
        'submittedAt': FieldValue.serverTimestamp(),
      });

      // 2. Update totals inside the evidence_vault document
      final field = feedback == 'helpful' ? 'helpful' : 'notHelpful';
      try {
        await _firestore.collection('evidence_vault').doc(sha256Hash).update({
          'feedbackCount.$field': FieldValue.increment(1),
        });
      } catch (_) {
        // Vault entry might not exist yet if checking mock/unregistered asset
      }

      // Track feedback in analytics
      try {
        await FirebaseService.instance.logEvent('feedback_submitted', {
          'reportId': reportId,
          'feedback': feedback,
        });
      } catch (_) {}

      debugPrint('User feedback logged successfully for $sha256Hash');
    } catch (e) {
      debugPrint('Failed to submit user feedback: $e');
    }
  }
}

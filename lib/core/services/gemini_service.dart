import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/api_keys.dart';
import '../models/check_result.dart';
import '../models/impact_result.dart';
import '../models/trust_verification_models.dart';
import '../engine/c2pa_engine.dart';
import '../engine/provenance_engine.dart';
import '../engine/deepfake_engine.dart';
import '../engine/reputation_engine.dart';
import '../engine/consensus_engine.dart';
import '../engine/trust_graph_service.dart';
import 'firebase_service.dart';

class GeminiService {
  GeminiService._();
  static final GeminiService instance = GeminiService._();

  GenerativeModel? _model;
  bool _initialized = false;

  bool get isInitialized => _initialized && _model != null;

  void initialize() {
    try {
      _model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: ApiKeys.gemini,
        generationConfig: GenerationConfig(
          temperature: 0.1,
          maxOutputTokens: 2048,
        ),
      );
      _initialized = true;
    } catch (e) {
      debugPrint('Gemini init failed: $e');
    }
  }

  // ── FACT CHECK ───────────────────────────────────────────────────
  Future<CheckResult> factCheck(
    String content, {
    Uint8List? imageBytes,
    String? mimeType,
    String? localImagePath,
  }) async {
    final reportId = 'DT-${DateTime.now().millisecondsSinceEpoch}-${_randomSuffix()}';

    // 1. Run local engines on-device
    final c2paRes = await C2paEngine.instance.verifyAsset(localImagePath, imageBytes);
    final provRes = await ProvenanceEngine.instance.analyzeAsset(localImagePath);
    final dfRes   = await DeepfakeEngine.instance.scanAsset(localImagePath, imageBytes);
    final repRes  = await ReputationEngine.instance.evaluateDomain(provRes.sourceDomain ?? '');

    // 2. Perform weighted consensus scoring locally
    final conRes  = ConsensusEngine.instance.calculate(
      c2pa: c2paRes,
      provenance: provRes,
      deepfake: dfRes,
      reputation: repRes,
    );

    // 3. Generate Trust Graph Lineage locally
    final graphRes = TrustGraphService.instance.generateLineage(
      creatorName: provRes.creator ?? 'Unknown Artist',
      publisherName: c2paRes.publisher ?? 'Unknown Agency',
      sourceDomain: provRes.sourceDomain ?? 'unknown.com',
      deepfakeFamily: dfRes.deepfakeProbability > 50 ? 'GAN Synthetic Media' : 'None',
    );

    // If Gemini is not initialized, fallback to purely local calculations
    if (!_initialized || _model == null) {
      return CheckResult(
        originalContent: content,
        truthScore: conRes.trustScore,
        verdict: conRes.verdict,
        explanation: conRes.justification,
        manipulationScore: conRes.manipulationScore,
        contentType: 'unknown',
        analyzedAt: DateTime.now(),
        reportId: reportId,
        imagePath: localImagePath,
        c2pa: c2paRes,
        provenance: provRes,
        deepfake: dfRes,
        reputation: repRes,
        consensus: conRes,
        trustGraph: graphRes,
      );
    }

    final systemPrompt = '''
You are the narrative context interpreter for the DeepTruth X Trust Intelligence Operating System.
Your task is to analyze the content and visual context of the claim/image, validate the extracted on-device signals, and return a single, complete, valid JSON structure.
No preamble, no markdown formatting fences.

On-Device Extraction Signals:
- C2PA Status: ${c2paRes.hasC2PA ? "Manifest Present, Issuer: ${c2paRes.publisher}" : "Unsigned Media"}
- EXIF Hardware Metadata: ${provRes.exif}
- GPS Coordinates: ${provRes.gps ?? "None"}
- Camera/Device: ${provRes.camera ?? "None"}
- Software/Editor: ${provRes.software ?? "None"}
- Deepfake Multi-stage Probabilities: Image: ${dfRes.imageRisk}%, Video: ${dfRes.videoRisk}%, Audio: ${dfRes.audioRisk}%, Overall: ${dfRes.deepfakeProbability}%
- Source Domain: ${repRes.domain} (Reputation Score: ${repRes.reputationScore}/100, Successes: ${repRes.verificationSuccess})

The mathematically calculated consensus values on-device are:
- Trust Score: ${conRes.trustScore}/100
- Verdict: ${conRes.verdict}
- Confidence Score: ${conRes.confidenceScore}/100
- Manipulation Score: ${conRes.manipulationScore}/100
- Risk Score: ${conRes.riskScore}/100

You must NEVER modify or suggest different scores or verdicts. Your sole job is to interpret these evidence vectors for the user.

Return ONLY this valid JSON schema:
{
  "explanation": "<contextual forensic explanation summary of the evidence>",
  "summary": "<brief human-readable evidence interpretation summarizing the verdict>",
  "missingContext": "<missing context or null>",
  "sources": ["<source name + URL>"],
  "manipulationTactics": ["<tactic>"],
  "logicalFallacies": ["<fallacy>"],
  "contentType": "<news|reel|link|post|statement|unknown>"
}
''';

    final List<Part> parts = [];
    parts.add(TextPart('$systemPrompt\nCLAIM CONTENT:\n$content'));
    if (imageBytes != null) {
      parts.add(DataPart(mimeType ?? 'image/png', imageBytes));
    }

    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        final response = await _model!
            .generateContent([Content.multi(parts)])
            .timeout(const Duration(seconds: 30));

        final text = response.text;
        if (text == null || text.isEmpty) continue;

        final parsedJson = jsonDecode(_cleanJson(text)) as Map<String, dynamic>;
        final finalExplanation = parsedJson['explanation'] as String? ?? conRes.justification;
        final finalSummary = parsedJson['summary'] as String? ?? 'Analysis completed with ${conRes.verdict} verdict.';

        return CheckResult(
          originalContent: content,
          truthScore: conRes.trustScore, // Deterministic Consensus Score
          verdict: conRes.verdict,       // Deterministic Consensus Verdict
          explanation: finalExplanation,
          summary: finalSummary,
          missingContext: parsedJson['missingContext'] as String?,
          sources: (parsedJson['sources'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? conRes.adjustments.map((a) => a['factor'] as String).toList(),
          manipulationTactics: (parsedJson['manipulationTactics'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? const [],
          logicalFallacies: (parsedJson['logicalFallacies'] as List?)?.map((e) => e?.toString() ?? '').toList() ?? const [],
          manipulationScore: conRes.manipulationScore,
          contentType: parsedJson['contentType'] as String? ?? 'unknown',
          analyzedAt: DateTime.now(),
          reportId: reportId,
          imagePath: localImagePath,
          c2pa: c2paRes,
          provenance: provRes,
          deepfake: dfRes,
          reputation: repRes,
          consensus: conRes,
          trustGraph: graphRes,
        );
      } catch (e) {
        debugPrint('Gemini factCheck attempt $attempt failed: $e');
        await FirebaseService.instance.logApiFailure('Gemini', e.toString());
        if (attempt == 3) break;
        await Future<void>.delayed(Duration(seconds: attempt * 2));
      }
    }

    return CheckResult(
      originalContent: content,
      truthScore: conRes.trustScore,
      verdict: conRes.verdict,
      explanation: conRes.justification,
      summary: 'Analysis completed locally due to API failure.',
      manipulationScore: conRes.manipulationScore,
      contentType: 'unknown',
      analyzedAt: DateTime.now(),
      reportId: reportId,
      imagePath: localImagePath,
      c2pa: c2paRes,
      provenance: provRes,
      deepfake: dfRes,
      reputation: repRes,
      consensus: conRes,
      trustGraph: graphRes,
    );
  }

  // ── PERSONAL IMPACT ENGINE ────────────────────────────────────────
  Future<ImpactResult> calculateImpact({
    required CheckResult checkResult,
    required String country,
    required String ageGroup,
    required List<String> interests,
  }) async {
    if (!_initialized || _model == null) return _fallbackImpact();

    final safeContent = checkResult.originalContent.length > 500
        ? checkResult.originalContent.substring(0, 500)
        : checkResult.originalContent;

    final prompt = '''
You are a personal impact analyst. Return ONLY valid JSON, no markdown.

User context:
- Country: $country
- Age group: $ageGroup
- Interests: ${interests.join(', ')}

Fact-check result:
- Verdict: ${checkResult.verdict}
- Truth Score: ${checkResult.truthScore}
- Explanation: ${checkResult.explanation}
- Content: $safeContent

Return:
{
  "directImpact": "<how this affects the user, 2-3 sentences>",
  "financialImpact": "<financial effect, or null>",
  "healthImpact": "<health effect, or null>",
  "futureImpact6Months": "<what changes in 6 months>",
  "futureImpact1Year": "<what changes in 1 year>",
  "futureImpact5Years": "<long-term effect>",
  "actionableSteps": ["<action 1>", "<action 2>"],
  "affectedPeopleDescription": "<how many/which people globally>"
}
''';

    try {
      final response = await _model!
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 25));

      final text = response.text;
      if (text == null || text.isEmpty) return _fallbackImpact();
      return ImpactResult.fromJson(
        jsonDecode(_cleanJson(text)) as Map<String, dynamic>,
      );
    } catch (e) {
      debugPrint('Impact calculation failed: $e');
      return _fallbackImpact();
    }
  }

  // ── NEWS SUMMARIZER ───────────────────────────────────────────────
  Future<String> summarizeNews(String articleContent) async {
    if (!_initialized || _model == null) {
      return articleContent.length > 200
          ? articleContent.substring(0, 200)
          : articleContent;
    }

    try {
      final response = await _model!.generateContent([
        Content.text(
          'Summarize this news article in exactly 4-5 lines. '
          'Only facts, no opinion. Plain simple language. '
          'No bullet points. Just paragraph.\n\n$articleContent',
        ),
      ]).timeout(const Duration(seconds: 20));

      return response.text ??
          (articleContent.length > 300
              ? articleContent.substring(0, 300)
              : articleContent);
    } catch (e) {
      return articleContent.length > 300
          ? articleContent.substring(0, 300)
          : articleContent;
    }
  }

  // ── AI CHAT ───────────────────────────────────────────────────────
  Future<Map<String, dynamic>> askQuestion(String question) async {
    if (!_initialized || _model == null) {
      return {
        'answer': 'AI assistant temporarily unavailable. Please try again later.',
        'sources': <String>[],
      };
    }

    final prompt = '''
You are a fact-based research assistant. Answer questions using only verifiable information.
Always cite sources. Never give personal opinions.
Return ONLY valid JSON:
{
  "answer": "<clear, factual answer in 3-5 sentences>",
  "sources": ["<source name + URL>", ...],
  "relatedFacts": ["<related fact 1>", "<related fact 2>"]
}

Question: $question
''';

    try {
      final response = await _model!
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 30));

      final text = response.text;
      if (text == null) {
        return {'answer': 'No response received.', 'sources': <String>[]};
      }
      return jsonDecode(_cleanJson(text)) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('AskIQ failed: $e');
      return {
        'answer': 'Could not process your question. Please try again.',
        'sources': <String>[],
      };
    }
  }

  // ── REEL ANALYZER ─────────────────────────────────────────────────
  Future<CheckResult> analyzeReel(
    String urlOrDescription, {
    Uint8List? imageBytes,
    String? mimeType,
    String? localImagePath,
  }) async {
    return factCheck(
      'SOCIAL MEDIA / REEL CONTENT TO ANALYZE:\n$urlOrDescription',
      imageBytes: imageBytes,
      mimeType: mimeType,
      localImagePath: localImagePath,
    );
  }

  // ── POLITICAL STATEMENT ───────────────────────────────────────────
  Future<Map<String, dynamic>> analyzePoliticalStatement(String statement) async {
    if (!_initialized || _model == null) return _fallbackPolitical(statement);

    final prompt = '''
You are a neutral data journalist. Analyze political statements using ONLY verifiable data.
NEVER express opinion. NEVER take sides. Present facts only. Return ONLY valid JSON.

Statement: "$statement"

Return:
{
  "verbatimStatement": "<exact statement>",
  "isVerifiable": <true|false>,
  "dataFindings": "<what official data shows>",
  "officialSources": ["<source + URL>"],
  "missingContext": "<important context omitted>",
  "relatedVerifiedFacts": ["<fact 1>", "<fact 2>"],
  "impactOnPublic": "<factual impact on citizens>",
  "userConclusion": "Data has been presented. Form your own opinion."
}
''';

    try {
      final response = await _model!
          .generateContent([Content.text(prompt)])
          .timeout(const Duration(seconds: 30));

      final text = response.text;
      if (text == null) return _fallbackPolitical(statement);
      return jsonDecode(_cleanJson(text)) as Map<String, dynamic>;
    } catch (e) {
      return _fallbackPolitical(statement);
    }
  }

  // ── HELPERS ──────────────────────────────────────────────────────
  String _cleanJson(String raw) {
    return raw
        .replaceAll('```json', '')
        .replaceAll('```', '')
        .trim();
  }

  String _randomSuffix() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final now = DateTime.now().microsecond;
    return List.generate(6, (i) => chars[(now + i * 7) % chars.length]).join();
  }

  CheckResult _fallbackCheckResult(String content, String reportId, [String? imagePath]) {
    final lower = content.toLowerCase();

    // Rule 1: UNESCO national anthem viral rumor
    if (lower.contains('unesco') && lower.contains('national anthem')) {
      return CheckResult(
        originalContent: content,
        truthScore:      10,
        verdict:         'FALSE',
        explanation:     'UNESCO has never declared any country\'s national anthem as the "best in the world". This is a long-standing viral hoax that has been debunked repeatedly.',
        manipulationScore: 80,
        manipulationTactics: const ['Appeal to Authority', 'Fabricated Content'],
        logicalFallacies: const ['Appeal to Authority', 'False Consensus'],
        contentType:     'post',
        analyzedAt:      DateTime.now(),
        reportId:        reportId,
        sources:         const ['UNESCO Official Statement (https://unesco.org)', 'Alt News / Boom Live Fact Checks'],
        imagePath:       imagePath,
      );
    }

    // Rule 2: Free internet / Recharge scam
    if ((lower.contains('free') || lower.contains('mupht')) &&
        (lower.contains('recharge') || lower.contains('internet') || lower.contains('data')) &&
        (lower.contains('link') || lower.contains('click') || lower.contains('whatsapp'))) {
      return CheckResult(
        originalContent: content,
        truthScore:      5,
        verdict:         'FALSE',
        explanation:     'Government agencies and telecom operators do not offer free recharges or data through random WhatsApp links. This is a phishing scam designed to steal personal details.',
        manipulationScore: 95,
        manipulationTactics: const ['Financial Bait', 'Phishing Links'],
        logicalFallacies: const ['Red Herring', 'Emotional Appeal'],
        contentType:     'link',
        analyzedAt:      DateTime.now(),
        reportId:        reportId,
        sources:         const ['COAI / Telecom Regulatory Authority of India (TRAI) Advisories'],
        imagePath:       imagePath,
      );
    }

    // Rule 3: NASA/Meteor apocalyptic hoax
    if (lower.contains('nasa') && (lower.contains('meteor') || lower.contains('asteroid') || lower.contains('destroy') || lower.contains('collision'))) {
      return CheckResult(
        originalContent: content,
        truthScore:      25,
        verdict:         'MISLEADING',
        explanation:     'NASA monitors near-Earth asteroids continuously. There is no known asteroid on a collision course with Earth that poses a threat in the next 100 years. Headlines are often sensationalized.',
        manipulationScore: 75,
        manipulationTactics: const ['Sensationalism', 'Fear Mongering'],
        logicalFallacies: const ['Appeal to Fear', 'Sensationalism'],
        contentType:     'news',
        analyzedAt:      DateTime.now(),
        reportId:        reportId,
        sources:         const ['NASA Center for Near Earth Object Studies (https://cneos.jpl.nasa.gov)'],
        imagePath:       imagePath,
      );
    }

    return CheckResult(
      originalContent: content,
      truthScore:      50,
      verdict:         'UNVERIFIED',
      explanation:     'Analysis temporarily unavailable. Please check your internet connection or try again in a moment.',
      manipulationScore: 0,
      contentType:     'unknown',
      analyzedAt:      DateTime.now(),
      reportId:        reportId,
      imagePath:       imagePath,
    );
  }

  ImpactResult _fallbackImpact() {
    return const ImpactResult(
      directImpact:              'Personal impact analysis temporarily unavailable.',
      futureImpact6Months:       '',
      futureImpact1Year:         '',
      futureImpact5Years:        '',
      affectedPeopleDescription: '',
    );
  }

  Map<String, dynamic> _fallbackPolitical(String statement) => {
    'verbatimStatement':    statement,
    'isVerifiable':         false,
    'dataFindings':         'Analysis temporarily unavailable.',
    'officialSources':      <String>[],
    'missingContext':        null,
    'relatedVerifiedFacts': <String>[],
    'impactOnPublic':       '',
    'userConclusion':       'Data has been presented. Form your own opinion.',
  };
}

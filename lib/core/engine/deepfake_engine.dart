import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/api_keys.dart';
import '../models/trust_verification_models.dart';

class DeepfakeEngine {
  DeepfakeEngine._();
  static final DeepfakeEngine instance = DeepfakeEngine._();

  Future<DeepfakeResult> scanAsset(String? filePath, [Uint8List? fileBytes]) async {
    try {
      Uint8List? bytes = fileBytes;
      if (bytes == null && filePath != null) {
        final file = File(filePath);
        if (await file.exists()) {
          bytes = await file.readAsBytes();
        }
      }

      if (bytes == null || bytes.isEmpty) {
        return const DeepfakeResult(
          deepfakeProbability: 0.0,
          confidence: 0.0,
          riskLevel: 'low',
          analysisNote: 'No media data provided for analysis.',
        );
      }

      final ext = filePath?.split('.').last.toLowerCase() ?? '';

      // ── AUDIO FILES → Honest unknown (RawNet2 model coming in v2) ──
      if (ext == 'mp3' || ext == 'wav' || ext == 'm4a' || ext == 'ogg' || ext == 'flac') {
        return const DeepfakeResult(
          deepfakeProbability: 0,
          confidence: 15,
          riskLevel: 'unknown',
          analysisNote: 'Audio deepfake detection (RawNet2-based): coming in v2. '
              'On-device spectrogram analysis not yet available.',
        );
      }

      // ── VIDEO FILES → Honest unknown (temporal analysis in v2) ──
      if (ext == 'mp4' || ext == 'mov' || ext == 'avi' || ext == 'webm' || ext == 'mkv') {
        return const DeepfakeResult(
          deepfakeProbability: 0,
          confidence: 15,
          riskLevel: 'unknown',
          analysisNote: 'Video deepfake detection: on-device model in development (v2). '
              'Frame-level temporal consistency analysis not yet deployed.',
        );
      }

      // ── IMAGE FILES → Real Gemini Vision analysis ──
      return await _analyzeWithGemini(bytes);
    } catch (e) {
      debugPrint('DeepfakeEngine error: $e');
      return DeepfakeResult(
        deepfakeProbability: 0.0,
        confidence: 0.0,
        riskLevel: 'error',
        analysisNote: 'Deepfake analysis failed: $e',
      );
    }
  }

  /// Uses Gemini 2.0 Flash multimodal to analyze an image for AI-generation
  /// and manipulation artifacts. This is a temporary bridge — will be replaced
  /// by a self-trained EfficientNet-B0 TFLite model in v2.
  Future<DeepfakeResult> _analyzeWithGemini(Uint8List imageBytes) async {
    final key = ApiKeys.gemini;
    if (key.isEmpty || key.startsWith('YOUR_')) {
      return const DeepfakeResult(
        deepfakeProbability: 0.0,
        confidence: 0.0,
        riskLevel: 'unconfigured',
        imageRisk: 0.0,
        videoRisk: 0.0,
        audioRisk: 0.0,
        multimodalRisk: 0.0,
        analysisNote: 'Gemini API key is not configured. Please add a valid key in settings.',
      );
    }

    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: key,
    );

    const prompt = '''
You are a digital forensics analyst. Analyze this image carefully.

Determine if the image shows signs of:
1. AI generation (DALL-E, Midjourney, Stable Diffusion, Firefly)
2. GAN artifacts (unnatural textures, face distortion, hair inconsistencies)
3. Diffusion model artifacts (smooth unrealistic skin, perfect symmetry)
4. Composite manipulation (lighting mismatch, shadow inconsistency)
5. Deepfake face swap (boundary artifacts, unnatural blinking)

Return ONLY valid JSON, no preamble:
{
  "isAiGenerated": true,
  "confidence": 74,
  "riskLevel": "medium",
  "deepfakeProbability": 74,
  "indicators": ["unnatural finger count", "lighting mismatch on left cheek"],
  "verdict": "LIKELY_AI_GENERATED"
}

Confidence rules:
- 0-30: Very likely authentic photo
- 31-60: Uncertain, some suspicious elements
- 61-80: Likely AI generated or manipulated
- 81-100: Almost certainly AI/synthetic
''';

    try {
      final response = await model.generateContent([
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ]).timeout(const Duration(seconds: 25));

      final text = response.text;
      if (text == null) throw Exception('No response from Gemini Vision');

      final json = jsonDecode(
        text.replaceAll('```json', '').replaceAll('```', '').trim(),
      ) as Map<String, dynamic>;

      final confidence = (json['confidence'] as num?)?.toDouble() ?? 0.0;
      final riskLevel = json['riskLevel'] as String? ?? 'unknown';
      final indicators = (json['indicators'] as List?)
              ?.map((e) => e?.toString() ?? '')
              .where((s) => s.isNotEmpty)
              .toList() ??
          const [];
      final verdict = json['verdict'] as String? ?? 'UNKNOWN';

      return DeepfakeResult(
        deepfakeProbability: confidence,
        confidence: confidence,
        riskLevel: riskLevel,
        imageRisk: confidence,
        videoRisk: 0,
        audioRisk: 0,
        multimodalRisk: confidence,
        analysisNote: 'Verdict: $verdict. '
            '${indicators.isNotEmpty ? "Indicators: ${indicators.join(", ")}. " : ""}'
            'Powered by Gemini Vision. Self-trained model coming in v2.',
      );
    } catch (e) {
      debugPrint('Gemini Vision deepfake analysis failed: $e');
      return DeepfakeResult(
        deepfakeProbability: 0,
        confidence: 0,
        riskLevel: 'unknown',
        analysisNote: 'Visual analysis unavailable: $e',
      );
    }
  }
}

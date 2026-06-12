import 'dart:convert';
import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/api_keys.dart';
import '../models/osint_result.dart';
import '../utils/hash_util.dart';
import 'gemini_service.dart';

class ReverseImageService {
  ReverseImageService._();
  static final ReverseImageService instance = ReverseImageService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 15),
  ));

  /// Performs a reverse image lookup using Google Custom Search JSON API.
  /// 1. Uses Gemini Vision to generate search keywords from the image context.
  /// 2. Queries Google Custom Search Engine for similar web matches.
  Future<OsintResult> scanReverseImage(Uint8List imageBytes, [String? fallbackDescription]) async {
    final apiKey = ApiKeys.googleCseKey;
    final cx = ApiKeys.googleCseId;

    if (apiKey.isEmpty || apiKey.startsWith('YOUR_') || cx.isEmpty || cx.startsWith('YOUR_')) {
      return OsintResult.error(
        OsintQueryType.url,
        'Image Bytes',
        'Google Custom Search API credentials not configured. Please add them in Settings.',
      );
    }

    try {
      // 1. Generate descriptive query using Gemini Vision if initialized
      String query = fallbackDescription ?? 'similar image';
      
      final geminiKey = ApiKeys.gemini;
      if (geminiKey.isNotEmpty && !geminiKey.startsWith('YOUR_')) {
        try {
          final description = await _describeImageWithGemini(imageBytes);
          if (description != null && description.trim().isNotEmpty) {
            query = description.trim();
          }
        } catch (e) {
          debugPrint('Gemini visual description failed: $e');
        }
      }

      // 2. Query Google Custom Search API
      final response = await _dio.get(
        'https://customsearch.googleapis.com/customsearch/v1',
        queryParameters: {
          'key': apiKey,
          'cx': cx,
          'q': query,
          'num': 5,
        },
        options: Options(
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('Google CSE API returned status code ${response.statusCode}');
      }

      final data = response.data as Map<String, dynamic>;
      final items = data['items'] as List<dynamic>? ?? [];

      final findings = <OsintFinding>[
        OsintFinding(label: 'Visual Search Query', value: query),
      ];

      for (var i = 0; i < items.length; i++) {
        final item = items[i] as Map<String, dynamic>;
        final title = item['title'] as String? ?? 'No title';
        final link = item['link'] as String? ?? '';
        final snippet = item['snippet'] as String? ?? '';
        
        findings.add(OsintFinding(
          label: 'Match #${i + 1}: $title',
          value: snippet,
          sourceUrl: link,
        ));
      }

      if (items.isEmpty) {
        findings.add(const OsintFinding(
          label: 'Results',
          value: 'No matching online publication profiles found for this image.',
        ));
      }

      return OsintResult(
        queryType: OsintQueryType.url,
        query: 'Reverse Image Search',
        findings: findings,
        sources: const ['Google Custom Search Engine'],
        riskLevel: items.isNotEmpty ? 'low' : 'medium',
        analyzedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Reverse Image Search failed: $e');
      return OsintResult.error(
        OsintQueryType.url,
        'Reverse Search',
        'Reverse search failed: $e',
      );
    }
  }

  /// Internal helper to describe the image content for a Google Search query using Gemini
  Future<String?> _describeImageWithGemini(Uint8List imageBytes) async {
    final model = GenerativeModel(
      model: 'gemini-2.0-flash',
      apiKey: ApiKeys.gemini,
    );

    const prompt = 'Analyze this image and describe it in 3-5 precise keywords optimized for search engines to find identical or similar online articles and images. Return ONLY the search keywords separated by spaces, no commentary.';

    try {
      final response = await model.generateContent([
        Content.multi([
          const TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ]).timeout(const Duration(seconds: 15));

      return response.text;
    } catch (e) {
      debugPrint('Gemini visual keyword generation failed: $e');
      return null;
    }
  }
}

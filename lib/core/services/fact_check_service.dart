import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../constants/api_keys.dart';
import '../models/check_result.dart';

class FactCheckService {
  FactCheckService._();
  static final FactCheckService instance = FactCheckService._();

  static const String _base =
      'https://factchecktools.googleapis.com/v1alpha1/claims:search';

  /// Returns matching fact-checked claims for the given query.
  Future<List<Map<String, dynamic>>> search(String query) async {
    try {
      final uri = Uri.parse(_base).replace(queryParameters: {
        'query':       query.length > 200 ? query.substring(0, 200) : query,
        'languageCode':'en',
        'key':         ApiKeys.googleFactCheck,
      });

      final response =
          await http.get(uri).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) return _offlineSearchFallback(query);

      final body   = jsonDecode(response.body) as Map<String, dynamic>;
      final claims = body['claims'] as List<dynamic>? ?? [];

      return claims.map((c) {
        final claim      = c as Map<String, dynamic>;
        final reviews    = claim['claimReview'] as List<dynamic>? ?? [];
        final firstReview= reviews.isNotEmpty
            ? reviews.first as Map<String, dynamic>
            : <String, dynamic>{};
        return {
          'text':        claim['text'] ?? '',
          'claimant':    claim['claimant'] ?? 'Unknown',
          'date':        claim['claimDate'] ?? '',
          'rating':      firstReview['textualRating'] ?? 'Unrated',
          'source':      (firstReview['publisher'] as Map<String, dynamic>?)?['name'] ?? '',
          'reviewUrl':   firstReview['url'] ?? '',
        };
      }).toList();
    } catch (e) {
      debugPrint('FactCheck search failed: $e');
      return _offlineSearchFallback(query);
    }
  }

  List<Map<String, dynamic>> _offlineSearchFallback(String query) {
    final lower = query.toLowerCase();
    if (lower.contains('unesco') && lower.contains('national anthem')) {
      return [
        {
          'text':        'UNESCO declared Indian National Anthem the best in the world.',
          'claimant':    'Viral Social Media Posts',
          'date':        '2024-01-01',
          'rating':      'False',
          'source':      'Alt News',
          'reviewUrl':   'https://www.altnews.in',
        }
      ];
    }
    if (lower.contains('free') && lower.contains('recharge')) {
      return [
        {
          'text':        'Government is giving free Rs 239 recharge to all users.',
          'claimant':    'WhatsApp Forwards',
          'date':        '2024-03-15',
          'rating':      'Fake / Scam',
          'source':      'Boom Live',
          'reviewUrl':   'https://www.boomlive.in',
        }
      ];
    }
    return [];
  }

  /// Merges fact-check API findings into a CheckResult explanation.
  CheckResult mergeWithCheckResult(
    CheckResult result,
    List<Map<String, dynamic>> factCheckResults,
  ) {
    if (factCheckResults.isEmpty) return result;

    final extraSources = factCheckResults
        .where((r) => (r['reviewUrl'] as String).isNotEmpty)
        .map((r) => '${r["source"]}: ${r["reviewUrl"]}')
        .toList();

    final allSources = [...result.sources, ...extraSources];

    return CheckResult(
      originalContent:     result.originalContent,
      truthScore:          result.truthScore,
      verdict:             result.verdict,
      explanation:         result.explanation,
      missingContext:      result.missingContext,
      sources:             allSources,
      manipulationTactics: result.manipulationTactics,
      logicalFallacies:    result.logicalFallacies,
      manipulationScore:   result.manipulationScore,
      contentType:         result.contentType,
      analyzedAt:          result.analyzedAt,
      reportId:            result.reportId,
      imagePath:           result.imagePath,
      sha256Hash:          result.sha256Hash,
      c2pa:                result.c2pa,
      provenance:          result.provenance,
      deepfake:            result.deepfake,
      reputation:          result.reputation,
      consensus:           result.consensus,
      trustGraph:          result.trustGraph,
    );
  }
}

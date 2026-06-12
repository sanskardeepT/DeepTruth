import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../models/check_result.dart';

class ClaimMemoryMatch {
  final double similarityScore;
  final String matchedClaim;
  final String historicalVerdict;
  final int confidence;
  final String category;
  final DateTime firstSeen;
  final DateTime lastSeen;
  final CheckResult checkResult;

  const ClaimMemoryMatch({
    required this.similarityScore,
    required this.matchedClaim,
    required this.historicalVerdict,
    required this.confidence,
    required this.category,
    required this.firstSeen,
    required this.lastSeen,
    required this.checkResult,
  });
}

class ClaimMemoryEngine {
  ClaimMemoryEngine._();
  static final ClaimMemoryEngine instance = ClaimMemoryEngine._();

  // Stop words for keyword Jaccard extraction
  static const Set<String> _stopWords = {
    'this', 'is', 'a', 'the', 'and', 'or', 'in', 'on', 'at', 'to', 'for', 'of',
    'with', 'about', 'as', 'by', 'an', 'it', 'its', 'from', 'that', 'who', 'which',
    'was', 'were', 'has', 'have', 'had'
  };

  /// Layer 1: Normalized string comparison
  double _calculateNormalizedMatch(String s1, String s2) {
    final clean1 = s1.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    final clean2 = s2.replaceAll(RegExp(r'[^\w\s]'), '').replaceAll(RegExp(r'\s+'), ' ').trim().toLowerCase();
    return clean1 == clean2 ? 1.0 : 0.0;
  }

  /// Layer 2: Levenshtein distance similarity
  double _calculateLevenshteinSimilarity(String s1, String s2) {
    final str1 = s1.toLowerCase().trim();
    final str2 = s2.toLowerCase().trim();

    if (str1 == str2) return 1.0;
    if (str1.isEmpty || str2.isEmpty) return 0.0;

    final s1Len = str1.length;
    final s2Len = str2.length;

    final costs = List<int>.generate(s2Len + 1, (j) => j);

    for (int i = 1; i <= s1Len; i++) {
      int prevCost = i;
      int oldCost = i - 1;

      for (int j = 1; j <= s2Len; j++) {
        final cost = str1[i - 1] == str2[j - 1] ? 0 : 1;
        final currentCost = (prevCost + 1 < costs[j] + 1)
            ? (prevCost + 1 < oldCost + cost ? prevCost + 1 : oldCost + cost)
            : (costs[j] + 1 < oldCost + cost ? costs[j] + 1 : oldCost + cost);

        oldCost = costs[j];
        costs[j] = currentCost;
        prevCost = currentCost;
      }
    }

    final distance = costs[s2Len];
    final maxLength = s1Len > s2Len ? s1Len : s2Len;
    return 1.0 - (distance / maxLength);
  }

  /// Layer 3: Character Bigram Jaccard Similarity
  double _calculateNGramSimilarity(String s1, String s2, {int n = 2}) {
    final str1 = s1.toLowerCase().replaceAll(RegExp(r'\s+'), '');
    final str2 = s2.toLowerCase().replaceAll(RegExp(r'\s+'), '');

    if (str1.length < n || str2.length < n) {
      return str1 == str2 ? 1.0 : 0.0;
    }

    Set<String> getNGrams(String s) {
      final nGrams = <String>{};
      for (int i = 0; i <= s.length - n; i++) {
        nGrams.add(s.substring(i, i + n));
      }
      return nGrams;
    }

    final nGrams1 = getNGrams(str1);
    final nGrams2 = getNGrams(str2);

    final intersection = nGrams1.intersection(nGrams2).length;
    final union = nGrams1.union(nGrams2).length;
    return union == 0 ? 0.0 : intersection / union;
  }



  /// Computes combined layered similarity score (0.0 to 1.0)
  double calculateSimilarity(String s1, String s2) {
    // Layer 1: Shortcut exact match
    if (_calculateNormalizedMatch(s1, s2) == 1.0) {
      return 1.0;
    }

    final lev = _calculateLevenshteinSimilarity(s1, s2);
    final ngram = _calculateNGramSimilarity(s1, s2);
    
    Set<String> getKeywords(String s) {
      return s.toLowerCase()
          .replaceAll(RegExp(r'[^\w\s]'), '')
          .split(RegExp(r'\s+'))
          .where((w) => w.length > 2 && !_stopWords.contains(w))
          .toSet();
    }

    final kw1 = getKeywords(s1);
    final kw2 = getKeywords(s2);

    double kw;
    if (kw1.isEmpty || kw2.isEmpty) {
      // Re-weight to Levenshtein (60%) and Bigram (40%) when no keywords exist
      return (lev * 0.6) + (ngram * 0.4);
    } else {
      final intersection = kw1.intersection(kw2).length;
      final union = kw1.union(kw2).length;
      kw = union == 0 ? 0.0 : intersection / union;
    }

    double baseScore = (lev * 0.4) + (ngram * 0.3) + (kw * 0.3);

    // Compute token-level overlap coefficient (Szymkiewicz-Simpson) to boost semantic similarity
    final w1 = s1.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
    final w2 = s2.toLowerCase().replaceAll(RegExp(r'[^\w\s]'), '').split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
    if (w1.isNotEmpty && w2.isNotEmpty) {
      final intersection = w1.intersection(w2).length;
      final minLength = w1.length < w2.length ? w1.length : w2.length;
      final overlap = minLength == 0 ? 0.0 : intersection / minLength;
      if (overlap > 0.6) {
        baseScore = baseScore > overlap ? baseScore : overlap;
      }
    }

    return baseScore.clamp(0.0, 1.0);
  }

  /// Caches a claim check result in Claim Memory
  Future<void> saveClaim(String claim, CheckResult result) async {
    try {
      if (Hive.isBoxOpen(AppConstants.boxClaimMemory)) {
        final box = Hive.box<String>(AppConstants.boxClaimMemory);
        final cleanClaim = claim.trim().toLowerCase();
        
        if (cleanClaim.isNotEmpty) {
          final hashKey = cleanClaim.hashCode.toString();
          
          DateTime firstSeen = DateTime.now();
          final rawExisting = box.get(hashKey);
          if (rawExisting != null) {
            final data = jsonDecode(rawExisting) as Map<String, dynamic>;
            final fs = data['firstSeen'] as String?;
            if (fs != null) {
              firstSeen = DateTime.tryParse(fs) ?? DateTime.now();
            }
          }

          final data = {
            'claim': claim,
            'result': result.toJson(),
            'category': result.contentType,
            'firstSeen': firstSeen.toIso8601String(),
            'lastSeen': DateTime.now().toIso8601String(),
          };
          await box.put(hashKey, jsonEncode(data));
          debugPrint('Claim Memory V2: Saved claim key: $hashKey');
        }
      }
    } catch (e) {
      debugPrint('Failed to save claim in Memory Engine: $e');
    }
  }

  /// Searches the Claim Memory database for a match (similarity >= 0.85)
  Future<ClaimMemoryMatch?> findMatch(String claim) async {
    try {
      if (!Hive.isBoxOpen(AppConstants.boxClaimMemory)) return null;

      final box = Hive.box<String>(AppConstants.boxClaimMemory);
      final target = claim.trim();
      if (target.isEmpty) return null;

      double highestScore = 0.0;
      Map<String, dynamic>? bestData;

      for (final key in box.keys) {
        final raw = box.get(key);
        if (raw != null) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final cachedClaim = data['claim'] as String? ?? '';
          
          final similarity = calculateSimilarity(target, cachedClaim);
          if (similarity > highestScore) {
            highestScore = similarity;
            bestData = data;
          }
        }
      }

      if (highestScore >= 0.85 && bestData != null) {
        final firstSeen = DateTime.tryParse(bestData['firstSeen']?.toString() ?? '') ?? DateTime.now();
        final lastSeen = DateTime.now(); // Mark this lookup as the new lastSeen

        // Update the lastSeen value inside the Hive record
        final hashKey = (bestData['claim'] as String).toLowerCase().trim().hashCode.toString();
        bestData['lastSeen'] = lastSeen.toIso8601String();
        await box.put(hashKey, jsonEncode(bestData));

        final resultObj = CheckResult.fromJson(Map<String, dynamic>.from(bestData['result'] as Map));

        debugPrint('Claim Memory Layered Match: SUCCESS (score: ${(highestScore * 100).toStringAsFixed(1)}%)');
        return ClaimMemoryMatch(
          similarityScore: highestScore,
          matchedClaim: bestData['claim'] as String? ?? '',
          historicalVerdict: resultObj.verdict,
          confidence: (highestScore * 100).round(),
          category: bestData['category'] as String? ?? resultObj.contentType,
          firstSeen: firstSeen,
          lastSeen: lastSeen,
          checkResult: resultObj,
        );
      }
    } catch (e) {
      debugPrint('Claim Memory search failed: $e');
    }
    return null;
  }
}

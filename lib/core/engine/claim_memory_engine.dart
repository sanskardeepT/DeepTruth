import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../models/check_result.dart';

class ClaimMemoryEngine {
  ClaimMemoryEngine._();
  static final ClaimMemoryEngine instance = ClaimMemoryEngine._();

  /// Calculates the normalized Levenshtein similarity between two strings (0.0 to 1.0)
  double calculateSimilarity(String s1, String s2) {
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

  /// Caches a completed claim check result in the local memory registry
  Future<void> saveClaim(String claim, CheckResult result) async {
    try {
      if (Hive.isBoxOpen(AppConstants.boxClaimMemory)) {
        final box = Hive.box<String>(AppConstants.boxClaimMemory);
        
        // Save using sanitized claim text as key prefix/hash
        final cleanClaim = claim.trim().toLowerCase();
        if (cleanClaim.isNotEmpty) {
          final data = {
            'claim': claim,
            'result': result.toJson(),
            'cachedAt': DateTime.now().toIso8601String(),
          };
          await box.put(cleanClaim.hashCode.toString(), jsonEncode(data));
          debugPrint('Claim Memory: Saved claim hash: ${cleanClaim.hashCode}');
        }
      }
    } catch (e) {
      debugPrint('Failed to save claim in Memory Engine: $e');
    }
  }

  /// Searches local memory registry for a match. Returns CheckResult if similarity >= 0.85
  Future<CheckResult?> findMatch(String claim) async {
    try {
      if (!Hive.isBoxOpen(AppConstants.boxClaimMemory)) return null;

      final box = Hive.box<String>(AppConstants.boxClaimMemory);
      final target = claim.trim().toLowerCase();
      if (target.isEmpty) return null;

      double highestScore = 0.0;
      CheckResult? bestMatch;

      for (final key in box.keys) {
        final raw = box.get(key);
        if (raw != null) {
          final data = jsonDecode(raw) as Map<String, dynamic>;
          final cachedClaim = data['claim'] as String? ?? '';
          
          final similarity = calculateSimilarity(target, cachedClaim);
          if (similarity > highestScore) {
            highestScore = similarity;
            if (similarity >= 0.85) {
              bestMatch = CheckResult.fromJson(Map<String, dynamic>.from(data['result'] as Map));
            }
          }
        }
      }

      if (bestMatch != null) {
        debugPrint('Claim Memory: MATCH FOUND (similarity: ${(highestScore * 100).toStringAsFixed(1)}%)');
        return bestMatch;
      }
    } catch (e) {
      debugPrint('Claim Memory search failed: $e');
    }
    return null;
  }
}

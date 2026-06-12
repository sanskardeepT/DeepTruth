import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import '../models/osint_result.dart';

/// Error Level Analysis (ELA) — entirely on-device, zero API dependency.
///
/// How it works:
/// 1. Load original image bytes
/// 2. Re-compress at JPEG quality=75
/// 3. Compare pixel-by-pixel absolute difference
/// 4. High-difference areas → likely manipulated regions
/// 5. Anomaly score = percentage of pixels that exceed the diff threshold
///
/// Interpretation:
///   >15% anomaly → manipulation likely
///   5-15% anomaly → some processing detected
///   <5% anomaly → likely original / single-save JPEG
class ElaService {
  ElaService._();
  static final ElaService instance = ElaService._();

  /// ELA difference threshold per channel (0-255).
  /// Pixels with max-channel-diff above this are considered "anomalous".
  static const int _diffThreshold = 25;

  /// JPEG re-compression quality for ELA comparison.
  static const int _recompressQuality = 75;

  /// Analyze an image file for compression manipulation artifacts.
  Future<ElaAnalysisResult> analyzeELA(String filePath) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return ElaAnalysisResult.error(
          filePath,
          'File does not exist at path.',
        );
      }

      final originalBytes = await file.readAsBytes();
      if (originalBytes.isEmpty) {
        return ElaAnalysisResult.error(
          filePath,
          'File is empty (0 bytes).',
        );
      }

      // Decode the original image
      final originalImage = img.decodeImage(originalBytes);
      if (originalImage == null) {
        return ElaAnalysisResult.error(
          filePath,
          'Could not decode image. Unsupported format.',
        );
      }

      // Run ELA computation on an isolate to avoid blocking UI thread
      final result = await compute(_computeEla, _ElaInput(
        originalBytes: originalBytes,
        width: originalImage.width,
        height: originalImage.height,
      ));

      final findings = <OsintFinding>[];
      findings.add(OsintFinding(
        label: 'Analysis Type',
        value: 'Error Level Analysis (ELA)',
      ));
      findings.add(OsintFinding(
        label: 'Image Resolution',
        value: '${originalImage.width} × ${originalImage.height} px',
      ));
      findings.add(OsintFinding(
        label: 'Total Pixels Analyzed',
        value: '${result.totalPixels}',
      ));
      findings.add(OsintFinding(
        label: 'Anomalous Pixels',
        value: '${result.anomalousPixels} (${result.anomalyPercent.toStringAsFixed(2)}%)',
      ));
      findings.add(OsintFinding(
        label: 'Average Pixel Difference',
        value: '${result.avgDiff.toStringAsFixed(2)} / 255',
      ));
      findings.add(OsintFinding(
        label: 'Max Pixel Difference',
        value: '${result.maxDiff} / 255',
      ));
      findings.add(OsintFinding(
        label: 'Anomaly Score',
        value: '${result.anomalyPercent.toStringAsFixed(1)}%',
      ));

      // Determine verdict
      String verdict;
      String riskLevel;
      double confidence = 90.0;

      if (result.anomalyPercent > 15.0) {
        verdict = 'MANIPULATION_LIKELY';
        riskLevel = 'high';
        // Extreme values increase confidence
        if (result.anomalyPercent > 30.0) confidence = 95.0;
      } else if (result.anomalyPercent > 5.0) {
        verdict = 'PROCESSING_DETECTED';
        riskLevel = 'medium';
        confidence = 75.0; // border regions are less certain
      } else {
        verdict = 'LIKELY_ORIGINAL';
        riskLevel = 'low';
        if (result.anomalyPercent < 2.0) confidence = 95.0;
      }

      findings.add(OsintFinding(label: 'ELA Verdict', value: verdict));

      // Detail on high-diff regions
      if (result.hotspotRegions.isNotEmpty) {
        findings.add(OsintFinding(
          label: 'High-Diff Regions',
          value: result.hotspotRegions.join('; '),
        ));
      }

      findings.add(const OsintFinding(
        label: 'Method',
        value: 'On-device JPEG re-compression at Q75 → pixel-level diff analysis. '
            'No data leaves your device.',
      ));

      return ElaAnalysisResult(
        queryType: OsintQueryType.image,
        query: filePath,
        findings: findings,
        sources: const ['DeepTruth On-Device ELA Engine'],
        riskLevel: riskLevel,
        analyzedAt: DateTime.now(),
        anomalyScore: result.anomalyPercent,
        verdict: verdict,
        confidence: confidence,
      );
    } catch (e) {
      debugPrint('ELA analysis failed: $e');
      return ElaAnalysisResult.error(
        filePath,
        'ELA analysis failed: $e',
      );
    }
  }
}

class ElaAnalysisResult extends OsintResult {
  final double anomalyScore;
  final String ELAverdict; // Named ELAverdict to avoid conflicts with super classes if any
  final double ELAconfidence;

  const ElaAnalysisResult({
    required super.queryType,
    required super.query,
    required super.findings,
    super.sources = const [],
    required super.riskLevel,
    super.error,
    required super.analyzedAt,
    required this.anomalyScore,
    required String verdict,
    required double confidence,
  }) : ELAverdict = verdict,
       ELAconfidence = confidence;

  factory ElaAnalysisResult.error(String query, String message) {
    return ElaAnalysisResult(
      queryType: OsintQueryType.image,
      query: query,
      findings: const [],
      riskLevel: 'unknown',
      error: message,
      analyzedAt: DateTime.now(),
      anomalyScore: 0.0,
      verdict: 'ERROR',
      confidence: 0.0,
    );
  }
}

// ── Data classes for isolate communication ──────────────────────────────────

class _ElaInput {
  final Uint8List originalBytes;
  final int width;
  final int height;

  const _ElaInput({
    required this.originalBytes,
    required this.width,
    required this.height,
  });
}

class ElaResult {
  final int totalPixels;
  final int anomalousPixels;
  final double anomalyPercent;
  final double avgDiff;
  final int maxDiff;
  final List<String> hotspotRegions;

  const ElaResult({
    required this.totalPixels,
    required this.anomalousPixels,
    required this.anomalyPercent,
    required this.avgDiff,
    required this.maxDiff,
    required this.hotspotRegions,
  });
}

/// Runs the actual ELA computation. Designed to execute in a separate isolate
/// via `compute()` to keep the UI thread responsive.
ElaResult _computeEla(_ElaInput input) {
  // 1. Decode original image
  final original = img.decodeImage(input.originalBytes);
  if (original == null) {
    return const ElaResult(
      totalPixels: 0,
      anomalousPixels: 0,
      anomalyPercent: 0,
      avgDiff: 0,
      maxDiff: 0,
      hotspotRegions: [],
    );
  }

  // 2. Re-compress as JPEG at the target quality
  final recompressedBytes = img.encodeJpg(original, quality: ElaService._recompressQuality);
  final recompressed = img.decodeImage(Uint8List.fromList(recompressedBytes));
  if (recompressed == null) {
    return const ElaResult(
      totalPixels: 0,
      anomalousPixels: 0,
      anomalyPercent: 0,
      avgDiff: 0,
      maxDiff: 0,
      hotspotRegions: [],
    );
  }

  final w = original.width;
  final h = original.height;
  final totalPixels = w * h;

  // 3. Pixel-by-pixel comparison
  int anomalousCount = 0;
  double totalDiff = 0;
  int maxDiff = 0;

  // Grid for hotspot detection: divide image into 4x4 sectors
  const gridSize = 4;
  final sectorW = w ~/ gridSize;
  final sectorH = h ~/ gridSize;
  final sectorAnomalyCounts = List<int>.filled(gridSize * gridSize, 0);
  final sectorTotalCounts = List<int>.filled(gridSize * gridSize, 0);

  for (int y = 0; y < h; y++) {
    for (int x = 0; x < w; x++) {
      final origPixel = original.getPixel(x, y);
      final recompPixel = recompressed.getPixel(x, y);

      // Calculate per-channel absolute difference
      final dr = (origPixel.r.toInt() - recompPixel.r.toInt()).abs();
      final dg = (origPixel.g.toInt() - recompPixel.g.toInt()).abs();
      final db = (origPixel.b.toInt() - recompPixel.b.toInt()).abs();

      final channelMax = math.max(dr, math.max(dg, db));
      totalDiff += channelMax;
      if (channelMax > maxDiff) maxDiff = channelMax;

      // Track grid sector
      final sx = math.min(x ~/ (sectorW == 0 ? 1 : sectorW), gridSize - 1);
      final sy = math.min(y ~/ (sectorH == 0 ? 1 : sectorH), gridSize - 1);
      final sectorIdx = sy * gridSize + sx;
      sectorTotalCounts[sectorIdx]++;

      if (channelMax > ElaService._diffThreshold) {
        anomalousCount++;
        sectorAnomalyCounts[sectorIdx]++;
      }
    }
  }

  final anomalyPercent = totalPixels > 0 ? (anomalousCount / totalPixels) * 100.0 : 0.0;
  final avgDiff = totalPixels > 0 ? totalDiff / totalPixels : 0.0;

  // 4. Identify hotspot regions (sectors with >20% anomalous pixels)
  final hotspots = <String>[];
  final sectorLabels = [
    'Top-Left (1,1)',     'Top (1,2)',          'Top (1,3)',          'Top-Right (1,4)',
    'Mid-Left (2,1)',     'Center-Left (2,2)',  'Center-Right (2,3)', 'Mid-Right (2,4)',
    'Mid-Left (3,1)',     'Center-Left (3,2)',  'Center-Right (3,3)', 'Mid-Right (3,4)',
    'Bottom-Left (4,1)',  'Bottom (4,2)',       'Bottom (4,3)',       'Bottom-Right (4,4)',
  ];

  for (int i = 0; i < sectorAnomalyCounts.length && i < sectorLabels.length; i++) {
    if (sectorTotalCounts[i] > 0) {
      final sectorPercent = (sectorAnomalyCounts[i] / sectorTotalCounts[i]) * 100.0;
      if (sectorPercent > 20.0) {
        hotspots.add('${sectorLabels[i]}: ${sectorPercent.toStringAsFixed(1)}% anomalous');
      }
    }
  }

  return ElaResult(
    totalPixels: totalPixels,
    anomalousPixels: anomalousCount,
    anomalyPercent: anomalyPercent,
    avgDiff: avgDiff,
    maxDiff: maxDiff,
    hotspotRegions: hotspots,
  );
}

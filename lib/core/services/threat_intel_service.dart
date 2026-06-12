import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/api_keys.dart';
import '../constants/app_constants.dart';
import '../models/osint_result.dart';
import 'firebase_service.dart';

/// Threat Intelligence service — VirusTotal + URLScan.io URL scanning.
///
/// Rate limits:
///   VirusTotal Free: 500 requests/day, 4/minute
///   URLScan.io Free: 100 scans/day
class ThreatIntelService {
  ThreatIntelService._();
  static final ThreatIntelService instance = ThreatIntelService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 30),
  ));

  // ── Rate limiter (reuses OsintService pattern) ────────────────────

  bool _canQuery(String service) {
    try {
      final box = Hive.box<String>(AppConstants.boxOsint);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final key = '${service}_$today';
      final count = int.tryParse(box.get(key) ?? '0') ?? 0;
      final limit = service == 'virustotal' ? 500 : 100;
      return count < limit;
    } catch (_) {
      return true;
    }
  }

  void _incrementCount(String service) {
    try {
      final box = Hive.box<String>(AppConstants.boxOsint);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final key = '${service}_$today';
      final count = int.tryParse(box.get(key) ?? '0') ?? 0;
      box.put(key, (count + 1).toString());
    } catch (_) {}
  }

  // ══════════════════════════════════════════════════════════════════
  //  VIRUSTOTAL URL SCAN
  // ══════════════════════════════════════════════════════════════════

  /// Scans a URL against 70+ antivirus and threat-detection engines
  /// using the VirusTotal v3 API.
  ///
  /// Flow:
  /// 1. POST the URL to submit for scanning
  /// 2. Extract analysis ID from response
  /// 3. GET the analysis results
  /// 4. Parse malicious/suspicious/clean counts
  Future<OsintResult> scanUrlVirusTotal(String url) async {
    if (!_canQuery('virustotal')) {
      return OsintResult.error(
        OsintQueryType.url,
        url,
        'VirusTotal daily limit reached (500/day). Reset tomorrow.',
      );
    }

    final apiKey = ApiKeys.virusTotal;
    if (apiKey.contains('YOUR_')) {
      return OsintResult.error(
        OsintQueryType.url,
        url,
        'VirusTotal API key not configured. Add it in Settings → API Keys.',
      );
    }

    try {
      _incrementCount('virustotal');

      // Step 1: Submit URL for scanning
      final submitResponse = await _dio.post(
        'https://www.virustotal.com/api/v3/urls',
        data: 'url=${Uri.encodeComponent(url)}',
        options: Options(
          headers: {
            'x-apikey': apiKey,
            'Content-Type': 'application/x-www-form-urlencoded',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (submitResponse.statusCode != 200) {
        throw Exception(
          'VirusTotal submit failed: ${submitResponse.statusCode} — '
          '${submitResponse.data}',
        );
      }

      final submitData = submitResponse.data as Map<String, dynamic>;
      final analysisId = (submitData['data'] as Map<String, dynamic>?)?['id'] as String?;

      if (analysisId == null || analysisId.isEmpty) {
        throw Exception('No analysis ID returned from VirusTotal.');
      }

      // Step 2: Wait briefly for scan to complete, then fetch results
      await Future<void>.delayed(const Duration(seconds: 3));

      final resultResponse = await _dio.get(
        'https://www.virustotal.com/api/v3/analyses/$analysisId',
        options: Options(
          headers: {'x-apikey': apiKey},
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (resultResponse.statusCode != 200) {
        throw Exception(
          'VirusTotal result fetch failed: ${resultResponse.statusCode}',
        );
      }

      final resultData = resultResponse.data as Map<String, dynamic>;
      final attributes = (resultData['data'] as Map<String, dynamic>?)?['attributes']
          as Map<String, dynamic>? ?? {};
      final stats = attributes['stats'] as Map<String, dynamic>? ?? {};

      final malicious = (stats['malicious'] as num?)?.toInt() ?? 0;
      final suspicious = (stats['suspicious'] as num?)?.toInt() ?? 0;
      final harmless = (stats['harmless'] as num?)?.toInt() ?? 0;
      final undetected = (stats['undetected'] as num?)?.toInt() ?? 0;
      final timeout = (stats['timeout'] as num?)?.toInt() ?? 0;
      final totalScanners = malicious + suspicious + harmless + undetected + timeout;

      // Parse top flagging engines
      final engineResults = attributes['results'] as Map<String, dynamic>? ?? {};
      final flaggingEngines = <String>[];
      for (final entry in engineResults.entries) {
        final engineData = entry.value as Map<String, dynamic>? ?? {};
        final category = engineData['category'] as String? ?? '';
        if (category == 'malicious' || category == 'suspicious') {
          final result = engineData['result'] as String? ?? category;
          flaggingEngines.add('${entry.key}: $result');
          if (flaggingEngines.length >= 5) break; // Top 5 only
        }
      }

      // Determine risk level
      String riskLevel;
      String verdict;
      if (malicious >= 5) {
        riskLevel = 'high';
        verdict = 'MALICIOUS';
      } else if (malicious >= 1 || suspicious >= 3) {
        riskLevel = 'medium';
        verdict = 'SUSPICIOUS';
      } else {
        riskLevel = 'low';
        verdict = 'CLEAN';
      }

      final findings = <OsintFinding>[
        OsintFinding(label: 'URL Scanned', value: url),
        OsintFinding(label: 'Total Scanners', value: '$totalScanners'),
        OsintFinding(
          label: 'Malicious Detections',
          value: '$malicious / $totalScanners',
        ),
        OsintFinding(label: 'Suspicious', value: '$suspicious'),
        OsintFinding(label: 'Clean / Harmless', value: '$harmless'),
        OsintFinding(label: 'Undetected', value: '$undetected'),
        OsintFinding(label: 'Verdict', value: verdict),
      ];

      if (flaggingEngines.isNotEmpty) {
        findings.add(OsintFinding(
          label: 'Top Flagging Engines',
          value: flaggingEngines.join('\n'),
        ));
      }

      return OsintResult(
        queryType: OsintQueryType.url,
        query: url,
        findings: findings,
        sources: const ['VirusTotal (virustotal.com)'],
        riskLevel: riskLevel,
        analyzedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('VirusTotal scan failed: $e');
      await FirebaseService.instance.logApiFailure('VirusTotal', e.toString());
      return OsintResult.error(
        OsintQueryType.url,
        url,
        'VirusTotal scan failed: $e',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  URLSCAN.IO — Website screenshot + threat analysis
  // ══════════════════════════════════════════════════════════════════

  /// Submits a URL to urlscan.io for scanning, waits for results,
  /// and extracts threat verdicts, domain info, and IP intelligence.
  ///
  /// Flow:
  /// 1. POST /scan with the URL
  /// 2. Wait 12 seconds for scan to complete
  /// 3. GET /result/{uuid}/ for full analysis
  /// 4. Parse verdicts, domain, IPs, and threat indicators
  Future<OsintResult> scanUrlScreenshot(String url) async {
    if (!_canQuery('urlscan')) {
      return OsintResult.error(
        OsintQueryType.url,
        url,
        'URLScan.io daily limit reached (100/day). Reset tomorrow.',
      );
    }

    final apiKey = ApiKeys.urlscan;
    if (apiKey.contains('YOUR_')) {
      return OsintResult.error(
        OsintQueryType.url,
        url,
        'URLScan.io API key not configured. Add it in Settings → API Keys.',
      );
    }

    try {
      _incrementCount('urlscan');

      // Step 1: Submit scan request
      final submitResponse = await _dio.post(
        'https://urlscan.io/api/v1/scan/',
        data: jsonEncode({
          'url': url,
          'visibility': 'public',
        }),
        options: Options(
          headers: {
            'API-Key': apiKey,
            'Content-Type': 'application/json',
          },
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      if (submitResponse.statusCode != 200) {
        // urlscan.io returns 429 for rate limit
        if (submitResponse.statusCode == 429) {
          return OsintResult.error(
            OsintQueryType.url,
            url,
            'URLScan.io rate limit exceeded. Please wait a minute.',
          );
        }
        throw Exception(
          'URLScan submit failed: ${submitResponse.statusCode} — '
          '${submitResponse.data}',
        );
      }

      final submitData = submitResponse.data as Map<String, dynamic>;
      final uuid = submitData['uuid'] as String?;
      final resultUrl = submitData['result'] as String?;

      if (uuid == null || uuid.isEmpty) {
        throw Exception('No scan UUID returned from URLScan.io.');
      }

      // Step 2: Wait for scan to complete (urlscan typically takes 10-20s)
      await Future<void>.delayed(const Duration(seconds: 12));

      // Step 3: Fetch results (retry once if not ready)
      Map<String, dynamic>? resultData;
      for (int attempt = 1; attempt <= 3; attempt++) {
        try {
          final resultResponse = await _dio.get(
            'https://urlscan.io/api/v1/result/$uuid/',
            options: Options(
              headers: {'API-Key': apiKey},
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          if (resultResponse.statusCode == 200) {
            resultData = resultResponse.data as Map<String, dynamic>;
            break;
          } else if (resultResponse.statusCode == 404) {
            // Scan not ready yet
            if (attempt < 3) {
              await Future<void>.delayed(const Duration(seconds: 5));
            }
          } else {
            throw Exception('URLScan result: ${resultResponse.statusCode}');
          }
        } catch (e) {
          if (attempt == 3) rethrow;
          await Future<void>.delayed(const Duration(seconds: 5));
        }
      }

      if (resultData == null) {
        return OsintResult(
          queryType: OsintQueryType.url,
          query: url,
          findings: [
            const OsintFinding(
              label: 'Status',
              value: 'Scan submitted but results not yet available. '
                  'URLScan.io may still be processing.',
            ),
            OsintFinding(
              label: 'Result URL',
              value: resultUrl ?? 'https://urlscan.io/result/$uuid/',
              sourceUrl: resultUrl ?? 'https://urlscan.io/result/$uuid/',
            ),
          ],
          sources: const ['urlscan.io'],
          riskLevel: 'unknown',
          analyzedAt: DateTime.now(),
        );
      }

      // Step 4: Parse results
      final verdicts = resultData['verdicts'] as Map<String, dynamic>? ?? {};
      final overallVerdict = verdicts['overall'] as Map<String, dynamic>? ?? {};
      final isMalicious = overallVerdict['malicious'] as bool? ?? false;
      final score = (overallVerdict['score'] as num?)?.toInt() ?? 0;
      final categories = (overallVerdict['categories'] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          [];

      final page = resultData['page'] as Map<String, dynamic>? ?? {};
      final pageDomain = page['domain'] as String? ?? 'Unknown';
      final pageCountry = page['country'] as String? ?? 'Unknown';
      final pageTitle = page['title'] as String? ?? 'No title';
      final pageServer = page['server'] as String? ?? 'Unknown';
      final pageIp = page['ip'] as String? ?? 'Unknown';

      final lists = resultData['lists'] as Map<String, dynamic>? ?? {};
      final ips = (lists['ips'] as List?)?.map((e) => e.toString()).toList() ?? [];
      final domains = (lists['domains'] as List?)?.map((e) => e.toString()).toList() ?? [];

      // Screenshot URL
      final task = resultData['task'] as Map<String, dynamic>? ?? {};
      final screenshotUrl = task['screenshotURL'] as String?;

      String riskLevel;
      String verdictLabel;
      if (isMalicious || score >= 80) {
        riskLevel = 'high';
        verdictLabel = 'MALICIOUS';
      } else if (score >= 40 || categories.isNotEmpty) {
        riskLevel = 'medium';
        verdictLabel = 'SUSPICIOUS';
      } else {
        riskLevel = 'low';
        verdictLabel = 'CLEAN';
      }

      final findings = <OsintFinding>[
        OsintFinding(label: 'URL Scanned', value: url),
        OsintFinding(label: 'Page Title', value: pageTitle),
        OsintFinding(label: 'Domain', value: pageDomain),
        OsintFinding(label: 'Server IP', value: pageIp),
        OsintFinding(label: 'Hosting Country', value: pageCountry),
        OsintFinding(label: 'Server Software', value: pageServer),
        OsintFinding(label: 'Threat Score', value: '$score / 100'),
        OsintFinding(label: 'Verdict', value: verdictLabel),
      ];

      if (categories.isNotEmpty) {
        findings.add(OsintFinding(
          label: 'Threat Categories',
          value: categories.join(', '),
        ));
      }

      if (ips.isNotEmpty) {
        findings.add(OsintFinding(
          label: 'Contacted IPs',
          value: ips.take(10).join(', ') + (ips.length > 10 ? ' (+${ips.length - 10} more)' : ''),
        ));
      }

      if (domains.isNotEmpty) {
        findings.add(OsintFinding(
          label: 'Contacted Domains',
          value: domains.take(10).join(', ') + (domains.length > 10 ? ' (+${domains.length - 10} more)' : ''),
        ));
      }

      if (screenshotUrl != null) {
        findings.add(OsintFinding(
          label: 'Page Screenshot',
          value: 'Available',
          sourceUrl: screenshotUrl,
        ));
      }

      findings.add(OsintFinding(
        label: 'Full Report',
        value: 'urlscan.io/result/$uuid/',
        sourceUrl: 'https://urlscan.io/result/$uuid/',
      ));

      return OsintResult(
        queryType: OsintQueryType.url,
        query: url,
        findings: findings,
        sources: const ['urlscan.io'],
        riskLevel: riskLevel,
        analyzedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('URLScan.io scan failed: $e');
      await FirebaseService.instance.logApiFailure('URLScan', e.toString());
      return OsintResult.error(
        OsintQueryType.url,
        url,
        'URLScan.io scan failed: $e',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  COMBINED URL SCAN — runs both in parallel
  // ══════════════════════════════════════════════════════════════════

  /// Checks the Internet Archive Wayback Machine to see if the URL has history.
  Future<OsintResult> scanWaybackArchive(String url) async {
    try {
      final findings = <OsintFinding>[];
      String riskLevel = 'low';
      String? firstSnapshot;
      String? latestSnapshot;
      String ageIndicator = 'Brand New / Unarchived';

      // 1. Fetch first snapshot
      try {
        final firstRes = await _dio.get(
          'https://web.archive.org/cdx/search/cdx',
          queryParameters: {
            'url': url,
            'output': 'json',
            'fl': 'timestamp',
            'limit': 1,
          },
        ).timeout(const Duration(seconds: 8));

        if (firstRes.statusCode == 200 && firstRes.data is List) {
          final rows = firstRes.data as List<dynamic>;
          if (rows.length > 1 && rows[1] is List && (rows[1] as List).isNotEmpty) {
            firstSnapshot = rows[1][0]?.toString();
          }
        }
      } catch (e) {
        debugPrint('Wayback first snapshot fetch failed: $e');
      }

      // 2. Fetch latest snapshot
      try {
        final latestRes = await _dio.get(
          'https://web.archive.org/cdx/search/cdx',
          queryParameters: {
            'url': url,
            'output': 'json',
            'fl': 'timestamp',
            'limit': -1,
          },
        ).timeout(const Duration(seconds: 8));

        if (latestRes.statusCode == 200 && latestRes.data is List) {
          final rows = latestRes.data as List<dynamic>;
          if (rows.length > 1 && rows[1] is List && (rows[1] as List).isNotEmpty) {
            latestSnapshot = rows[1][0]?.toString();
          }
        }
      } catch (e) {
        debugPrint('Wayback latest snapshot fetch failed: $e');
      }

      if (firstSnapshot != null) {
        if (firstSnapshot.length >= 8) {
          final year = int.tryParse(firstSnapshot.substring(0, 4)) ?? 0;
          final month = int.tryParse(firstSnapshot.substring(4, 6)) ?? 1;
          final day = int.tryParse(firstSnapshot.substring(6, 8)) ?? 1;
          final date = DateTime(year, month, day);
          final diff = DateTime.now().difference(date);
          
          if (diff.inDays > 365) {
            final years = (diff.inDays / 365.0).toStringAsFixed(1);
            ageIndicator = '$years years old';
          } else {
            ageIndicator = '${diff.inDays} days old';
          }
        }

        String formatTimestamp(String ts) {
          if (ts.length < 14) return ts;
          return '${ts.substring(0, 4)}-${ts.substring(4, 6)}-${ts.substring(6, 8)} '
              '${ts.substring(8, 10)}:${ts.substring(10, 12)}:${ts.substring(12, 14)}';
        }

        findings.add(const OsintFinding(label: 'Wayback Archive Status', value: 'Archived Snapshots Present ✅'));
        findings.add(OsintFinding(label: 'First Snapshot', value: formatTimestamp(firstSnapshot)));
        findings.add(OsintFinding(label: 'Latest Snapshot', value: formatTimestamp(latestSnapshot ?? firstSnapshot)));
        findings.add(OsintFinding(label: 'Archival Age Indicator', value: ageIndicator));
      } else {
        findings.add(const OsintFinding(label: 'Wayback Archive Status', value: 'No snapshots found.'));
        findings.add(const OsintFinding(label: 'Age Indicator', value: 'New/Unarchived (Spoofing risk) ⚠️'));
        riskLevel = 'medium';
      }

      return OsintResult(
        queryType: OsintQueryType.url,
        query: url,
        findings: findings,
        sources: const ['Wayback Machine (archive.org)'],
        riskLevel: riskLevel,
        analyzedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Wayback Machine check failed: $e');
      await FirebaseService.instance.logApiFailure('Wayback', e.toString());
      return OsintResult.error(
        OsintQueryType.url,
        url,
        'Wayback Machine lookup failed: $e',
      );
    }
  }

  // ══════════════════════════════════════════════════════════════════
  //  COMBINED URL SCAN — runs VT, URLScan, and Wayback in parallel
  // ══════════════════════════════════════════════════════════════════

  /// Runs VirusTotal, URLScan.io, and Wayback Machine in parallel and merges findings
  /// into a single comprehensive OsintResult.
  Future<OsintResult> fullUrlScan(String url) async {
    final results = await Future.wait([
      scanUrlVirusTotal(url),
      scanUrlScreenshot(url),
      scanWaybackArchive(url),
    ]);

    final vtResult = results[0];
    final usResult = results[1];
    final wbResult = results[2];

    // Merge findings
    final mergedFindings = <OsintFinding>[
      const OsintFinding(
        label: '── VirusTotal ──',
        value: '70+ antivirus engine scan',
      ),
      ...vtResult.findings,
      const OsintFinding(
        label: '── URLScan.io ──',
        value: 'Website behavior analysis',
      ),
      ...usResult.findings,
      const OsintFinding(
        label: '── Wayback Machine ──',
        value: 'Historical snapshot check',
      ),
      ...wbResult.findings,
    ];

    // Merged risk: take the highest risk level
    const riskOrder = {'high': 3, 'medium': 2, 'low': 1, 'unknown': 0};
    final vtRisk = riskOrder[vtResult.riskLevel] ?? 0;
    final usRisk = riskOrder[usResult.riskLevel] ?? 0;
    final wbRisk = riskOrder[wbResult.riskLevel] ?? 0;
    
    int maxRiskScore = vtRisk;
    String mergedRisk = vtResult.riskLevel;

    if (usRisk > maxRiskScore) {
      maxRiskScore = usRisk;
      mergedRisk = usResult.riskLevel;
    }
    if (wbRisk > maxRiskScore) {
      maxRiskScore = wbRisk;
      mergedRisk = wbResult.riskLevel;
    }

    final mergedSources = <String>{
      ...vtResult.sources,
      ...usResult.sources,
      ...wbResult.sources,
    }.toList();

    final hasErrors = [vtResult.hasError, usResult.hasError, wbResult.hasError];
    final errorMessages = [vtResult.error, usResult.error, wbResult.error]
        .where((e) => e != null && e.isNotEmpty)
        .join('; ');

    return OsintResult(
      queryType: OsintQueryType.url,
      query: url,
      findings: mergedFindings,
      sources: mergedSources,
      riskLevel: mergedRisk,
      analyzedAt: DateTime.now(),
      error: errorMessages.isNotEmpty ? errorMessages : null,
    );
  }
}

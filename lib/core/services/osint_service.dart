import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image/image.dart' as img;
import '../constants/api_keys.dart';
import '../constants/app_constants.dart';
import '../models/osint_result.dart';
import 'gemini_service.dart';

class OsintService {
  OsintService._();
  static final OsintService instance = OsintService._();

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
  ));

  // ── RATE LIMITER ──────────────────────────────────────────────────
  bool _canQuery(OsintQueryType type) {
    try {
      final box = Hive.box<String>(AppConstants.boxOsint);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final key   = '${type.name}_$today';
      final count = int.tryParse(box.get(key) ?? '0') ?? 0;
      return count < AppConstants.osintDailyLimit;
    } catch (_) {
      return true;
    }
  }

  void _incrementCount(OsintQueryType type) {
    try {
      final box = Hive.box<String>(AppConstants.boxOsint);
      final today = DateTime.now().toIso8601String().substring(0, 10);
      final key   = '${type.name}_$today';
      final count = int.tryParse(box.get(key) ?? '0') ?? 0;
      box.put(key, (count + 1).toString());
    } catch (_) {}
  }

  // ── EMAIL BREACH ──────────────────────────────────────────────────
  Future<OsintResult> checkEmail(String email) async {
    if (!_canQuery(OsintQueryType.email)) {
      return OsintResult.error(
        OsintQueryType.email,
        email,
        'Daily limit reached (${AppConstants.osintDailyLimit} lookups/day). Reset tomorrow.',
      );
    }

    try {
      _incrementCount(OsintQueryType.email);
      final response = await _dio.get(
        'https://haveibeenpwned.com/api/v3/breachedaccount/${Uri.encodeComponent(email)}',
        options: Options(
          headers: {
            'hibp-api-key':   ApiKeys.hibp,
            'user-agent':     'DeepTruth-App',
            'Accept':         'application/json',
          },
          validateStatus: (status) => status == 200 || status == 404,
        ),
      );

      if (response.statusCode == 404) {
        return OsintResult(
          queryType:  OsintQueryType.email,
          query:      email,
          findings:   [const OsintFinding(label: 'Status', value: 'No breaches found ✅')],
          riskLevel:  'low',
          analyzedAt: DateTime.now(),
        );
      }

      if (response.statusCode != 200) {
        throw Exception('HIBP returned ${response.statusCode}');
      }

      final breaches = response.data as List<dynamic>;
      final findings = breaches.map((b) {
        final breach = b as Map<String, dynamic>;
        return OsintFinding(
          label:     breach['Name'] as String? ?? 'Unknown Breach',
          value:     'Compromised on: ${breach['BreachDate'] ?? 'Unknown date'}',
          sourceUrl: 'https://haveibeenpwned.com',
        );
      }).toList();

      return OsintResult(
        queryType:  OsintQueryType.email,
        query:      email,
        findings:   findings,
        sources:    ['HaveIBeenPwned.com'],
        riskLevel:  breaches.length > 3 ? 'high' : 'medium',
        analyzedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('HIBP lookup failed: $e');
      return OsintResult.error(OsintQueryType.email, email, 'Breach check unavailable: $e');
    }
  }

  // ── IP LOOKUP ─────────────────────────────────────────────────────
  Future<OsintResult> lookupIp(String ip) async {
    if (!_canQuery(OsintQueryType.ip)) {
      return OsintResult.error(
        OsintQueryType.ip, ip,
        'Daily limit reached. Reset tomorrow.',
      );
    }
    try {
      _incrementCount(OsintQueryType.ip);
      final response = await _dio.get('https://ipapi.co/$ip/json/');
      if (response.statusCode != 200) throw Exception('ipapi error');

      final data = response.data as Map<String, dynamic>;
      final findings = <OsintFinding>[
        OsintFinding(label: 'IP',           value: data['ip']           as String? ?? ip),
        OsintFinding(label: 'City',         value: data['city']         as String? ?? 'Unknown'),
        OsintFinding(label: 'Region',       value: data['region']       as String? ?? 'Unknown'),
        OsintFinding(label: 'Country',      value: data['country_name'] as String? ?? 'Unknown'),
        OsintFinding(label: 'ISP / Org',    value: data['org']          as String? ?? 'Unknown'),
        OsintFinding(label: 'Timezone',     value: data['timezone']     as String? ?? 'Unknown'),
        OsintFinding(label: 'Latitude',     value: '${data["latitude"] ?? "?"}'),
        OsintFinding(label: 'Longitude',    value: '${data["longitude"] ?? "?"}'),
      ];

      return OsintResult(
        queryType:  OsintQueryType.ip,
        query:      ip,
        findings:   findings,
        sources:    ['ipapi.co'],
        riskLevel:  'low',
        analyzedAt: DateTime.now(),
      );
    } catch (e) {
      return OsintResult.error(OsintQueryType.ip, ip, 'IP lookup failed: $e');
    }
  }

  // ── USERNAME ──────────────────────────────────────────────────────
  Future<OsintResult> lookupUsername(String username) async {
    if (!_canQuery(OsintQueryType.username)) {
      return OsintResult.error(
        OsintQueryType.username, username,
        'Daily limit reached. Reset tomorrow.',
      );
    }
    _incrementCount(OsintQueryType.username);

    final findings = <OsintFinding>[];
    final sources  = <String>[];

    // GitHub
    try {
      final ghRes = await _dio.get(
        'https://api.github.com/users/$username',
        options: Options(
          headers: {'Accept': 'application/json'},
          validateStatus: (status) => status == 200 || status == 404,
        ),
      );
      if (ghRes.statusCode == 200) {
        final gh = ghRes.data as Map<String, dynamic>;
        findings.add(OsintFinding(
          label: 'GitHub',
          value: 'Found — ${gh["public_repos"] ?? 0} repos, ${gh["followers"] ?? 0} followers',
          sourceUrl: gh['html_url'] as String?,
        ));
        sources.add('github.com');
      }
    } catch (_) {}

    // Reddit
    try {
      final rdRes = await _dio.get(
        'https://www.reddit.com/user/$username/about.json',
        options: Options(
          headers: {'User-Agent': 'DeepTruth/1.0'},
          validateStatus: (status) => status == 200 || status == 404,
        ),
      );
      if (rdRes.statusCode == 200) {
        final rd   = rdRes.data as Map<String, dynamic>;
        final data = rd['data'] as Map<String, dynamic>? ?? {};
        findings.add(OsintFinding(
          label: 'Reddit',
          value: 'Found — Karma: ${data["total_karma"] ?? 0}',
          sourceUrl: 'https://reddit.com/u/$username',
        ));
        sources.add('reddit.com');
      }
    } catch (_) {}

    if (findings.isEmpty) {
      findings.add(const OsintFinding(label: 'Result', value: 'No public profiles found on checked platforms.'));
    }

    return OsintResult(
      queryType:  OsintQueryType.username,
      query:      username,
      findings:   findings,
      sources:    sources,
      riskLevel:  'low',
      analyzedAt: DateTime.now(),
    );
  }

  // ── WEBSITE WHOIS ─────────────────────────────────────────────────
  Future<OsintResult> lookupWebsite(String domain) async {
    if (!_canQuery(OsintQueryType.website)) {
      return OsintResult.error(
        OsintQueryType.website, domain,
        'Daily limit reached. Reset tomorrow.',
      );
    }
    try {
      _incrementCount(OsintQueryType.website);
      // Free WHOIS via rdap (IANA maintained)
      final cleanDomain = domain
          .replaceAll('https://', '')
          .replaceAll('http://', '')
          .split('/')[0];
      final tld = cleanDomain.split('.').last;

      final response = await _dio.get(
        'https://rdap.org/domain/$cleanDomain',
        options: Options(
          validateStatus: (status) => status == 200 || status == 404,
        ),
      );

      if (response.statusCode != 200) {
        throw Exception('RDAP returned ${response.statusCode}');
      }

      final data     = response.data as Map<String, dynamic>;
      final events   = data['events'] as List<dynamic>? ?? [];
      String? regDate, expDate;
      for (final ev in events) {
        final e = ev as Map<String, dynamic>;
        if (e['eventAction'] == 'registration') regDate = e['eventDate'] as String?;
        if (e['eventAction'] == 'expiration')   expDate = e['eventDate'] as String?;
      }

      return OsintResult(
        queryType: OsintQueryType.website,
        query:     domain,
        findings: [
          OsintFinding(label: 'Domain',      value: cleanDomain),
          OsintFinding(label: 'TLD',         value: '.$tld'),
          OsintFinding(label: 'Registered',  value: regDate ?? 'Unknown'),
          OsintFinding(label: 'Expires',     value: expDate ?? 'Unknown'),
          OsintFinding(label: 'Status',      value: (data['status'] as List?)?.join(', ') ?? 'Unknown'),
        ],
        sources:    ['rdap.org (IANA)'],
        riskLevel:  'low',
        analyzedAt: DateTime.now(),
      );
    } catch (e) {
      return OsintResult.error(OsintQueryType.website, domain, 'WHOIS lookup failed: $e');
    }
  }

  // ── PHONE (basic) ─────────────────────────────────────────────────
  Future<OsintResult> lookupPhone(String phone) async {
    if (!_canQuery(OsintQueryType.phone)) {
      return OsintResult.error(
        OsintQueryType.phone, phone,
        'Daily limit reached. Reset tomorrow.',
      );
    }
    // Basic carrier/country detection from phone prefix (no paid API needed)
    _incrementCount(OsintQueryType.phone);
    final cleaned = phone.replaceAll(RegExp(r'[^\d+]'), '');
    String country = 'Unknown';
    if (cleaned.startsWith('+91') || cleaned.startsWith('91')) {
      country = 'India';
    } else if (cleaned.startsWith('+1')) {
      country = 'USA/Canada';
    } else if (cleaned.startsWith('+44')) {
      country = 'United Kingdom';
    } else if (cleaned.startsWith('+61')) {
      country = 'Australia';
    } else if (cleaned.startsWith('+49')) {
      country = 'Germany';
    } else if (cleaned.startsWith('+86')) {
      country = 'China';
    } else if (cleaned.startsWith('+81')) {
      country = 'Japan';
    }

    return OsintResult(
      queryType: OsintQueryType.phone,
      query:     phone,
      findings: [
        OsintFinding(label: 'Number',     value: cleaned),
        OsintFinding(label: 'Country',    value: country),
        const OsintFinding(label: 'Note',       value: 'Advanced lookup requires NumVerify API key'),
      ],
      riskLevel:  'low',
      analyzedAt: DateTime.now(),
    );
  }

  // ── IMAGE METADATA FORENSICS ──────────────────────────────────────
  Future<OsintResult> analyzeImageMetadata(String filePath) async {
    if (!_canQuery(OsintQueryType.image)) {
      return OsintResult.error(
        OsintQueryType.image, filePath,
        'Daily limit reached. Reset tomorrow.',
      );
    }
    _incrementCount(OsintQueryType.image);

    try {
      final file = File(filePath);
      if (!await file.exists()) {
        return OsintResult.error(OsintQueryType.image, filePath, 'File does not exist.');
      }
      final bytes = await file.readAsBytes();

      // Decode image to check dimensions
      final image = img.decodeImage(bytes);
      final findings = <OsintFinding>[];
      findings.add(OsintFinding(label: 'File Name', value: filePath.split(Platform.pathSeparator).last));
      findings.add(OsintFinding(label: 'File Size', value: '${(bytes.length / 1024).toStringAsFixed(1)} KB'));

      if (image != null) {
        findings.add(OsintFinding(label: 'Resolution', value: '${image.width} x ${image.height} px'));
        findings.add(OsintFinding(label: 'Aspect Ratio', value: (image.width / image.height).toStringAsFixed(2)));
      }

      // Read EXIF tags from image package
      String? cameraMake;
      String? cameraModel;
      String? software;
      String? dateTime;
      String? gpsInfo;

      if (image != null && image.exif != null) {
        final exif = image.exif;
        if (exif.imageIfd.containsKey(0x010f)) {
          cameraMake = exif.imageIfd[0x010f]?.toString();
        }
        if (exif.imageIfd.containsKey(0x0110)) {
          cameraModel = exif.imageIfd[0x0110]?.toString();
        }
        if (exif.imageIfd.containsKey(0x0131)) {
          software = exif.imageIfd[0x0131]?.toString();
        }
        if (exif.imageIfd.containsKey(0x0132)) {
          dateTime = exif.imageIfd[0x0132]?.toString();
        }
        if (!exif.gpsIfd.isEmpty) {
          gpsInfo = 'GPS Coordinates present 📍';
        }
      }

      findings.add(OsintFinding(label: 'Camera Make', value: cameraMake ?? 'Unknown / Stripped'));
      findings.add(OsintFinding(label: 'Camera Model', value: cameraModel ?? 'Unknown / Stripped'));
      findings.add(OsintFinding(label: 'Software Header', value: software ?? 'None Detected (Original/Clean)'));
      findings.add(OsintFinding(label: 'Creation Date', value: dateTime ?? 'Unknown / Stripped'));
      if (gpsInfo != null) {
        findings.add(OsintFinding(label: 'GPS Metadata', value: gpsInfo));
      }

      // Gemini prompt for forensics
      final prompt = '''
You are a digital forensics and image OSINT analyst. Analyze the following image metadata and the visual content of the image to check if it has been manipulated, edited, or fabricated.

Metadata found:
- File Name: ${filePath.split(Platform.pathSeparator).last}
- File Size: ${(bytes.length / 1024).toStringAsFixed(1)} KB
- Resolution: ${image != null ? "${image.width} x ${image.height}" : "Unknown"}
- Camera Make: ${cameraMake ?? "Unknown"}
- Camera Model: ${cameraModel ?? "Unknown"}
- Software/Editing Tool: ${software ?? "None"}
- Date Taken: ${dateTime ?? "Unknown"}
- GPS Data: ${gpsInfo ?? "None"}

Please evaluate:
1. Is there any editing software header (like Adobe Photoshop, Canva, GIMP, Pixelmator)?
2. Is the creation date inconsistent or missing?
3. What is the likelihood that this image was edited, compressed multiple times, or AI-generated?

Return ONLY a valid JSON object:
{
  "forensicVerdict": "<MINIMAL_EDITING|HEAVILY_EDITED|AI_GENERATED|ORIGINAL_UNCUT|SUSPICIOUS_METADATA>",
  "riskLevel": "<low|medium|high>",
  "analysisSummary": "<2-3 sentences explaining your findings>",
  "anomalyScore": <integer 0-100>
}
''';

      String analysisSummary = 'AI Forensic analysis is unavailable.';
      String riskLevel = 'low';
      String forensicVerdict = 'SUSPICIOUS_METADATA';
      int anomalyScore = 50;

      if (GeminiService.instance.isInitialized) {
        try {
          final model = GenerativeModel(
            model: 'gemini-1.5-flash',
            apiKey: ApiKeys.gemini,
          );
          final response = await model.generateContent([
            Content.multi([
              TextPart(prompt),
              DataPart('image/jpeg', bytes),
            ])
          ]).timeout(const Duration(seconds: 25));

          final text = response.text;
          if (text != null && text.isNotEmpty) {
            final json = jsonDecode(text.replaceAll('```json', '').replaceAll('```', '').trim()) as Map<String, dynamic>;
            forensicVerdict = json['forensicVerdict'] as String? ?? 'SUSPICIOUS_METADATA';
            riskLevel = json['riskLevel'] as String? ?? 'medium';
            analysisSummary = json['analysisSummary'] as String? ?? 'Analysis completed.';
            anomalyScore = (json['anomalyScore'] as num?)?.toInt() ?? 50;
          }
        } catch (e) {
          debugPrint('Gemini EXIF forensics failed: $e');
        }
      }

      findings.add(OsintFinding(label: 'Forensic Verdict', value: forensicVerdict));
      findings.add(OsintFinding(label: 'Anomaly Score', value: '$anomalyScore/100'));
      findings.add(OsintFinding(label: 'AI Forensic Summary', value: analysisSummary));

      return OsintResult(
        queryType:  OsintQueryType.image,
        query:      filePath,
        findings:   findings,
        sources:    const ['On-device EXIF parser', 'DeepTruth AI Visual Forensics'],
        riskLevel:  riskLevel,
        analyzedAt: DateTime.now(),
      );
    } catch (e) {
      debugPrint('analyzeImageMetadata failed: $e');
      return OsintResult.error(OsintQueryType.image, filePath, 'Forensic lookup failed: $e');
    }
  }
}

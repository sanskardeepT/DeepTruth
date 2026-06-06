import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../constants/api_keys.dart';
import '../constants/app_constants.dart';
import '../models/osint_result.dart';

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
            'user-agent':     'LensIQ-App',
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
          headers: {'User-Agent': 'LensIQ/1.0'},
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
}

import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import '../models/check_result.dart';
import '../models/impact_result.dart';
import '../models/report_model.dart';
import '../services/admob_service.dart';
import '../services/fact_check_service.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../services/streak_service.dart';
import '../utils/error_handler.dart';
import '../utils/silent_profiler.dart';

enum CheckState { idle, loading, loadingImpact, done, error }

class CheckProvider extends ChangeNotifier {
  CheckState _state = CheckState.idle;
  CheckResult? _result;
  ImpactResult? _impactResult;
  ReportModel? _reportModel;
  String? _errorMessage;
  String? _prefilledContent;

  CheckState  get state          => _state;
  CheckResult? get result        => _result;
  ImpactResult? get impactResult => _impactResult;
  ReportModel? get reportModel   => _reportModel;
  String?     get errorMessage   => _errorMessage;
  String?     get prefilledContent => _prefilledContent;

  void prefillContent(String content) {
    _prefilledContent = content;
    notifyListeners();
  }

  void clearPrefill() {
    _prefilledContent = null;
    notifyListeners();
  }

  bool get isIdle        => _state == CheckState.idle;
  bool get isLoading     => _state == CheckState.loading;
  bool get isDone        => _state == CheckState.done;
  bool get isError       => _state == CheckState.error;

  // ── ANALYZE ───────────────────────────────────────────────────────
  Future<void> analyze(String content, {String? imagePath}) async {
    if (content.trim().isEmpty) {
      _errorMessage = 'Please enter some content to analyze.';
      _state = CheckState.error;
      notifyListeners();
      return;
    }

    _state        = CheckState.loading;
    _result       = null;
    _impactResult = null;
    _errorMessage = null;
    notifyListeners();

    try {
      Uint8List? imageBytes;
      String? mimeType;
      if (imagePath != null) {
        final file = File(imagePath);
        if (await file.exists()) {
          imageBytes = await file.readAsBytes();
          final ext = imagePath.split('.').last.toLowerCase();
          if (ext == 'png') {
            mimeType = 'image/png';
          } else if (ext == 'webp') {
            mimeType = 'image/webp';
          } else {
            mimeType = 'image/jpeg';
          }
        }
      }

      // Run Gemini + FactCheck API in parallel
      final results = await Future.wait([
        GeminiService.instance.factCheck(
          content,
          imageBytes: imageBytes,
          mimeType: mimeType,
          localImagePath: imagePath,
        ),
        FactCheckService.instance.search(content),
      ]);

      var checkResult    = results[0] as CheckResult;
      final factChecks   = results[1] as List<Map<String, dynamic>>;

      // Merge fact-check API sources
      checkResult = FactCheckService.instance.mergeWithCheckResult(
        checkResult, factChecks,
      );

      _result = checkResult;
      _state  = CheckState.loadingImpact;
      notifyListeners();

      // Now calculate personal impact
      await _loadImpact(checkResult);

      // Track in analytics + profiler
      await Future.wait([
        FirebaseService.instance.logFactCheck(checkResult.verdict, checkResult.truthScore),
        SilentProfiler.instance.onCheckCompleted(checkResult.contentType),
        StreakService.instance.recordCheckCompleted(
          wasFake: checkResult.truthScore < 30,
          truthScore: checkResult.truthScore,
        ),
      ]);

      // Trigger interstitial ad frequency cap
      AdMobService.instance.onCheckCompleted();

      _state = CheckState.done;
      notifyListeners();
    } catch (e, st) {
      await ErrorHandler.record(e, st);
      _errorMessage = ErrorHandler.toUserMessage(e);
      _state        = CheckState.error;
      notifyListeners();
    }
  }

  Future<void> _loadImpact(CheckResult checkResult) async {
    try {
      const country   = 'Global'; // AppProvider provides this; simplified here
      final interests = SilentProfiler.instance.topInterests;
      _impactResult   = await GeminiService.instance.calculateImpact(
        checkResult: checkResult,
        country:     country,
        ageGroup:    'adult',
        interests:   interests,
      );
    } catch (_) {
      // Impact is optional — don't fail the whole check
    }
  }

  void reset() {
    _state        = CheckState.idle;
    _result       = null;
    _impactResult = null;
    _reportModel  = null;
    _errorMessage = null;
    notifyListeners();
  }
}

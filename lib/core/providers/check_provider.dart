import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../constants/app_constants.dart';
import '../models/check_result.dart';
import '../models/impact_result.dart';
import '../models/report_model.dart';
import '../services/admob_service.dart';
import '../services/fact_check_service.dart';
import '../services/firebase_service.dart';
import '../services/gemini_service.dart';
import '../services/streak_service.dart';
import '../services/verification_pipeline_orchestrator.dart';
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
  String _loadingStage = '';
  String _inputType = 'text';

  CheckState  get state          => _state;
  CheckResult? get result        => _result;
  ImpactResult? get impactResult => _impactResult;
  ReportModel? get reportModel   => _reportModel;
  String?     get errorMessage   => _errorMessage;
  String?     get prefilledContent => _prefilledContent;
  String      get loadingStage   => _loadingStage;
  String      get inputType      => _inputType;

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

    final limit = FirebaseService.instance.dailyScanLimit;
    final todayCount = _getScansToday();
    if (todayCount >= limit) {
      _errorMessage = 'Daily scan limit of $limit reached. Please try again tomorrow!';
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

      // Determine input type for the verification pipeline
      String inputType = 'text';
      String contentToVerify = content;

      if (imagePath != null) {
        final lower = imagePath.toLowerCase();
        if (lower.endsWith('.mp4') || lower.endsWith('.mov') || lower.endsWith('.avi') || lower.endsWith('.mkv')) {
          inputType = 'video';
        } else {
          inputType = 'image';
        }
        contentToVerify = imagePath;
      } else if (content.startsWith('http://') || content.startsWith('https://')) {
        final lower = content.toLowerCase();
        if (lower.contains('youtube.com') || lower.contains('youtu.be') || lower.contains('instagram.com/reel')) {
          inputType = 'video';
        } else {
          inputType = 'url';
        }
      }

      _inputType = inputType;

      // Execute through verification orchestrator (C2PA, EXIF, Wayback, Google CSE, and Evidence Vault)
      final checkResult = await VerificationPipelineOrchestrator.instance.verify(
        inputType: inputType,
        originalContent: contentToVerify,
        fileBytes: imageBytes,
        onStageChanged: (stage) {
          _loadingStage = stage;
          notifyListeners();
        },
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

      // Increment daily scan count
      await _incrementScansToday();

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
    _loadingStage = '';
    notifyListeners();
  }

  void loadResult(CheckResult result) {
    _state = CheckState.done;
    _result = result;
    _impactResult = null; // Re-compute personal impact could be added if needed, but not critical
    notifyListeners();
  }

  int _getScansToday() {
    try {
      if (Hive.isBoxOpen(AppConstants.boxSettings)) {
        final box = Hive.box<String>(AppConstants.boxSettings);
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final val = box.get('scans_count_$todayStr');
        if (val != null) return int.tryParse(val) ?? 0;
      }
    } catch (_) {}
    return 0;
  }

  Future<void> _incrementScansToday() async {
    try {
      if (Hive.isBoxOpen(AppConstants.boxSettings)) {
        final box = Hive.box<String>(AppConstants.boxSettings);
        final todayStr = DateTime.now().toIso8601String().substring(0, 10);
        final current = _getScansToday();
        await box.put('scans_count_$todayStr', (current + 1).toString());
      }
    } catch (_) {}
  }
}


import '../models/check_result.dart';
import '../models/impact_result.dart';
import '../utils/location_detector.dart';
import '../utils/silent_profiler.dart';
import 'gemini_service.dart';

class ImpactEngineService {
  ImpactEngineService._();
  static final ImpactEngineService instance = ImpactEngineService._();

  Future<ImpactResult> calculatePersonalImpact(CheckResult checkResult) async {
    final country   = await LocationDetector.instance.getCountry();
    final interests = SilentProfiler.instance.topInterests;
    final ageGroup  = SilentProfiler.instance.inferredAgeGroup ?? 'adult';

    return GeminiService.instance.calculateImpact(
      checkResult: checkResult,
      country:     country,
      ageGroup:    ageGroup,
      interests:   interests,
    );
  }
}

import 'dart:typed_data';
import 'c2pa_engine.dart';
import 'provenance_engine.dart';
import 'deepfake_engine.dart';
import '../services/threat_intel_service.dart';
import '../services/fact_check_service.dart';
import '../services/reverse_image_service.dart';
import '../models/trust_verification_models.dart';
import '../models/osint_result.dart';

abstract class VerificationPlugin {
  String get id;
  bool supports(String inputType);
  Future<dynamic> execute(String originalContent, Uint8List? fileBytes);
}

class C2PaPlugin implements VerificationPlugin {
  @override
  String get id => 'c2pa';

  @override
  bool supports(String inputType) => inputType == 'image';

  @override
  Future<C2PAResult> execute(String originalContent, Uint8List? fileBytes) async {
    return C2paEngine.instance.verifyAsset(originalContent, fileBytes);
  }
}

class ProvenancePlugin implements VerificationPlugin {
  @override
  String get id => 'provenance';

  @override
  bool supports(String inputType) => inputType == 'image';

  @override
  Future<ProvenanceResult> execute(String originalContent, Uint8List? fileBytes) async {
    return ProvenanceEngine.instance.analyzeAsset(originalContent);
  }
}

class DeepfakePlugin implements VerificationPlugin {
  @override
  String get id => 'deepfake';

  @override
  bool supports(String inputType) => inputType == 'image' || inputType == 'video';

  @override
  Future<DeepfakeResult> execute(String originalContent, Uint8List? fileBytes) async {
    return DeepfakeEngine.instance.scanAsset(originalContent, fileBytes);
  }
}

class ThreatIntelPlugin implements VerificationPlugin {
  @override
  String get id => 'threat_intel';

  @override
  bool supports(String inputType) => inputType == 'url';

  @override
  Future<OsintResult> execute(String originalContent, Uint8List? fileBytes) async {
    return ThreatIntelService.instance.fullUrlScan(originalContent);
  }
}

class FactCheckPlugin implements VerificationPlugin {
  @override
  String get id => 'fact_check';

  @override
  bool supports(String inputType) => inputType == 'text';

  @override
  Future<List<Map<String, dynamic>>> execute(String originalContent, Uint8List? fileBytes) async {
    return FactCheckService.instance.search(originalContent);
  }
}

class ReverseImagePlugin implements VerificationPlugin {
  @override
  String get id => 'reverse_image';

  @override
  bool supports(String inputType) => inputType == 'image';

  @override
  Future<OsintResult> execute(String originalContent, Uint8List? fileBytes) async {
    if (fileBytes != null && fileBytes.isNotEmpty) {
      return ReverseImageService.instance.scanReverseImage(fileBytes);
    }
    return OsintResult.error(
      OsintQueryType.url,
      'Reverse Image',
      'No image asset bytes provided.',
    );
  }
}

import 'check_result.dart';
import 'impact_result.dart';

class ReportModel {
  final String reportId;
  final CheckResult checkResult;
  final ImpactResult? impactResult;
  final DateTime generatedAt;
  final String? pdfLocalPath;
  final String? shareUrl;

  const ReportModel({
    required this.reportId,
    required this.checkResult,
    this.impactResult,
    required this.generatedAt,
    this.pdfLocalPath,
    this.shareUrl,
  });

  ReportModel copyWith({
    String? pdfLocalPath,
    String? shareUrl,
    ImpactResult? impactResult,
  }) {
    return ReportModel(
      reportId:      reportId,
      checkResult:   checkResult,
      impactResult:  impactResult ?? this.impactResult,
      generatedAt:   generatedAt,
      pdfLocalPath:  pdfLocalPath ?? this.pdfLocalPath,
      shareUrl:      shareUrl ?? this.shareUrl,
    );
  }
}

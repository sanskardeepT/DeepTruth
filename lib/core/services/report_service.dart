import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/check_result.dart';
import '../models/impact_result.dart';
import '../models/report_model.dart';
import '../utils/report_generator.dart';

class ReportService {
  ReportService._();
  static final ReportService instance = ReportService._();

  Future<ReportModel> generateAndShare(
    CheckResult checkResult, [
    ImpactResult? impactResult,
  ]) async {
    final report = ReportModel(
      reportId:     checkResult.reportId,
      checkResult:  checkResult,
      impactResult: impactResult,
      generatedAt:  DateTime.now(),
    );

    try {
      final pdfBytes = await ReportGenerator.generate(report);
      final dir      = await getApplicationDocumentsDirectory();
      final file     = File('${dir.path}/${report.reportId}.pdf');
      await file.writeAsBytes(pdfBytes);

      final updatedReport = report.copyWith(pdfLocalPath: file.path);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'LensIQ Verified Intelligence Report — ${report.reportId}',
      );

      return updatedReport;
    } catch (e) {
      debugPrint('ReportService.generateAndShare failed: $e');
      return report;
    }
  }

  Future<String?> generatePdfPath(
    CheckResult checkResult, [
    ImpactResult? impactResult,
  ]) async {
    try {
      final report = ReportModel(
        reportId:     checkResult.reportId,
        checkResult:  checkResult,
        impactResult: impactResult,
        generatedAt:  DateTime.now(),
      );
      final pdfBytes = await ReportGenerator.generate(report);
      final dir      = await getApplicationDocumentsDirectory();
      final file     = File('${dir.path}/${report.reportId}.pdf');
      await file.writeAsBytes(pdfBytes);
      return file.path;
    } catch (e) {
      debugPrint('generatePdfPath failed: $e');
      return null;
    }
  }
}

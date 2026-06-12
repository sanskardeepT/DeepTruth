import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/check_result.dart';
import '../models/impact_result.dart';
import '../models/report_model.dart';
import '../utils/report_generator.dart';
import '../utils/image_card_generator.dart';
import 'firebase_service.dart';

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

      // Generate PNG Image Card
      String? imagePath;
      try {
        final cardBytes = ImageCardGenerator.generateCard(checkResult);
        final imgFile   = File('${dir.path}/card_${report.reportId}.png');
        await imgFile.writeAsBytes(cardBytes);
        imagePath = imgFile.path;
      } catch (e) {
        debugPrint('Failed to generate image card during share: $e');
      }

      final updatedReport = report.copyWith(pdfLocalPath: file.path);

      final shareText = '🚨 DeepTruth Trust Verification Card\n\n'
          'Verdict: ${checkResult.verdict} ${checkResult.verdictEmoji}\n'
          'Trust Score: ${checkResult.truthScore}/100\n'
          'Timestamp: ${checkResult.analyzedAt.toLocal().toString().substring(0, 19)}\n\n'
          'Expose fakes and trace OSINT using DeepTruth: https://deeptruth.app/verify/${report.reportId}';

      final filesToShare = <XFile>[XFile(file.path)];
      if (imagePath != null) {
        filesToShare.add(XFile(imagePath));
      }

      await Share.shareXFiles(
        filesToShare,
        subject: 'DeepTruth Verified Intelligence Report — ${report.reportId}',
        text: shareText,
      );

      // Track share in analytics
      try {
        await FirebaseService.instance.logEvent('report_shared', {
          'reportId': report.reportId,
          'verdict': checkResult.verdict,
          'score': checkResult.truthScore,
        });
      } catch (_) {}

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

      // Track export in analytics
      try {
        await FirebaseService.instance.logEvent('report_exported', {
          'reportId': checkResult.reportId,
          'contentType': checkResult.contentType,
        });
      } catch (_) {}

      return file.path;
    } catch (e) {
      debugPrint('generatePdfPath failed: $e');
      return null;
    }
  }

  Future<String?> generateImageCardPath(CheckResult checkResult) async {
    try {
      final cardBytes = ImageCardGenerator.generateCard(checkResult);
      final dir = await getApplicationDocumentsDirectory();
      final file = File('${dir.path}/card_${checkResult.reportId}.png');
      await file.writeAsBytes(cardBytes);
      return file.path;
    } catch (e) {
      debugPrint('generateImageCardPath failed: $e');
      return null;
    }
  }
}

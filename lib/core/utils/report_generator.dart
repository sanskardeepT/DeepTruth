import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:qr_flutter/qr_flutter.dart';
import '../constants/app_colors.dart';
import '../models/report_model.dart';

class ReportGenerator {
  ReportGenerator._();

  static Future<Uint8List> generate(ReportModel report) async {
    final pdf = pw.Document();
    final cr  = report.checkResult;
    final ir  = report.impactResult;

    // ── COLOR HELPERS ──
    final scoreColor = _scoreColor(cr.truthScore);
    final verdictBg  = _verdictBg(cr.verdict);

    // ── PAGE 1 ────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => pw.Stack(
          children: [
            // Watermark
            pw.Positioned.fill(
              child: pw.Center(
                child: pw.Transform.rotate(
                  angle: -0.5,
                  child: pw.Text(
                    'LensIQ',
                    style: pw.TextStyle(
                      fontSize: 80,
                      color: PdfColor.fromHex('#0A0E27').flatten().copyWith(alpha: 0.06),
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
            // Content
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(report),
                pw.SizedBox(height: 24),
                _buildSection('SECTION 1 — ORIGINAL CLAIM'),
                pw.SizedBox(height: 8),
                _buildClaimBox(cr.originalContent),
                pw.SizedBox(height: 20),
                _buildSection('SECTION 2 — VERDICT'),
                pw.SizedBox(height: 8),
                _buildVerdictRow(cr.verdict, cr.truthScore, scoreColor, verdictBg),
                pw.SizedBox(height: 12),
                pw.Text(
                  cr.explanation,
                  style: const pw.TextStyle(fontSize: 11),
                ),
                if (cr.missingContext != null) ...[
                  pw.SizedBox(height: 12),
                  _buildAmberBox('⚠ Missing Context: ${cr.missingContext}'),
                ],
                pw.Spacer(),
                _buildFooter(report.reportId, 1),
              ],
            ),
          ],
        ),
      ),
    );

    // ── PAGE 2 ────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSection('SECTION 3 — EVIDENCE'),
            pw.SizedBox(height: 8),
            if (cr.sources.isEmpty)
              pw.Text('No specific sources cited.', style: const pw.TextStyle(fontSize: 10))
            else
              ...cr.sources.asMap().entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 4),
                child: pw.Text(
                  '${e.key + 1}. ${e.value}',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              )),
            if (cr.manipulationTactics.isNotEmpty) ...[
              pw.SizedBox(height: 12),
              _buildSection('Manipulation Tactics Detected'),
              pw.SizedBox(height: 6),
              pw.Wrap(
                spacing: 6,
                runSpacing: 4,
                children: cr.manipulationTactics
                    .map((t) => _buildChip(t, PdfColors.red100))
                    .toList(),
              ),
            ],
            if (ir != null) ...[
              pw.SizedBox(height: 20),
              _buildSection('SECTION 4 — PERSONAL IMPACT'),
              pw.SizedBox(height: 8),
              pw.Text(ir.directImpact, style: const pw.TextStyle(fontSize: 11)),
              if (ir.financialImpact != null) ...[
                pw.SizedBox(height: 8),
                pw.Text('💰 Financial: ${ir.financialImpact}',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
              if (ir.healthImpact != null) ...[
                pw.SizedBox(height: 4),
                pw.Text('🏥 Health: ${ir.healthImpact}',
                    style: const pw.TextStyle(fontSize: 10)),
              ],
              pw.SizedBox(height: 12),
              _buildTimeline(ir.futureImpact6Months, ir.futureImpact1Year, ir.futureImpact5Years),
              if (ir.actionableSteps.isNotEmpty) ...[
                pw.SizedBox(height: 12),
                pw.Text('Recommended Actions:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 11)),
                pw.SizedBox(height: 4),
                ...ir.actionableSteps.asMap().entries.map((e) => pw.Text(
                  '${e.key + 1}. ${e.value}',
                  style: const pw.TextStyle(fontSize: 10),
                )),
              ],
            ],
            pw.Spacer(),
            _buildFooter(report.reportId, 2),
          ],
        ),
      ),
    );

    // ── PAGE 3 ────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildSection('SECTION 5 — ALL VERIFIED SOURCES'),
            pw.SizedBox(height: 8),
            if (cr.sources.isEmpty)
              pw.Text('No external sources cited for this analysis.',
                  style: const pw.TextStyle(fontSize: 10))
            else
              ...cr.sources.asMap().entries.map((e) => pw.Padding(
                padding: const pw.EdgeInsets.only(bottom: 6),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('${e.key + 1}. ${e.value}',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              )),
            pw.SizedBox(height: 24),
            _buildSection('SECTION 6 — REPORT VERIFICATION'),
            pw.SizedBox(height: 8),
            pw.Row(
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('Report ID: ${report.reportId}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 12)),
                    pw.SizedBox(height: 4),
                    pw.Text('Generated: ${report.generatedAt.toLocal().toString().substring(0, 19)}',
                        style: const pw.TextStyle(fontSize: 10)),
                    pw.SizedBox(height: 4),
                    pw.Text('Scan QR to verify this report →',
                        style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ],
            ),
            pw.Spacer(),
            _buildFooter(report.reportId, 3),
          ],
        ),
      ),
    );

    return pdf.save();
  }

  // ── WIDGET BUILDERS ───────────────────────────────────────────────
  static pw.Widget _buildHeader(ReportModel report) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text('LensIQ',
              style: pw.TextStyle(
                  fontSize: 22,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#00D4FF'))),
          pw.Text('VERIFIED INTELLIGENCE REPORT',
              style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(report.reportId,
              style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
          pw.Text(
            report.generatedAt.toLocal().toString().substring(0, 10),
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
        ]),
      ],
    );
  }

  static pw.Widget _buildSection(String title) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(title.toUpperCase(),
          style: pw.TextStyle(
              fontSize: 9,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
              letterSpacing: 1.2)),
      pw.Container(
        height: 1,
        color: PdfColor.fromHex('#2A2F50'),
        margin: const pw.EdgeInsets.only(top: 4),
      ),
    ]);
  }

  static pw.Widget _buildClaimBox(String content) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#1E2240'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColor.fromHex('#2A2F50')),
      ),
      child: pw.Text(
        content.length > 800 ? '${content.substring(0, 800)}…' : content,
        style: const pw.TextStyle(fontSize: 10),
      ),
    );
  }

  static pw.Widget _buildVerdictRow(
    String verdict, int score, PdfColor scoreColor, PdfColor verdictBg,
  ) {
    return pw.Row(
      children: [
        pw.Container(
          width: 72,
          height: 72,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: scoreColor, width: 3),
          ),
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('$score',
                    style: pw.TextStyle(
                        fontSize: 24,
                        fontWeight: pw.FontWeight.bold,
                        color: scoreColor)),
                pw.Text('/100',
                    style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 16),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: pw.BoxDecoration(
            color: verdictBg,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Text(
            verdict,
            style: pw.TextStyle(
                fontSize: 18,
                fontWeight: pw.FontWeight.bold,
                color: scoreColor),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildAmberBox(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#3D2E00'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColor.fromHex('#FFB800')),
      ),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 10)),
    );
  }

  static pw.Widget _buildChip(String label, PdfColor bg) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: pw.BoxDecoration(
        color: bg,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(20)),
      ),
      child: pw.Text(label, style: const pw.TextStyle(fontSize: 9)),
    );
  }

  static pw.Widget _buildTimeline(String m6, String y1, String y5) {
    return pw.Row(
      children: [
        _buildTimelineItem('6 Months', m6, PdfColor.fromHex('#00D4FF')),
        pw.SizedBox(width: 8),
        _buildTimelineItem('1 Year',   y1, PdfColor.fromHex('#7FFF00')),
        pw.SizedBox(width: 8),
        _buildTimelineItem('5 Years',  y5, PdfColor.fromHex('#FFB800')),
      ],
    );
  }

  static pw.Widget _buildTimelineItem(String period, String text, PdfColor color) {
    return pw.Expanded(
      child: pw.Container(
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: color, width: 2)),
          color: PdfColors.grey100,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(period,
                style: pw.TextStyle(
                    fontSize: 8, fontWeight: pw.FontWeight.bold, color: color)),
            pw.SizedBox(height: 4),
            pw.Text(
              text.isEmpty ? 'No data.' : text,
              style: const pw.TextStyle(fontSize: 9),
            ),
          ],
        ),
      ),
    );
  }

  static pw.Widget _buildFooter(String reportId, int page) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated by LensIQ | Data only. Conclusions are yours to make.',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
          pw.Text(
            '$reportId | Page $page',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
          ),
        ],
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────
  static PdfColor _scoreColor(int score) {
    if (score >= 81) return PdfColor.fromHex('#00FF88');
    if (score >= 61) return PdfColor.fromHex('#7FFF00');
    if (score >= 41) return PdfColor.fromHex('#FFB800');
    if (score >= 21) return PdfColor.fromHex('#FF6B35');
    return PdfColor.fromHex('#FF4757');
  }

  static PdfColor _verdictBg(String verdict) {
    switch (verdict) {
      case 'TRUE':       return PdfColor.fromHex('#003D22');
      case 'FALSE':      return PdfColor.fromHex('#3D0010');
      case 'MISLEADING': return PdfColor.fromHex('#3D2E00');
      default:           return PdfColor.fromHex('#1E2240');
    }
  }
}

// Needed for PdfColor alpha manipulation
extension on PdfColor {
  PdfColor copyWith({double? alpha}) => PdfColor(red, green, blue, alpha ?? this.alpha);
  PdfColor flatten() => this;
}

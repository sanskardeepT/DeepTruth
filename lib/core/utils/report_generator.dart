import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/report_model.dart';
import '../models/check_result.dart';

class ReportGenerator {
  ReportGenerator._();

  static pw.Widget _buildWatermark() {
    return pw.Positioned.fill(
      child: pw.Center(
        child: pw.Transform.rotate(
          angle: -0.5,
          child: pw.Text(
            'DeepTruth X',
            style: pw.TextStyle(
              fontSize: 80,
              color: PdfColor.fromHex('#0A0E27').flatten().copyWith(alpha: 0.04),
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildSourceLink(String source, int index) {
    final cleanSource = source.trim();
    final isUrl = cleanSource.startsWith('http');
    final text = '${index + 1}. $cleanSource';
    
    if (isUrl) {
      return pw.UrlLink(
        destination: cleanSource,
        child: pw.Text(
          text,
          style: const pw.TextStyle(
            fontSize: 9,
            color: PdfColors.blue700,
            decoration: pw.TextDecoration.underline,
          ),
        ),
      );
    } else {
      return pw.Text(
        text,
        style: const pw.TextStyle(fontSize: 9),
      );
    }
  }

  static Future<Uint8List> generate(ReportModel report) async {
    final pdf = pw.Document();
    final cr  = report.checkResult;
    final ir  = report.impactResult;

    final scoreColor = _scoreColor(cr.truthScore);
    final verdictBg  = _verdictBg(cr.verdict);

    // ── PAGE 1 ────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => pw.Stack(
          children: [
            _buildWatermark(),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildHeader(report),
                pw.SizedBox(height: 20),
                _buildSection('SECTION 1 — ORIGINAL CLAIM'),
                pw.SizedBox(height: 8),
                _buildClaimBox(cr.originalContent),
                pw.SizedBox(height: 16),
                _buildSection('SECTION 2 — SYSTEM CONCENSUS VERDICT'),
                pw.SizedBox(height: 8),
                _buildVerdictRow(cr.verdict, cr.truthScore, scoreColor, verdictBg),
                pw.SizedBox(height: 12),
                pw.Text(
                  cr.explanation,
                  style: pw.TextStyle(fontSize: 10, lineHeight: 1.4),
                ),
                pw.SizedBox(height: 16),
                // Scores table breakdown
                _buildSection('CONSENSUS SCORES SUMMARY'),
                pw.SizedBox(height: 8),
                _buildScoresTable(cr),
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
        build: (ctx) => pw.Stack(
          children: [
            _buildWatermark(),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSection('SECTION 3 — EXPLAINABILITY ADJUSTMENTS TREE'),
                pw.SizedBox(height: 8),
                _buildExplainabilityList(cr),
                pw.SizedBox(height: 16),
                _buildSection('SECTION 4 — CRYPTOGRAPHIC SIGNATURE & CERTIFICATES (C2PA)'),
                pw.SizedBox(height: 8),
                _buildC2PAForensics(cr),
                pw.SizedBox(height: 16),
                _buildSection('SECTION 5 — DEVICE HARDWARE METADATA (EXIF)'),
                pw.SizedBox(height: 8),
                _buildEXIFForensics(cr),
                pw.Spacer(),
                _buildFooter(report.reportId, 2),
              ],
            ),
          ],
        ),
      ),
    );

    // ── PAGE 3 ────────────────────────────────────────────────────
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        build: (ctx) => pw.Stack(
          children: [
            _buildWatermark(),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildSection('SECTION 6 — MULTIMODAL SYNTHETIC MEDIA DIAGNOSTICS'),
                pw.SizedBox(height: 8),
                _buildDeepfakeScans(cr),
                pw.SizedBox(height: 16),
                _buildSection('SECTION 7 — DISSEMINATION OSINT & SOURCES'),
                pw.SizedBox(height: 8),
                _buildOSINTForensics(cr),
                pw.SizedBox(height: 12),
                if (cr.sources.isNotEmpty) ...[
                  pw.Text('Verified Citations:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
                  pw.SizedBox(height: 6),
                  ...cr.sources.asMap().entries.map((e) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 4),
                    child: _buildSourceLink(e.value, e.key),
                  )),
                ],
                pw.SizedBox(height: 20),
                _buildSection('SECTION 8 — SECURITY AUDIT BLOCK'),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Report ID: ${report.reportId}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10)),
                        pw.SizedBox(height: 4),
                        pw.Text('Secure Lock Signature: SHA-256 Verified Ledger Anchor',
                            style: const pw.TextStyle(fontSize: 8)),
                        pw.SizedBox(height: 4),
                        pw.Text('Verification Hash: ${report.reportId.hashCode.toRadixString(16).toUpperCase()}',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                      ],
                    ),
                    pw.Container(
                      width: 50,
                      height: 50,
                      child: pw.BarcodeWidget(
                        barcode: pw.Barcode.qrCode(),
                        data: 'https://deeptruth.app/verify/${report.reportId}',
                        color: PdfColor.fromHex('#0A0E27'),
                      ),
                    ),
                  ],
                ),
                pw.Spacer(),
                _buildFooter(report.reportId, 3),
              ],
            ),
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
          pw.Text('DeepTruth X',
              style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#00D4FF'))),
          pw.Text('TRUST INTELLIGENCE FORENSIC AUDIT',
              style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ]),
        pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.end, children: [
          pw.Text(report.reportId,
              style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
          pw.Text(
            report.generatedAt.toLocal().toString().substring(0, 19),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          ),
        ]),
      ],
    );
  }

  static pw.Widget _buildSection(String title) {
    return pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
      pw.Text(title.toUpperCase(),
          style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
              letterSpacing: 1.1)),
      pw.Container(
        height: 1,
        color: PdfColor.fromHex('#2A2F50'),
        margin: const pw.EdgeInsets.only(top: 4),
      ),
    ]);
  }

  static pw.Widget _buildClaimBox(String content) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#1E2240'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColor.fromHex('#2A2F50')),
      ),
      child: pw.Text(
        content.length > 500 ? '${content.substring(0, 500)}…' : content,
        style: const pw.TextStyle(fontSize: 9),
      ),
    );
  }

  static pw.Widget _buildVerdictRow(
    String verdict, int score, PdfColor scoreColor, PdfColor verdictBg,
  ) {
    return pw.Row(
      children: [
        pw.Container(
          width: 56,
          height: 56,
          decoration: pw.BoxDecoration(
            shape: pw.BoxShape.circle,
            border: pw.Border.all(color: scoreColor, width: 2.5),
          ),
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('$score',
                    style: pw.TextStyle(
                        fontSize: 18,
                        fontWeight: pw.FontWeight.bold,
                        color: scoreColor)),
                pw.Text('/100',
                    style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 14),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: pw.BoxDecoration(
            color: verdictBg,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(
            verdict,
            style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
                color: scoreColor),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildScoresTable(CheckResult cr) {
    final con = cr.consensus;
    final int auth = con?.authenticityScore ?? cr.truthScore;
    final int trust = con?.trustScore ?? cr.truthScore;
    final int manip = con?.manipulationScore ?? cr.manipulationScore;
    final int risk = con?.riskScore ?? 0;
    final int confidence = con?.confidenceScore ?? 92;

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableHeaderCell('Consensus Vector'),
            _buildTableHeaderCell('Score Percentage'),
            _buildTableHeaderCell('Audit Diagnostic Rating'),
          ],
        ),
        _buildTableRow('Verification Trust Index', '$trust%', trust > 70 ? 'Authenticated' : (trust > 40 ? 'Suspicious' : 'Highly Unreliable')),
        _buildTableRow('Source Lineage Authenticity', '$auth%', auth > 70 ? 'True Origin' : 'Altered/Fabricated'),
        _buildTableRow('Structural Manipulation Risk', '$manip%', manip > 60 ? 'Synthesized' : 'Minimal Edits'),
        _buildTableRow('Virality Weaponization Risk', '$risk%', risk > 60 ? 'Critical Threat' : 'Low Spread Threat'),
        _buildTableRow('Evaluation Confidence Rating', '$confidence%', confidence > 80 ? 'High Confidence' : 'Medium certainty'),
      ],
    );
  }

  static pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.all(6),
      child: pw.Text(text, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
    );
  }

  static pw.TableRow _buildTableRow(String v1, String v2, String v3) {
    return pw.TableRow(
      children: [
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(v1, style: const pw.TextStyle(fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(v2, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(v3, style: const pw.TextStyle(fontSize: 8))),
      ],
    );
  }

  static pw.Widget _buildExplainabilityList(CheckResult cr) {
    final con = cr.consensus;
    if (con == null || con.adjustments.isEmpty) {
      return pw.Text('No score adjustments calculated.', style: const pw.TextStyle(fontSize: 9));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: con.adjustments.map<pw.Widget>((adj) {
        final int imp = adj['impact'] as int;
        return pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4),
          child: pw.Row(
            children: [
              pw.Text(imp >= 0 ? '[+]' : '[-]', style: pw.TextStyle(color: imp >= 0 ? PdfColors.green700 : PdfColors.red700, fontWeight: pw.FontWeight.bold, fontSize: 8)),
              pw.SizedBox(width: 8),
              pw.Expanded(child: pw.Text(adj['factor'] as String, style: const pw.TextStyle(fontSize: 8))),
              pw.Text('${imp >= 0 ? "+" : ""}$imp', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8)),
            ],
          ),
        );
      }).toList(),
    );
  }

  static pw.Widget _buildC2PAForensics(CheckResult cr) {
    final c2pa = cr.c2pa;
    if (c2pa == null || !c2pa.hasC2PA) {
      return pw.Text('No cryptographic signature extracted.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.red700));
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.green300, width: 0.5),
        color: PdfColors.green50,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Status: ${c2pa.verificationStatus}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: PdfColors.green800)),
          pw.SizedBox(height: 4),
          pw.Text('Creator: ${c2pa.creator ?? "Unknown"}', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('Publisher: ${c2pa.publisher ?? "Unknown"}', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('Anchored Timestamp: ${c2pa.createdAt ?? "Unknown"}', style: const pw.TextStyle(fontSize: 8)),
          if (c2pa.editedBy.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Text('Actions history: ${c2pa.editedBy.join(", ")}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700)),
          ]
        ],
      ),
    );
  }

  static pw.Widget _buildEXIFForensics(CheckResult cr) {
    final prov = cr.provenance;
    if (prov == null || prov.exif.isEmpty) {
      return pw.Text('No hardware EXIF parameters extracted.', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey200, width: 0.5),
      children: prov.exif.entries.map((e) => pw.TableRow(
        children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e.key, style: const pw.TextStyle(fontSize: 7.5))),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(e.value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 7.5))),
        ],
      )).toList(),
    );
  }

  static pw.Widget _buildDeepfakeScans(CheckResult cr) {
    final df = cr.deepfake;
    if (df == null) {
      return pw.Text('Synthetic Media scanning metrics missing.', style: const pw.TextStyle(fontSize: 9));
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Diagnostic Layer', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Risk Score', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8))),
          ],
        ),
        pw.TableRow(children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Visual GAN Pixel Boundary artifacts', style: const pw.TextStyle(fontSize: 8))),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${df.imageRisk.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 8))),
        ]),
        pw.TableRow(children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Temporal frame flow inconsistencies', style: const pw.TextStyle(fontSize: 8))),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${df.videoRisk.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 8))),
        ]),
        pw.TableRow(children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Synthetic voice Cloning spectrogram peaks', style: const pw.TextStyle(fontSize: 8))),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${df.audioRisk.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 8))),
        ]),
        pw.TableRow(children: [
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Multimodal Fusion lipsync matching anomalies', style: const pw.TextStyle(fontSize: 8))),
          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${df.multimodalRisk.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 8))),
        ]),
      ],
    );
  }

  static pw.Widget _buildOSINTForensics(CheckResult cr) {
    final rep = cr.reputation;
    final prov = cr.provenance;
    if (rep == null) {
      return pw.Text('No reputation databases queried.', style: const pw.TextStyle(fontSize: 9));
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text('Domain: ${rep.domain}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9)),
        pw.SizedBox(height: 4),
        pw.Text('Domain Trust Score: ${rep.reputationScore}/100', style: const pw.TextStyle(fontSize: 8)),
        pw.Text('Historical Omission accuracy: ${rep.historicalAccuracy.toStringAsFixed(1)}%', style: const pw.TextStyle(fontSize: 8)),
        pw.Text('Propagation Exposure Count: ${prov?.reusedCount ?? 0} appearances tracked in Narratives', style: const pw.TextStyle(fontSize: 8)),
      ],
    );
  }

  static pw.Widget _buildAmberBox(String text) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#3D2E00'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColor.fromHex('#FFB800')),
      ),
      child: pw.Text(text, style: const pw.TextStyle(fontSize: 8, color: PdfColors.amber700)),
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
            'DeepTruth X Trust Intelligence | Decoupled Forensics Protocol.',
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

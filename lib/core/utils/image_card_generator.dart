import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/check_result.dart';

class ImageCardGenerator {
  ImageCardGenerator._();

  /// Generates a high-fidelity, premium shareable PNG image card of the verification result.
  static Uint8List generateCard(CheckResult result) {
    // 1. Create a 600x320 canvas
    final image = img.Image(width: 600, height: 320);
    
    // 2. Fill background with a beautiful diagonal deep space gradient (navy to purple-tinted indigo)
    for (int y = 0; y < image.height; y++) {
      for (int x = 0; x < image.width; x++) {
        final double ratio = (x + y) / (image.width + image.height);
        // Gradient from #0A0E27 (10, 14, 39) to #1C2046 (28, 32, 70)
        final int r = (10 + (18 * ratio)).toInt();
        final int g = (14 + (18 * ratio)).toInt();
        final int b = (39 + (31 * ratio)).toInt();
        image.setPixel(x, y, img.ColorRgb8(r, g, b));
      }
    }

    // 3. Draw outer cyan glow border outline
    final borderColor = img.ColorRgb8(0, 212, 255);
    img.drawRect(
      image,
      x1: 12,
      y1: 12,
      x2: 588,
      y2: 308,
      color: borderColor,
    );

    // 4. Draw Watermark logo signature
    final watermarkColor = img.ColorRgb8(45, 52, 98);
    img.drawString(
      image,
      'DEEPTRUTH TIOS',
      font: img.arial24,
      x: 370,
      y: 260,
      color: watermarkColor,
    );

    // 5. Draw Title Header
    final headerColor = img.ColorRgb8(0, 212, 255);
    img.drawString(
      image,
      'DEEPTRUTH TRUST REPORT CARD',
      font: img.arial14,
      x: 35,
      y: 35,
      color: headerColor,
    );

    // 6. Draw Verdict & Score
    final score = result.truthScore;
    final verdict = result.verdict;
    
    img.Color badgeColor;
    if (score >= 80) {
      badgeColor = img.ColorRgb8(0, 200, 100); // Premium Green
    } else if (score >= 45) {
      badgeColor = img.ColorRgb8(230, 160, 0); // Premium Amber/Orange
    } else {
      badgeColor = img.ColorRgb8(220, 50, 70); // Premium Red
    }

    // 7. Draw filled solid badge card for the verdict
    for (int y = 85; y < 125; y++) {
      for (int x = 35; x < 235; x++) {
        image.setPixel(x, y, badgeColor);
      }
    }

    // Draw text inside the verdict badge
    img.drawString(
      image,
      'VERDICT: $verdict',
      font: img.arial14,
      x: 50,
      y: 98,
      color: img.ColorRgb8(255, 255, 255), // White text inside colored badge
    );

    // Draw Score
    final textColor = img.ColorRgb8(255, 255, 255);
    img.drawString(
      image,
      'Trust Score: $score/100',
      font: img.arial24,
      x: 35,
      y: 150,
      color: textColor,
    );

    // 8. Draw metadata details
    final dateStr = result.analyzedAt.toLocal().toString().substring(0, 19);
    img.drawString(
      image,
      'Timestamp: $dateStr',
      font: img.arial14,
      x: 35,
      y: 215,
      color: img.ColorRgb8(180, 182, 205),
    );

    img.drawString(
      image,
      'Report ID: ${result.reportId}',
      font: img.arial14,
      x: 35,
      y: 245,
      color: img.ColorRgb8(140, 142, 165),
    );

    // 9. Return PNG encoded bytes
    return Uint8List.fromList(img.encodePng(image));
  }
}

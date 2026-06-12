import 'dart:typed_data';
import 'package:image/image.dart' as img;
import '../models/check_result.dart';

class ImageCardGenerator {
  ImageCardGenerator._();

  /// Generates a shareable PNG image card of the verification result.
  static Uint8List generateCard(CheckResult result) {
    // 1. Create a 600x320 canvas
    final image = img.Image(width: 600, height: 320);
    
    // 2. Fill background with dark navy blue (#0A0E27)
    final bgColor = img.ColorRgb8(10, 14, 39);
    img.fill(image, color: bgColor);

    // 3. Draw outline border in accent cyan
    final borderColor = img.ColorRgb8(0, 212, 255);
    img.drawRect(
      image,
      x1: 10,
      y1: 10,
      x2: 590,
      y2: 310,
      color: borderColor,
    );

    // 4. Draw Watermark text
    final watermarkColor = img.ColorRgb8(30, 35, 65);
    img.drawString(
      image,
      'DEEPTRUTH TIOS',
      font: img.arial24,
      x: 350,
      y: 260,
      color: watermarkColor,
    );

    // 5. Draw Title
    final textColor = img.ColorRgb8(255, 255, 255);
    img.drawString(
      image,
      'DEEPTRUTH TRUST VERIFICATION CARD',
      font: img.arial14,
      x: 30,
      y: 30,
      color: textColor,
    );

    // 6. Draw Verdict & Score
    final score = result.truthScore;
    final verdict = result.verdict;
    
    img.Color scoreColor;
    if (score >= 80) {
      scoreColor = img.ColorRgb8(0, 255, 136); // Green
    } else if (score >= 45) {
      scoreColor = img.ColorRgb8(255, 184, 0); // Orange/Amber
    } else {
      scoreColor = img.ColorRgb8(255, 71, 87); // Red
    }

    img.drawString(
      image,
      'Verdict: $verdict',
      font: img.arial24,
      x: 30,
      y: 100,
      color: scoreColor,
    );

    img.drawString(
      image,
      'Trust Score: $score/100',
      font: img.arial24,
      x: 30,
      y: 140,
      color: textColor,
    );

    // 7. Draw metadata details
    final dateStr = result.analyzedAt.toLocal().toString().substring(0, 19);
    img.drawString(
      image,
      'Timestamp: $dateStr',
      font: img.arial14,
      x: 30,
      y: 220,
      color: img.ColorRgb8(180, 180, 180),
    );

    img.drawString(
      image,
      'Report ID: ${result.reportId}',
      font: img.arial14,
      x: 30,
      y: 250,
      color: img.ColorRgb8(150, 150, 150),
    );

    // 8. Return PNG encoded bytes
    return Uint8List.fromList(img.encodePng(image));
  }
}

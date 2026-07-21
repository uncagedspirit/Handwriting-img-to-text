import 'dart:io';
import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:image/image.dart' as img;
import 'package:handwriting_to_text/core/utils/image_enhancer.dart';

/// Builds a page-sized image that resembles a photographed note: off-white
/// paper, a lighting gradient, and dark strokes.
File _writeSyntheticPage(Directory dir, int width, int height) {
  final image = img.Image(width: width, height: height);
  final random = Random(7);

  for (var y = 0; y < height; y++) {
    // Uneven lighting across the page, like a real phone photo.
    final shade = 190 + (40 * y / height).round();
    for (var x = 0; x < width; x++) {
      final noise = random.nextInt(8);
      final v = (shade + noise).clamp(0, 255);
      image.setPixelRgb(x, y, v, v, v);
    }
  }

  // Horizontal "text" strokes.
  for (var line = 0; line < 30; line++) {
    final y = 40 + line * (height ~/ 32);
    if (y + 6 >= height) break;
    for (var x = 60; x < width - 60; x++) {
      if (random.nextInt(4) == 0) continue;
      for (var t = 0; t < 5; t++) {
        image.setPixelRgb(x, y + t, 30, 30, 30);
      }
    }
  }

  final file = File('${dir.path}/synthetic_page.jpg');
  file.writeAsBytesSync(img.encodeJpg(image, quality: 90));
  return file;
}

void main() {
  late Directory workDir;

  setUpAll(() {
    workDir = Directory.systemTemp.createTempSync('enhancer_test');
  });

  tearDownAll(() {
    if (workDir.existsSync()) workDir.deleteSync(recursive: true);
  });

  test('builds both OCR variants from a single decode within a sane budget', () async {
    // 2200x2933 matches the capture cap, i.e. the largest image the
    // pipeline should ever see in practice.
    final source = _writeSyntheticPage(workDir, 2200, 2933);
    const enhancer = ImageEnhancer();

    final stopwatch = Stopwatch()..start();
    final variants = await enhancer.buildOcrVariants(
      source,
      '${workDir.path}/enhanced.jpg',
      '${workDir.path}/binarized.jpg',
    );
    stopwatch.stop();

    final enhanced = File(variants.enhancedPath);
    final binarized = File(variants.binarizedPath);

    expect(enhanced.existsSync(), isTrue);
    expect(binarized.existsSync(), isTrue);
    expect(enhanced.lengthSync(), greaterThan(0));
    expect(binarized.lengthSync(), greaterThan(0));

    // Both variants are produced from one decode; the old implementation
    // decoded twice and ran a 3x3 convolution, which took far longer.
    // Desktop CI is much faster than a phone, so this is a loose ceiling
    // that still catches a regression back to the old approach.
    expect(stopwatch.elapsed, lessThan(const Duration(seconds: 20)));

    // The binarized variant must actually be black and white.
    final decoded = img.decodeImage(binarized.readAsBytesSync())!;
    final sample = <int>{};
    for (var y = 0; y < decoded.height; y += 97) {
      for (var x = 0; x < decoded.width; x += 97) {
        sample.add(decoded.getPixel(x, y).r.toInt());
      }
    }
    // JPEG introduces ringing, so allow near-black/near-white rather than
    // exactly two values.
    expect(sample.every((v) => v < 60 || v > 195), isTrue);
  });

  test('manual adjustments are skipped entirely when neutral', () async {
    final source = _writeSyntheticPage(workDir, 600, 800);
    const enhancer = ImageEnhancer();

    final result = await enhancer.applyManualAdjustments(
      source,
      '${workDir.path}/neutral.jpg',
      const ManualAdjustments(),
    );

    expect(result.lengthSync(), source.lengthSync());
  });
}

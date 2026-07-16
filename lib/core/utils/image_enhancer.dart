import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Pixel-level adjustments applied to a captured page before recognition.
/// Values are user-facing multipliers/offsets, centered at their neutral
/// default so `0` always means "no change".
class ManualAdjustments {
  const ManualAdjustments({this.brightness = 0, this.contrast = 0});

  /// -100..100, 0 = unchanged.
  final double brightness;

  /// -100..100, 0 = unchanged.
  final double contrast;

  bool get isNeutral => brightness == 0 && contrast == 0;
}

class _ManualAdjustArgs {
  const _ManualAdjustArgs(this.bytes, this.brightness, this.contrast);
  final Uint8List bytes;
  final double brightness;
  final double contrast;
}

class _RotateArgs {
  const _RotateArgs(this.bytes, this.degrees);
  final Uint8List bytes;
  final int degrees;
}

/// Applies automatic and manual image enhancement to improve OCR accuracy,
/// entirely on-device using the `image` package (no native dependency).
/// Heavy pixel work runs on a background isolate via [compute] so the UI
/// thread never blocks.
class ImageEnhancer {
  const ImageEnhancer();

  /// Improves contrast and sharpness so handwriting is easier to recognize.
  Future<File> autoEnhance(File source, String outputPath) async {
    final bytes = await source.readAsBytes();
    final result = await compute(_autoEnhanceBytes, bytes);
    final output = File(outputPath);
    await output.writeAsBytes(result, flush: true);
    return output;
  }

  /// Applies manual brightness/contrast on top of the original image.
  Future<File> applyManualAdjustments(
    File source,
    String outputPath,
    ManualAdjustments adjustments,
  ) async {
    if (adjustments.isNeutral) {
      return source.copy(outputPath);
    }
    final bytes = await source.readAsBytes();
    final result = await compute(
      _applyManualAdjustments,
      _ManualAdjustArgs(bytes, adjustments.brightness, adjustments.contrast),
    );
    final output = File(outputPath);
    await output.writeAsBytes(result, flush: true);
    return output;
  }

  Future<File> rotate(File source, String outputPath, int degrees) async {
    final bytes = await source.readAsBytes();
    final result = await compute(_rotateBytes, _RotateArgs(bytes, degrees));
    final output = File(outputPath);
    await output.writeAsBytes(result, flush: true);
    return output;
  }
}

Uint8List _autoEnhanceBytes(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  var image = img.copyResize(decoded, width: decoded.width > 3200 ? 3200 : decoded.width);

  // Grayscale removes color noise the recognizer doesn't need, then a
  // percentile-based levels stretch adapts to the photo's actual lighting:
  // dim, shadowed pages get pulled to full range while already-good pages
  // are barely touched. This beats a fixed contrast multiplier, which
  // blows out faint pencil strokes on bright pages and does too little on
  // dark ones. The sharpen blends at low strength to avoid halo artifacts.
  image = img.grayscale(image);
  image = _stretchLevels(image, lowPercentile: 0.02, highPercentile: 0.98);
  image = img.convolution(image, filter: [0, -1, 0, -1, 5, -1, 0, -1, 0], div: 1, amount: 0.3);
  return Uint8List.fromList(img.encodeJpg(image, quality: 95));
}

/// Linearly remaps luminance so the given low/high percentiles land at
/// 0 and 255, ignoring outlier pixels (specks, glare) that would defeat a
/// simple min/max normalization.
img.Image _stretchLevels(
  img.Image image, {
  required double lowPercentile,
  required double highPercentile,
}) {
  final histogram = List<int>.filled(256, 0);
  for (final pixel in image) {
    histogram[pixel.r.toInt().clamp(0, 255)]++;
  }
  final totalPixels = image.width * image.height;

  int low = 0;
  int cumulative = 0;
  for (var i = 0; i < 256; i++) {
    cumulative += histogram[i];
    if (cumulative >= totalPixels * lowPercentile) {
      low = i;
      break;
    }
  }

  int high = 255;
  cumulative = 0;
  for (var i = 255; i >= 0; i--) {
    cumulative += histogram[i];
    if (cumulative >= totalPixels * (1 - highPercentile)) {
      high = i;
      break;
    }
  }

  if (high - low < 32) return image; // Nearly flat image; stretching would only amplify noise.

  final range = high - low;
  for (final pixel in image) {
    final value = (((pixel.r - low) / range) * 255).clamp(0, 255).toInt();
    pixel
      ..r = value
      ..g = value
      ..b = value;
  }
  return image;
}

Uint8List _applyManualAdjustments(_ManualAdjustArgs args) {
  final decoded = img.decodeImage(args.bytes);
  if (decoded == null) return args.bytes;
  final brightnessFactor = (1.0 + (args.brightness / 100.0)).clamp(0.2, 2.0);
  final contrastFactor = (1.0 + (args.contrast / 100.0)).clamp(0.2, 2.0);
  final image = img.adjustColor(decoded, brightness: brightnessFactor, contrast: contrastFactor);
  return Uint8List.fromList(img.encodeJpg(image, quality: 92));
}

Uint8List _rotateBytes(_RotateArgs args) {
  final decoded = img.decodeImage(args.bytes);
  if (decoded == null) return args.bytes;
  final rotated = img.copyRotate(decoded, angle: args.degrees);
  return Uint8List.fromList(img.encodeJpg(rotated, quality: 92));
}

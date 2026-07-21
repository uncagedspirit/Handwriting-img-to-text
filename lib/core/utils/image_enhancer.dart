import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

/// Working width for OCR variants. Handwriting on a page is comfortably
/// readable at this size, and every extra pixel costs pure-Dart decode,
/// filter and encode time on the user's phone.
const int _ocrWidth = 1600;

/// Cap for images the user keeps seeing (rotate output). Slightly higher so
/// the retained page still looks sharp when zoomed in review.
const int _displayWidth = 2000;

/// Pixel-level adjustments applied to a captured page before recognition.
/// Values are user-facing offsets centered on their neutral default, so `0`
/// always means "no change".
class ManualAdjustments {
  const ManualAdjustments({this.brightness = 0, this.contrast = 0});

  /// -100..100, 0 = unchanged.
  final double brightness;

  /// -100..100, 0 = unchanged.
  final double contrast;

  bool get isNeutral => brightness == 0 && contrast == 0;
}

/// The two derived images recognition can try in addition to the original.
class OcrVariants {
  const OcrVariants({required this.enhancedPath, required this.binarizedPath});

  final String enhancedPath;
  final String binarizedPath;

  List<String> get paths => [enhancedPath, binarizedPath];
}

class _VariantArgs {
  const _VariantArgs(this.bytes);
  final Uint8List bytes;
}

class _VariantBytes {
  const _VariantBytes(this.enhanced, this.binarized);
  final Uint8List enhanced;
  final Uint8List binarized;
}

class _AdjustArgs {
  const _AdjustArgs(this.bytes, this.brightness, this.contrast);
  final Uint8List bytes;
  final double brightness;
  final double contrast;
}

class _RotateArgs {
  const _RotateArgs(this.bytes, this.degrees);
  final Uint8List bytes;
  final int degrees;
}

/// On-device image preparation for OCR. Every operation decodes the source
/// exactly once and runs on a background isolate, because JPEG decoding and
/// per-pixel filtering in pure Dart are by far the most expensive things
/// this app does.
class ImageEnhancer {
  const ImageEnhancer();

  /// Builds the enhanced and binarized variants in a single isolate call
  /// from a single decode — previously these were two calls that each
  /// decoded the full-size photo again.
  Future<OcrVariants> buildOcrVariants(
    File source,
    String enhancedPath,
    String binarizedPath,
  ) async {
    final bytes = await source.readAsBytes();
    final result = await compute(_buildVariants, _VariantArgs(bytes));
    await File(enhancedPath).writeAsBytes(result.enhanced, flush: true);
    await File(binarizedPath).writeAsBytes(result.binarized, flush: true);
    return OcrVariants(enhancedPath: enhancedPath, binarizedPath: binarizedPath);
  }

  /// Applies the brightness/contrast the user dialed in on the prepare
  /// screen. Skipped entirely when the values are neutral.
  Future<File> applyManualAdjustments(
    File source,
    String outputPath,
    ManualAdjustments adjustments,
  ) async {
    if (adjustments.isNeutral) return source.copy(outputPath);
    final bytes = await source.readAsBytes();
    final result = await compute(
      _applyAdjustments,
      _AdjustArgs(bytes, adjustments.brightness, adjustments.contrast),
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

/// Decodes, applies EXIF orientation (re-encoded copies lose the tag, so an
/// un-baked photo would come out sideways) and normalizes to [targetWidth].
img.Image? _decodeAndFit(Uint8List bytes, int targetWidth) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return null;
  var image = img.bakeOrientation(decoded);
  if (image.width > targetWidth) {
    // `average` costs a little more than nearest-neighbour but avoids the
    // aliasing that shreds thin pen strokes when downscaling.
    image = img.copyResize(image, width: targetWidth, interpolation: img.Interpolation.average);
  } else if (image.width < targetWidth ~/ 2) {
    // Very small imports: the recognizer struggles when glyphs are only a
    // few pixels tall.
    image = img.copyResize(image, width: image.width * 2, interpolation: img.Interpolation.cubic);
  }
  return image;
}

/// Extracts an 8-bit luminance plane. Working on this flat [Uint8List] is
/// an order of magnitude faster than the package's per-pixel accessors,
/// which allocate an object per pixel.
Uint8List _luminance(img.Image image) {
  final rgb = image.getBytes(order: img.ChannelOrder.rgb);
  final count = image.width * image.height;
  final gray = Uint8List(count);
  for (var i = 0, j = 0; i < count; i++, j += 3) {
    // Integer BT.601 luma: (77R + 150G + 29B) >> 8.
    gray[i] = (77 * rgb[j] + 150 * rgb[j + 1] + 29 * rgb[j + 2]) >> 8;
  }
  return gray;
}

Uint8List _encodeGray(Uint8List gray, int width, int height) {
  final image = img.Image.fromBytes(
    width: width,
    height: height,
    bytes: gray.buffer,
    numChannels: 1,
  );
  return img.encodeJpg(image, quality: 88);
}

_VariantBytes _buildVariants(_VariantArgs args) {
  final image = _decodeAndFit(args.bytes, _ocrWidth);
  if (image == null) return _VariantBytes(args.bytes, args.bytes);

  final width = image.width;
  final height = image.height;
  final gray = _luminance(image);

  final stretched = _stretchLevels(gray);
  final binarized = _adaptiveThreshold(stretched, width, height);

  return _VariantBytes(
    _encodeGray(stretched, width, height),
    _encodeGray(binarized, width, height),
  );
}

/// Percentile-based levels stretch: adapts to each photo's actual lighting
/// so dim pages are pulled to full range while good ones are barely
/// touched. Outlier pixels (glare, specks) are ignored.
Uint8List _stretchLevels(Uint8List gray) {
  final histogram = Int32List(256);
  for (var i = 0; i < gray.length; i++) {
    histogram[gray[i]]++;
  }

  final total = gray.length;
  final lowCut = (total * 0.02).round();
  final highCut = (total * 0.02).round();

  var low = 0;
  var cumulative = 0;
  for (var i = 0; i < 256; i++) {
    cumulative += histogram[i];
    if (cumulative >= lowCut) {
      low = i;
      break;
    }
  }

  var high = 255;
  cumulative = 0;
  for (var i = 255; i >= 0; i--) {
    cumulative += histogram[i];
    if (cumulative >= highCut) {
      high = i;
      break;
    }
  }

  // Nearly flat image: stretching would only amplify noise.
  if (high - low < 32) return gray;

  final lookup = Uint8List(256);
  final range = high - low;
  for (var v = 0; v < 256; v++) {
    lookup[v] = (((v - low) * 255) ~/ range).clamp(0, 255);
  }

  final out = Uint8List(gray.length);
  for (var i = 0; i < gray.length; i++) {
    out[i] = lookup[gray[i]];
  }
  return out;
}

/// Adaptive mean thresholding over an integral image: each pixel is judged
/// against its local neighbourhood, so shadows and uneven lighting don't
/// wipe out whole regions the way a single global threshold would. Strips
/// ruled lines and paper texture that confuse recognition.
Uint8List _adaptiveThreshold(Uint8List gray, int width, int height) {
  final stride = width + 1;
  final integral = Int32List(stride * (height + 1));
  for (var y = 0; y < height; y++) {
    var rowSum = 0;
    final rowStart = y * width;
    final outRow = (y + 1) * stride;
    final prevRow = y * stride;
    for (var x = 0; x < width; x++) {
      rowSum += gray[rowStart + x];
      integral[outRow + x + 1] = integral[prevRow + x + 1] + rowSum;
    }
  }

  final window = (width ~/ 16).clamp(15, 60);
  final half = window ~/ 2;
  const offsetPercent = 6; // Ink must be this much darker than its surroundings.

  final out = Uint8List(gray.length);
  for (var y = 0; y < height; y++) {
    final y0 = y - half < 0 ? 0 : y - half;
    final y1 = y + half >= height ? height - 1 : y + half;
    final top = y0 * stride;
    final bottom = (y1 + 1) * stride;
    final rowStart = y * width;
    for (var x = 0; x < width; x++) {
      final x0 = x - half < 0 ? 0 : x - half;
      final x1 = x + half >= width ? width - 1 : x + half;
      final area = (x1 - x0 + 1) * (y1 - y0 + 1);
      final sum = integral[bottom + x1 + 1] -
          integral[top + x1 + 1] -
          integral[bottom + x0] +
          integral[top + x0];
      final threshold = (sum * (100 - offsetPercent)) ~/ (area * 100);
      out[rowStart + x] = gray[rowStart + x] < threshold ? 0 : 255;
    }
  }
  return out;
}

Uint8List _applyAdjustments(_AdjustArgs args) {
  final image = _decodeAndFit(args.bytes, _displayWidth);
  if (image == null) return args.bytes;

  final brightness = (1.0 + args.brightness / 100.0).clamp(0.2, 2.0);
  final contrast = (1.0 + args.contrast / 100.0).clamp(0.2, 2.0);

  // Precomputed lookup table: one multiply-free byte read per channel
  // instead of recomputing the curve for every pixel.
  final lookup = Uint8List(256);
  for (var v = 0; v < 256; v++) {
    final adjusted = ((v * brightness - 127.5) * contrast + 127.5).round();
    lookup[v] = adjusted < 0 ? 0 : (adjusted > 255 ? 255 : adjusted);
  }

  final rgb = image.getBytes(order: img.ChannelOrder.rgb);
  for (var i = 0; i < rgb.length; i++) {
    rgb[i] = lookup[rgb[i]];
  }

  final out = img.Image.fromBytes(
    width: image.width,
    height: image.height,
    bytes: rgb.buffer,
    numChannels: 3,
  );
  return Uint8List.fromList(img.encodeJpg(out, quality: 90));
}

Uint8List _rotateBytes(_RotateArgs args) {
  final image = _decodeAndFit(args.bytes, _displayWidth);
  if (image == null) return args.bytes;
  final rotated = img.copyRotate(image, angle: args.degrees);
  return Uint8List.fromList(img.encodeJpg(rotated, quality: 90));
}

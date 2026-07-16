import 'dart:math' as math;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../core/utils/app_exception.dart';
import '../../domain/entities/app_enums.dart';

/// Wraps Google ML Kit's on-device text recognizer. Recognition is fully
/// offline: the small script model ships with the app / Play Services and
/// no image ever leaves the device.
class TextRecognitionDataSource {
  final Map<RecognitionLanguage, TextRecognizer> _recognizers = {};

  TextRecognizer _recognizerFor(RecognitionLanguage language) {
    return _recognizers.putIfAbsent(
      language,
      () => TextRecognizer(script: _scriptFor(language)),
    );
  }

  TextRecognitionScript _scriptFor(RecognitionLanguage language) {
    switch (language) {
      case RecognitionLanguage.latin:
        return TextRecognitionScript.latin;
      case RecognitionLanguage.chinese:
        return TextRecognitionScript.chinese;
      case RecognitionLanguage.devanagari:
        return TextRecognitionScript.devanagiri;
      case RecognitionLanguage.japanese:
        return TextRecognitionScript.japanese;
      case RecognitionLanguage.korean:
        return TextRecognitionScript.korean;
    }
  }

  /// Recognizes handwritten/printed text in [imagePath] and returns it with
  /// paragraph structure preserved, or an empty string when nothing readable
  /// was found — so callers can compare multiple passes (e.g. the original
  /// vs the enhanced image) and keep the better result. Throws
  /// [AppException] only when the image itself cannot be processed.
  Future<String> tryRecognize(String imagePath, RecognitionLanguage language) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizer = _recognizerFor(language);
      final result = await recognizer.processImage(inputImage);
      return _composeText(result);
    } catch (_) {
      throw const AppException(
        'This page could not be processed.',
        suggestion: 'Make sure the image is clear and try again.',
      );
    }
  }

  /// Rebuilds the page text in true reading order. ML Kit returns text
  /// blocks in detection order, which on real pages often interleaves
  /// columns and margin notes, making words appear shuffled or missing.
  /// Lines from all blocks are re-sorted top-to-bottom (with left-to-right
  /// tie-breaking for lines that share a vertical band), and paragraph
  /// breaks are re-derived from the vertical gaps between lines.
  String _composeText(RecognizedText result) {
    final lines = <TextLine>[];
    for (final block in result.blocks) {
      lines.addAll(block.lines);
    }
    if (lines.isEmpty) return '';

    final medianHeight = _medianLineHeight(lines);

    lines.sort((a, b) {
      final aBox = a.boundingBox;
      final bBox = b.boundingBox;
      // Lines whose vertical centers are within half a line height of each
      // other are treated as the same row and ordered left-to-right.
      final aCenter = aBox.top + aBox.height / 2;
      final bCenter = bBox.top + bBox.height / 2;
      if ((aCenter - bCenter).abs() < medianHeight * 0.5) {
        return aBox.left.compareTo(bBox.left);
      }
      return aCenter.compareTo(bCenter);
    });

    final buffer = StringBuffer();
    double? previousBottom;
    for (final line in lines) {
      final text = line.text.trim();
      if (text.isEmpty) continue;
      if (previousBottom != null) {
        final gap = line.boundingBox.top - previousBottom;
        // A gap noticeably larger than normal line spacing means a new
        // paragraph; otherwise continue the current one on a new line.
        buffer.write(gap > medianHeight * 0.9 ? '\n\n' : '\n');
      }
      buffer.write(text);
      previousBottom = math.max(previousBottom ?? 0, line.boundingBox.bottom.toDouble());
    }
    return buffer.toString();
  }

  double _medianLineHeight(List<TextLine> lines) {
    final heights = lines.map((l) => l.boundingBox.height.toDouble()).toList()..sort();
    final median = heights[heights.length ~/ 2];
    return median <= 0 ? 1 : median;
  }

  Future<void> dispose() async {
    for (final recognizer in _recognizers.values) {
      await recognizer.close();
    }
    _recognizers.clear();
  }
}

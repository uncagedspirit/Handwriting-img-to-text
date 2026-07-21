import 'dart:math' as math;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../core/utils/app_exception.dart';
import '../../domain/entities/app_enums.dart';

/// The result of one recognition pass over one image variant.
class RecognitionOutcome {
  const RecognitionOutcome({
    required this.text,
    required this.confidence,
    required this.hasConfidence,
  });

  static const empty = RecognitionOutcome(text: '', confidence: 0, hasConfidence: false);

  final String text;

  /// 0..1, character-weighted mean of ML Kit's per-line confidence.
  final double confidence;

  /// Whether ML Kit actually reported confidence values. Some devices and
  /// model versions leave them null, in which case [confidence] is a
  /// neutral placeholder and callers must judge by content alone.
  final bool hasConfidence;

  int get characterCount => text.replaceAll(RegExp(r'\s'), '').length;

  /// Comparable quality score: the amount of recognized content, weighted
  /// by how sure the engine was about it. Confidence contributes at half
  /// strength so a marginally-more-confident pass can't beat one that
  /// actually read substantially more of the page.
  double get score => characterCount * (0.5 + confidence / 2);
}

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
  /// paragraph structure preserved, or an empty outcome when nothing
  /// readable was found — so callers can compare multiple passes (e.g. the
  /// original vs enhanced vs binarized image) and keep the best result.
  /// Throws [AppException] only when the image itself cannot be processed.
  Future<RecognitionOutcome> tryRecognize(String imagePath, RecognitionLanguage language) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizer = _recognizerFor(language);
      final result = await recognizer.processImage(inputImage);
      return RecognitionOutcome(
        text: _composeText(result),
        confidence: _averageConfidence(result),
        hasConfidence: _reportsConfidence(result),
      );
    } catch (_) {
      throw const AppException(
        'This page could not be processed.',
        suggestion: 'Make sure the image is clear and try again.',
      );
    }
  }

  /// Whether any line came back with a real confidence value.
  bool _reportsConfidence(RecognizedText result) {
    for (final block in result.blocks) {
      for (final line in block.lines) {
        if (line.confidence != null) return true;
      }
    }
    return false;
  }

  /// Character-weighted mean of ML Kit's per-line confidence, so long
  /// well-recognized lines count for more than short noisy ones. Lines
  /// without a reported confidence assume a neutral 0.5.
  double _averageConfidence(RecognizedText result) {
    var weightedSum = 0.0;
    var totalChars = 0;
    for (final block in result.blocks) {
      for (final line in block.lines) {
        final chars = line.text.trim().length;
        if (chars == 0) continue;
        weightedSum += (line.confidence ?? 0.5) * chars;
        totalChars += chars;
      }
    }
    return totalChars == 0 ? 0 : weightedSum / totalChars;
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

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

  /// Recognizes handwritten/printed text in [imagePath] and returns the
  /// text with paragraph structure preserved. Throws [AppException] with a
  /// plain-language message when nothing readable was found.
  Future<String> recognize(String imagePath, RecognitionLanguage language) async {
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognizer = _recognizerFor(language);
      final result = await recognizer.processImage(inputImage);

      final text = _composeText(result);
      if (text.trim().isEmpty) {
        throw const AppException(
          "We couldn't find any readable handwriting in this page.",
          suggestion: 'Try better lighting, reduce blur, or capture the full page.',
        );
      }
      return text;
    } on AppException {
      rethrow;
    } catch (_) {
      throw const AppException(
        'This page could not be processed.',
        suggestion: 'Make sure the image is clear and try again.',
      );
    }
  }

  String _composeText(RecognizedText result) {
    final blocks = result.blocks;
    return blocks.map((block) => block.text.trim()).where((t) => t.isNotEmpty).join('\n\n');
  }

  Future<void> dispose() async {
    for (final recognizer in _recognizers.values) {
      await recognizer.close();
    }
    _recognizers.clear();
  }
}

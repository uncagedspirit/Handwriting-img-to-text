import 'package:image_picker/image_picker.dart';
import '../../core/utils/app_exception.dart';

/// Wraps `image_picker` for camera capture and gallery import, including
/// batch/multi-image selection.
class CaptureDataSource {
  final ImagePicker _picker = ImagePicker();

  /// A 12MP camera photo costs seconds of pure-Dart decoding later for no
  /// recognition benefit — a page of handwriting is fully legible at this
  /// size. The resize happens natively during capture, so it is effectively
  /// free and makes every downstream step several times faster.
  static const double _maxDimension = 2200;

  Future<String?> captureFromCamera() async {
    try {
      final file = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 92,
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
      );
      return file?.path;
    } catch (_) {
      throw const AppException(
        "We couldn't open the camera.",
        suggestion: 'Check that camera access is allowed for this app.',
      );
    }
  }

  Future<List<String>> pickFromGallery({bool allowMultiple = true}) async {
    try {
      if (allowMultiple) {
        final files = await _picker.pickMultiImage(
          imageQuality: 92,
          maxWidth: _maxDimension,
          maxHeight: _maxDimension,
        );
        return files.map((f) => f.path).toList();
      }
      final file = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 92,
        maxWidth: _maxDimension,
        maxHeight: _maxDimension,
      );
      return file == null ? [] : [file.path];
    } catch (_) {
      throw const AppException(
        "We couldn't open your gallery.",
        suggestion: 'Check that photo access is allowed for this app.',
      );
    }
  }
}
